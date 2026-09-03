import 'package:flutter/material.dart';

import 'data/app_controller.dart';
import 'med_license_app.dart';
import 'services/auth_bootstrap.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([
    AppController.load(),
    createAuthService(),
  ]);
  runApp(
    MedLicenseApp(
      controller: results[0] as AppController,
      authService: results[1] as AuthService,
    ),
  );
}
