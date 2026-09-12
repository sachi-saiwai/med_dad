import 'package:flutter/material.dart';

import 'data/app_controller.dart';
import 'med_license_app.dart';
import 'services/auth_bootstrap.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

/// Renders before startup finishes so a slow or failed initialization shows a
/// screen instead of nothing. On web the Firebase JS SDK is imported from a CDN
/// and never resolves when the app is launched without a network, so sign-in is
/// given a deadline rather than being awaited forever.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  static const authTimeout = Duration(seconds: 8);

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<_StartupResult> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _start();
  }

  Future<_StartupResult> _start() async {
    final controller = await AppController.load();
    final authService = await createAuthService().timeout(
      AppBootstrap.authTimeout,
      onTimeout: () => const UnconfiguredAuthService(
        'ログイン機能を読み込めませんでした。通信環境を確認して、アプリを開き直してください。',
      ),
    );
    return _StartupResult(controller, authService);
  }

  void _retry() {
    setState(() => _startup = _start());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupResult>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data!;
          return MedLicenseApp(
            controller: result.controller,
            authService: result.authService,
          );
        }
        return _StartupScreen(
          onRetry: snapshot.hasError ? _retry : null,
          message: snapshot.hasError ? 'アプリのデータを読み込めませんでした。' : null,
        );
      },
    );
  }
}

class _StartupResult {
  const _StartupResult(this.controller, this.authService);

  final AppController controller;
  final AuthService authService;
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF2F5F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (message == null)
                  const CircularProgressIndicator()
                else
                  Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('もう一度試す'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
