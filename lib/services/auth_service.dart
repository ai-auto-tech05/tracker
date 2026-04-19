import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/auth_user_model.dart';

/// Firebase-backed auth service.
/// Hive is used only for extra metadata not stored in Firebase:
///   - pendingEmail  (set when verifyBeforeUpdateEmail is called)
///   - resend timestamps (60-second throttle)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Hive box for metadata only
  static const String _metaBoxName = 'auth_meta_box';
  static const String _pendingEmailKey = 'pending_emails';   // uid → newEmail
  static const String _resendKey = 'resend_timestamps';      // key → ms timestamp

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_metaBoxName);
  }

  Box<String> get _metaBox {
    assert(_box != null, 'AuthService.init() must be called before use');
    return _box!;
  }

  // ─── Auth state stream ─────────────────────────────────────────────────────

  /// Emits a mapped [AuthUserModel] whenever Firebase auth state changes.
  /// Also checks for local guest session.
  Stream<AuthUserModel?> get authStateChanges =>
      _auth.authStateChanges().map((user) {
        if (user != null) return _buildModel(user);
        // No Firebase user — check for local guest session
        return _guestUser;
      });

  // ─── Current user ──────────────────────────────────────────────────────────

  AuthUserModel? get currentUser {
    final user = _auth.currentUser;
    if (user != null) return _buildModel(user);
    // Fallback: check local guest session
    return _guestUser;
  }

  bool get isLoggedIn => _auth.currentUser != null || _isGuestSession;

  // ─── Model builder ─────────────────────────────────────────────────────────

  AuthUserModel _buildModel(fb.User fbUser) {
    final isGoogle =
        fbUser.providerData.any((p) => p.providerId == 'google.com');
    final isAnonymous = fbUser.isAnonymous;
    final pendingEmail = _getPendingEmail(fbUser.uid);

    // Determine provider
    AuthProvider provider;
    if (isAnonymous) {
      provider = AuthProvider.guest;
    } else if (isGoogle) {
      provider = AuthProvider.google;
    } else {
      provider = AuthProvider.email;
    }

    // Determine verification status
    EmailVerificationStatus status;
    if (isAnonymous || isGoogle) {
      status = EmailVerificationStatus.verified;
    } else if (pendingEmail != null) {
      status = EmailVerificationStatus.pendingChange;
    } else if (fbUser.emailVerified) {
      status = EmailVerificationStatus.verified;
    } else {
      status = EmailVerificationStatus.pending;
    }

    return AuthUserModel(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ??
          (isAnonymous ? 'Guest' : fbUser.email?.split('@').first ?? 'User'),
      photoUrl: fbUser.photoURL,
      provider: provider,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      isEmailVerified: isAnonymous || isGoogle || fbUser.emailVerified,
      verificationStatus: status,
      pendingEmail: pendingEmail,
    );
  }

  // ─── Sign Up ───────────────────────────────────────────────────────────────

  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Set display name
      await cred.user!.updateDisplayName(name.trim());
      // Send real verification email
      await cred.user!.sendEmailVerification();
      await cred.user!.reload();
      return AuthResult.success(
        _buildModel(_auth.currentUser!),
        isNewUser: true,
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Sign up failed. Please try again.');
    }
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(
        _buildModel(cred.user!),
        isNewUser: false,
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Sign in failed. Please try again.');
    }
  }

  // ─── Google Sign In ────────────────────────────────────────────────────────

  Future<AuthResult> signInWithGoogle() async {
    try {
      // Opens the native Google account picker
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.error('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      return AuthResult.success(
        _buildModel(cred.user!),
        isNewUser: cred.additionalUserInfo?.isNewUser ?? false,
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('CONFIGURATION_NOT_FOUND') ||
          msg.contains('ApiException: 10') ||
          msg.contains('ApiException: 12500')) {
        return AuthResult.error(
          'Google Sign-In is not configured yet. '
          'Please add your SHA-1 fingerprint in Firebase Console, '
          'or use Email or Guest login.',
        );
      }
      return AuthResult.error('Google sign-in failed. Please try again.');
    }
  }

  // ─── Guest Sign In (local — no Firebase needed) ────────────────────────────

  /// Guest mode works 100% offline — creates a local user stored in Hive.
  /// No Firebase call required, so this never fails.
  static const String _guestSessionKey = 'guest_session';

  Future<AuthResult> signInAsGuest() async {
    // Check if there's an existing guest session
    final existingRaw = _metaBox.get(_guestSessionKey);
    if (existingRaw != null) {
      try {
        final existing = AuthUserModel.fromJson(
            jsonDecode(existingRaw) as Map<String, dynamic>);
        return AuthResult.success(existing, isNewUser: false);
      } catch (_) {
        // Corrupted — create fresh below
      }
    }

    final uid = 'guest_${const Uuid().v4()}';
    final user = AuthUserModel(
      uid: uid,
      email: '',
      displayName: 'Guest',
      provider: AuthProvider.guest,
      createdAt: DateTime.now(),
      isEmailVerified: true,
      verificationStatus: EmailVerificationStatus.verified,
    );
    await _metaBox.put(_guestSessionKey, jsonEncode(user.toJson()));
    return AuthResult.success(user, isNewUser: true);
  }

  bool get _isGuestSession => _metaBox.get(_guestSessionKey) != null;

  AuthUserModel? get _guestUser {
    final raw = _metaBox.get(_guestSessionKey);
    if (raw == null) return null;
    try {
      return AuthUserModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Email Verification ────────────────────────────────────────────────────

  /// Reload user from Firebase and return updated model.
  Future<AuthResult> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.error('Not signed in.');
      // Reload forces Firebase to fetch fresh data from the server
      await user.reload();
      final refreshed = _auth.currentUser!;
      return AuthResult.success(_buildModel(refreshed), isNewUser: false);
    } catch (_) {
      return AuthResult.error('Could not check verification status.');
    }
  }

  /// Resend verification email — throttled to once per 60 seconds.
  Future<AuthResult> resendVerificationEmail(String email) async {
    final throttleKey = 'verify_$email';
    if (!_canResend(throttleKey)) {
      return AuthResult.error(
          'Please wait 60 seconds before requesting another email.');
    }
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.error('Not signed in.');
      await user.sendEmailVerification();
      await _recordResend(throttleKey);
      return AuthResult.success(
        null,
        isNewUser: false,
        message: 'Verification email sent to $email.',
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Failed to send verification email.');
    }
  }

  // ─── Re-authenticate ───────────────────────────────────────────────────────

  Future<AuthResult> reauthenticate({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.error('Not signed in.');
      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return AuthResult.success(_buildModel(user), isNewUser: false);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Re-authentication failed.');
    }
  }

  // ─── Email Change ──────────────────────────────────────────────────────────

  /// Sends a verification link to [newEmail]. Firebase updates the email
  /// only after the user clicks the link.
  Future<AuthResult> initiateEmailChange({required String newEmail}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.error('Not signed in.');
      final trimmed = newEmail.trim().toLowerCase();
      await user.verifyBeforeUpdateEmail(trimmed);
      await _savePendingEmail(user.uid, trimmed);
      return AuthResult.success(
        _buildModel(user),
        isNewUser: false,
        message:
            'Verification sent to $trimmed. Click the link there, then tap "Confirm change".',
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Could not initiate email change.');
    }
  }

  /// Reload user — if Firebase shows the new email, clear the pending flag.
  Future<AuthResult> confirmEmailChange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.error('Not signed in.');
      final pending = _getPendingEmail(user.uid);
      await user.reload();
      final refreshed = _auth.currentUser!;

      if (pending != null && refreshed.email == pending) {
        await _clearPendingEmail(refreshed.uid);
        return AuthResult.success(
          _buildModel(refreshed),
          isNewUser: false,
          message: 'Email address updated to $pending.',
        );
      }

      // Not changed yet
      return AuthResult.success(
        _buildModel(refreshed),
        isNewUser: false,
        message:
            'Email not updated yet. Please click the link in ${pending ?? "your new inbox"} first.',
      );
    } catch (_) {
      return AuthResult.error('Could not confirm email change.');
    }
  }

  /// Resend the verification to the pending new address.
  Future<AuthResult> resendEmailChangeVerification() async {
    final user = _auth.currentUser;
    if (user == null) return AuthResult.error('Not signed in.');
    final pending = _getPendingEmail(user.uid);
    if (pending == null) return AuthResult.error('No pending email change.');

    final throttleKey = 'change_${user.uid}';
    if (!_canResend(throttleKey)) {
      return AuthResult.error('Please wait 60 seconds before resending.');
    }
    try {
      await user.verifyBeforeUpdateEmail(pending);
      await _recordResend(throttleKey);
      return AuthResult.success(
        null,
        isNewUser: false,
        message: 'Verification resent to $pending.',
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Could not resend verification.');
    }
  }

  // ─── Password Reset ────────────────────────────────────────────────────────

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(
        null,
        isNewUser: false,
        message: 'Password reset email sent to ${email.trim()}.',
      );
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.error(_mapError(e));
    } catch (_) {
      return AuthResult.error('Could not send password reset email.');
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Clear local guest session
    await _metaBox.delete(_guestSessionKey);
    await _googleSignIn.signOut().catchError((_) {}); // no-op if not Google
    await _auth.signOut();
  }

  // ─── Pending email helpers ─────────────────────────────────────────────────

  String? _getPendingEmail(String uid) {
    final raw = _metaBox.get(_pendingEmailKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)[uid] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePendingEmail(String uid, String email) async {
    final map = _readMap(_pendingEmailKey);
    map[uid] = email;
    await _metaBox.put(_pendingEmailKey, jsonEncode(map));
  }

  Future<void> _clearPendingEmail(String uid) async {
    final map = _readMap(_pendingEmailKey);
    map.remove(uid);
    await _metaBox.put(_pendingEmailKey, jsonEncode(map));
  }

  // ─── Resend throttle helpers ───────────────────────────────────────────────

  bool _canResend(String key) {
    final map = _readMap(_resendKey);
    final lastMs = map[key] as int?;
    if (lastMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch - lastMs > 60000;
  }

  Future<void> _recordResend(String key) async {
    final map = _readMap(_resendKey);
    map[key] = DateTime.now().millisecondsSinceEpoch;
    await _metaBox.put(_resendKey, jsonEncode(map));
  }

  Map<String, dynamic> _readMap(String key) {
    final raw = _metaBox.get(key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ─── Firebase error → human message ───────────────────────────────────────

  String _mapError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again before making this change.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}

// ─── AuthResult ────────────────────────────────────────────────────────────────

class AuthResult {
  final AuthUserModel? user;
  final bool isNewUser;
  final String? errorMessage;
  final String? message;

  const AuthResult._({
    this.user,
    required this.isNewUser,
    this.errorMessage,
    this.message,
  });

  factory AuthResult.success(
    AuthUserModel? user, {
    required bool isNewUser,
    String? message,
  }) =>
      AuthResult._(user: user, isNewUser: isNewUser, message: message);

  factory AuthResult.error(String message) =>
      AuthResult._(isNewUser: false, errorMessage: message);

  bool get isSuccess => errorMessage == null;
}
