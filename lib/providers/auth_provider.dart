import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─── Auth State ───────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUserModel? user;
  final bool isLoading;
  final String? error;
  final bool isNewUser;
  final String? message;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
    this.isNewUser = false,
    this.message,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isEmailVerified => user?.isEmailVerified ?? false;

  bool get hasPendingEmailChange => user?.pendingEmail != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthUserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isNewUser,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isNewUser: isNewUser ?? this.isNewUser,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;
  StreamSubscription<AuthUserModel?>? _subscription;

  AuthNotifier(this._auth) : super(const AuthState()) {
    // Listen to Firebase auth state changes.
    // Emits immediately if a user is already signed in (persisted session).
    _subscription = _auth.authStateChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Called whenever Firebase auth state changes (sign-in / sign-out / token refresh).
  void _onAuthChanged(AuthUserModel? user) {
    if (user == null) {
      // Signed out
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else if (state.status != AuthStatus.authenticated) {
      // First auth event (app start or fresh sign-in)
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } else {
      // Already authenticated — just refresh the user model
      // (e.g. email verified, display name changed)
      state = state.copyWith(user: user);
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.signUpWithEmail(
        name: name, email: email, password: password);
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
        isNewUser: true,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result =
        await _auth.signInWithEmail(email: email, password: password);
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
        isNewUser: false,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> signInAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.signInAsGuest();
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
        isNewUser: true,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.signInWithGoogle();
    if (result.isSuccess) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        isLoading: false,
        isNewUser: result.isNewUser,
      );
      return result.isNewUser;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  /// Reload user from Firebase — returns true if email is verified.
  Future<bool> checkEmailVerified() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.checkEmailVerified();
    if (result.isSuccess) {
      state = state.copyWith(user: result.user, isLoading: false);
      return result.user?.isEmailVerified ?? false;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.resendVerificationEmail(email);
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, message: result.message);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> reauthenticate({required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.reauthenticate(password: password);
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> initiateEmailChange({required String newEmail}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.initiateEmailChange(newEmail: newEmail);
    if (result.isSuccess) {
      state = state.copyWith(
        user: result.user,
        isLoading: false,
        message: result.message,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> confirmEmailChange() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.confirmEmailChange();
    if (result.isSuccess) {
      state = state.copyWith(
        user: result.user,
        isLoading: false,
        message: result.message,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<bool> resendEmailChangeVerification() async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.resendEmailChangeVerification();
    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, message: result.message);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
      return false;
    }
  }

  Future<String?> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    final result = await _auth.resetPassword(email);
    state = state.copyWith(isLoading: false);
    if (result.isSuccess) return null;
    return result.errorMessage;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Force state reset — stream won't fire for local guest sign-out
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearMessage() => state = state.copyWith(clearMessage: true);
}

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final currentAuthUserProvider = Provider<AuthUserModel?>((ref) {
  return ref.watch(authProvider).user;
});
