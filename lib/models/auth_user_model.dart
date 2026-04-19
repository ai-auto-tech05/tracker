enum AuthProvider { google, email, guest }

extension AuthProviderExt on AuthProvider {
  String get label {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.email:
        return 'Email';
      case AuthProvider.guest:
        return 'Guest';
    }
  }

  String get value => name;

  static AuthProvider fromString(String s) =>
      AuthProvider.values.firstWhere((e) => e.name == s,
          orElse: () => AuthProvider.guest);
}

enum EmailVerificationStatus { none, pending, verified, pendingChange }

extension EmailVerificationStatusExt on EmailVerificationStatus {
  String get value => name;
  static EmailVerificationStatus fromString(String s) =>
      EmailVerificationStatus.values.firstWhere((e) => e.name == s,
          orElse: () => EmailVerificationStatus.none);
}

class AuthUserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;
  final bool isEmailVerified;
  /// For in-progress email change — the new address awaiting verification.
  final String? pendingEmail;
  final EmailVerificationStatus verificationStatus;

  const AuthUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    this.isEmailVerified = false,
    this.pendingEmail,
    this.verificationStatus = EmailVerificationStatus.none,
  });

  AuthUserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? pendingEmail,
    bool clearPendingEmail = false,
    EmailVerificationStatus? verificationStatus,
  }) {
    return AuthUserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      pendingEmail:
          clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider.value,
        'createdAt': createdAt.toIso8601String(),
        'isEmailVerified': isEmailVerified,
        'pendingEmail': pendingEmail,
        'verificationStatus': verificationStatus.value,
      };

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        provider:
            AuthProviderExt.fromString(json['provider'] as String? ?? 'guest'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
        pendingEmail: json['pendingEmail'] as String?,
        verificationStatus: EmailVerificationStatusExt.fromString(
            json['verificationStatus'] as String? ?? 'none'),
      );
}
