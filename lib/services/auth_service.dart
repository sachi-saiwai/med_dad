class AuthUser {
  const AuthUser({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.providerIds = const [],
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final List<String> providerIds;
}

class AuthException implements Exception {
  const AuthException(this.message, {this.wasCanceled = false});

  final String message;
  final bool wasCanceled;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  bool get isConfigured;
  String? get configurationMessage;
  AuthUser? get currentUser;
  Stream<AuthUser?> authStateChanges();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}

/// Extra account operations used by the authenticated cloud API.
/// Test and local-preview auth services intentionally don't need to implement it.
abstract interface class CloudAuthService {
  Future<String?> getIdToken({bool forceRefresh = false});

  Future<void> deleteCurrentUser();
}

/// Used by widget tests and embedders that intentionally do not require sign-in.
class BypassAuthService implements AuthService {
  const BypassAuthService();

  static const _user = AuthUser(id: 'local-preview-user');

  @override
  bool get isConfigured => true;

  @override
  String? get configurationMessage => null;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class UnconfiguredAuthService implements AuthService {
  const UnconfiguredAuthService(this.configurationMessage);

  @override
  final String configurationMessage;

  @override
  bool get isConfigured => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

  @override
  Future<void> signInWithApple() => _throwConfigurationError();

  @override
  Future<void> signInWithGoogle() => _throwConfigurationError();

  Future<void> _throwConfigurationError() =>
      Future.error(AuthException(configurationMessage));

  @override
  Future<void> signOut() async {}
}
