import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/data/app_controller.dart';
import 'package:medlicense/med_license_app.dart';
import 'package:medlicense/services/auth_service.dart';

void main() {
  testWidgets('signed-out users see enabled account providers before setup', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    addTearDown(auth.dispose);

    await tester.pumpWidget(MedLicenseApp(authService: auth));
    await tester.pumpAndSettle();

    expect(find.text('Googleで続ける'), findsOneWidget);
    expect(find.text('Appleで続ける'), findsNothing);
    expect(find.text('設定を始める'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();

    expect(auth.googleSignInCount, 1);
    expect(find.text('設定を始める'), findsOneWidget);
  });

  testWidgets('unconfigured Firebase shows setup guidance', (tester) async {
    await tester.pumpWidget(
      const MedLicenseApp(
        authService: UnconfiguredAuthService('Firebase設定が必要です'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Firebase設定が必要です'), findsOneWidget);
    final googleButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Googleで続ける'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(googleButton.onPressed, isNull);
  });

  testWidgets('a different account starts clean on a shared device', (
    tester,
  ) async {
    final controller = AppController.memory();
    await controller.activateAccount('owner-user');
    await controller.completeSetup(
      displayName: '持ち主',
      qualifications: const [],
      notificationsEnabled: false,
    );
    final auth = _FakeAuthService(
      initialUser: const AuthUser(id: 'different-user'),
    );
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MedLicenseApp(controller: controller, authService: auth),
    );
    await tester.pumpAndSettle();

    expect(find.text('持ち主'), findsNothing);
    expect(find.text('設定を始める'), findsOneWidget);
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({AuthUser? initialUser}) : _user = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  int googleSignInCount = 0;

  @override
  bool get isConfigured => true;

  @override
  String? get configurationMessage => null;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCount += 1;
    _user = const AuthUser(
      id: 'user-1',
      displayName: '田中 太郎',
      email: 'taro@example.com',
      providerIds: ['google.com'],
    );
    _controller.add(_user);
  }

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
