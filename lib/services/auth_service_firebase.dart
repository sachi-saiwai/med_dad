import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

class FirebaseAuthService implements AuthService, CloudAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  Future<void>? _googleInitialization;

  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  @override
  bool get isConfigured => true;

  @override
  String? get configurationMessage => null;

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        return;
      }

      await (_googleInitialization ??= GoogleSignIn.instance.initialize(
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      ));
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Googleから認証情報を取得できませんでした。');
      }
      await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthException('', wasCanceled: true);
      }
      throw AuthException(_googleErrorMessage(error));
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Firebase Google sign-in failed: ${error.code}: ${error.message}',
      );
      throw AuthException(_firebaseErrorMessage(error));
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(provider);
      } else {
        await _firebaseAuth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'web-context-canceled' ||
          error.code == 'popup-closed-by-user' ||
          error.code == 'canceled') {
        throw const AuthException('', wasCanceled: true);
      }
      throw AuthException(_firebaseErrorMessage(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } on Object {
        // Firebase is already signed out. A stale provider session is harmless.
      }
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        throw const AuthException('安全のため、いったんログアウトして再ログイン後に削除してください。');
      }
      throw AuthException(_firebaseErrorMessage(error));
    }
  }
}

AuthUser? _mapUser(User? user) {
  if (user == null) return null;
  return AuthUser(
    id: user.uid,
    displayName: user.displayName,
    email: user.email,
    photoUrl: user.photoURL,
    providerIds: user.providerData
        .map((provider) => provider.providerId)
        .toList(),
  );
}

String _googleErrorMessage(GoogleSignInException error) {
  return switch (error.code) {
    GoogleSignInExceptionCode.clientConfigurationError =>
      'Googleログインのクライアント設定を確認してください。',
    GoogleSignInExceptionCode.providerConfigurationError =>
      'FirebaseでGoogleログインが有効になっているか確認してください。',
    GoogleSignInExceptionCode.uiUnavailable => 'この端末ではGoogleログイン画面を開けません。',
    _ => 'Googleログインに失敗しました。通信環境を確認してもう一度お試しください。',
  };
}

String _firebaseErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'account-exists-with-different-credential' =>
      '同じメールアドレスが別のログイン方法で登録されています。',
    'network-request-failed' => '通信できませんでした。ネットワーク接続を確認してください。',
    'operation-not-allowed' => 'このログイン方法は現在有効になっていません。',
    'popup-blocked' => 'ログイン画面がブロックされました。ポップアップを許可してください。',
    'popup-closed-by-user' => 'Googleログイン画面が完了前に閉じられました。もう一度お試しください。',
    'cancelled-popup-request' => '別のログイン処理が開始されました。もう一度お試しください。',
    'web-storage-unsupported' => 'ブラウザのサイトデータ保存を許可してから、もう一度お試しください。',
    'invalid-api-key' => 'FirebaseのWeb設定を確認してください（invalid-api-key）。',
    'invalid-app-credential' ||
    'invalid-credential' => 'Googleの認証情報を確認できませんでした（${error.code}）。',
    'too-many-requests' => '試行回数が多すぎます。しばらく待ってからお試しください。',
    'unauthorized-domain' => 'このWebサイトはログイン許可ドメインに登録されていません。',
    _ => 'ログインに失敗しました（${error.code}）。もう一度お試しください。',
  };
}
