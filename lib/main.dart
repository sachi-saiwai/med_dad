import 'package:flutter/material.dart';

import 'data/app_controller.dart';
import 'med_license_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.load();
  runApp(MedLicenseApp(controller: controller));
}
