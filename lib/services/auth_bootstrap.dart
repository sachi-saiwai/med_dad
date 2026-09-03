import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'auth_service_firebase.dart';

Future<AuthService> createAuthService() async {
  try {
    if (Firebase.apps.isEmpty) {
      final runtimeOptions = _runtimeFirebaseOptions;
      if (runtimeOptions != null) {
        await Firebase.initializeApp(options: runtimeOptions);
      } else if (!kIsWeb) {
        // Uses GoogleService-Info.plist / google-services.json when present.
        await Firebase.initializeApp();
      } else {
        return const UnconfiguredAuthService(
          'FirebaseのWeb設定がまだありません。READMEの「アカウントログイン設定」を完了してください。',
        );
      }
    }
    return FirebaseAuthService();
  } on Object {
    return const UnconfiguredAuthService(
      'Firebaseの接続設定がまだありません。READMEの「アカウントログイン設定」を完了してください。',
    );
  }
}

FirebaseOptions? get _runtimeFirebaseOptions {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if ([
    apiKey,
    appId,
    messagingSenderId,
    projectId,
  ].any((value) => value.isEmpty)) {
    return null;
  }

  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  const iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'jp.sachikosaga.medlicense',
  );
  const androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
    iosClientId: iosClientId.isEmpty ? null : iosClientId,
    iosBundleId: iosBundleId,
    androidClientId: androidClientId.isEmpty ? null : androidClientId,
  );
}
