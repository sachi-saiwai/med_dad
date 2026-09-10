import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/app_controller.dart';
import 'data/app_state.dart';
import 'services/attachment_service.dart';
import 'services/auth_service.dart';
import 'services/certificate_extraction.dart';
import 'services/certificate_ocr_service.dart';
import 'services/cloud_data_service.dart';
import 'services/official_rule_service.dart';

/// 文字色。長文でも疲れにくいよう白背景とのコントラストを高めに取っている。
const _ink = Color(0xFF152538);

/// 補助テキスト。WCAG AA を満たす濃さにして小さな文字でも読めるようにする。
const _inkSoft = Color(0xFF55677C);
const _primary = Color(0xFF1A5FA8);
const _primaryDark = Color(0xFF124878);
const _primarySoft = Color(0xFFE4EEF9);
const _canvas = Color(0xFFF2F5F9);
const _line = Color(0xFFD7DEE7);
const _neutralSoft = Color(0xFFEDF1F6);
const _track = Color(0xFFE3E9F0);
const _sectionTint = Color(0xFFF4F8FC);
const _sectionLine = Color(0xFFC7D9EC);
const _warning = Color(0xFFA85B08);
const _warningInk = Color(0xFF7A4A0A);
const _warningSoft = Color(0xFFFDF0DC);
const _warningStrong = Color(0xFFFBE1BC);
const _danger = Color(0xFFB3261E);
const _dangerSoft = Color(0xFFFBE9E7);
const _success = Color(0xFF1E7A4D);
const _successSoft = Color(0xFFE3F3E9);

/// 濃紺の面に載せる文字・アクセント色。
const _onInkMuted = Color(0xFFB8C7D8);
const _onInkSoft = Color(0xFFDCE6F0);
const _onInkAccent = Color(0xFF7FB2EA);
const _accentGold = Color(0xFFFFB84D);
const _cardShadow = Color(0x14152538);
const _appleSignInEnabled = bool.fromEnvironment('APPLE_SIGN_IN_ENABLED');

class MedLicenseApp extends StatefulWidget {
  const MedLicenseApp({super.key, this.controller, this.authService});

  final AppController? controller;
  final AuthService? authService;

  @override
  State<MedLicenseApp> createState() => _MedLicenseAppState();
}

class _MedLicenseAppState extends State<MedLicenseApp> {
  late final AppController _controller;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController.memory();
    _authService = widget.authService ?? const BypassAuthService();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: _primarySoft,
      onPrimaryContainer: _primaryDark,
      surface: Colors.white,
      onSurface: _ink,
      onSurfaceVariant: _inkSoft,
      surfaceContainerHighest: _neutralSoft,
      outline: _line,
      outlineVariant: _line,
      error: _danger,
      errorContainer: _dangerSoft,
    );

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => MaterialApp(
        title: '資格更新ノート',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: _canvas,
          fontFamilyFallback: const [
            'Hiragino Kaku Gothic ProN',
            'Hiragino Sans',
            'Yu Gothic',
            'Noto Sans JP',
          ],
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              color: _ink,
              fontSize: 27,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: TextStyle(
              color: _ink,
              fontSize: 21,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
            titleMedium: TextStyle(
              color: _ink,
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: TextStyle(color: _ink, fontSize: 17, height: 1.6),
            bodyMedium: TextStyle(color: _ink, fontSize: 15, height: 1.6),
            bodySmall: TextStyle(color: _inkSoft, fontSize: 14, height: 1.55),
            labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: _cardShadow,
            surfaceTintColor: Colors.transparent,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              side: BorderSide(color: _line),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              foregroundColor: _primaryDark,
              backgroundColor: Colors.white,
              side: const BorderSide(color: _line, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: _primaryDark,
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 3,
            shadowColor: _cardShadow,
            surfaceTintColor: Colors.transparent,
            indicatorColor: _primarySoft,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          listTileTheme: const ListTileThemeData(
            iconColor: _primary,
            textColor: _ink,
            subtitleTextStyle: TextStyle(
              color: _inkSoft,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: _line,
            thickness: 1,
            space: 1,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            linearTrackColor: _track,
            linearMinHeight: 10,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            dragHandleColor: _line,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: _ink,
            contentTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            hintStyle: const TextStyle(color: _inkSoft, fontSize: 16),
            labelStyle: const TextStyle(
              color: _inkSoft,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _line, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
          ),
        ),
        home: AuthGate(controller: _controller, authService: _authService),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.controller,
    required this.authService,
  });

  final AppController controller;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    if (!authService.isConfigured) {
      return SignInScreen(authService: authService);
    }

    return StreamBuilder<AuthUser?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _AuthLoadingScreen();
        }
        final user = snapshot.data;
        if (user == null) return SignInScreen(authService: authService);

        return _AccountBoundContent(
          key: ValueKey(user.id),
          controller: controller,
          authService: authService,
          user: user,
        );
      },
    );
  }
}

class _AccountBoundContent extends StatefulWidget {
  const _AccountBoundContent({
    super.key,
    required this.controller,
    required this.authService,
    required this.user,
  });

  final AppController controller;
  final AuthService authService;
  final AuthUser user;

  @override
  State<_AccountBoundContent> createState() => _AccountBoundContentState();
}

class _AccountBoundContentState extends State<_AccountBoundContent> {
  late Future<AccountConnectionResult> _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.user.id == 'local-preview-user'
        ? Future.value(
            const AccountConnectionResult(AccountConnectionStatus.connected),
          )
        : widget.controller.connectAuthenticatedAccount(
            widget.authService,
            widget.user,
          );
  }

  Future<AccountConnectionResult> _submitInvite(String inviteCode) {
    return widget.controller.connectAuthenticatedAccount(
      widget.authService,
      widget.user,
      inviteCode: inviteCode,
    );
  }

  void _useConnectionResult(AccountConnectionResult result) {
    if (!mounted) return;
    setState(() => _connection = Future.value(result));
  }

  Widget _buildAppContent() {
    final isLocalPreview = widget.user.id == 'local-preview-user';
    return widget.controller.isSetupComplete || widget.controller.demoMode
        ? AppShell(
            controller: widget.controller,
            authService: isLocalPreview ? null : widget.authService,
            authUser: isLocalPreview ? null : widget.user,
          )
        : InitialSetupScreen(controller: widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.id == 'local-preview-user') return _buildAppContent();

    return FutureBuilder<AccountConnectionResult>(
      future: _connection,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AuthLoadingScreen();
        }
        if (snapshot.hasError) {
          return _AccountAccessScreen(
            authService: widget.authService,
            title: 'アカウントを確認できませんでした',
            message: snapshot.error is CloudApiException
                ? (snapshot.error! as CloudApiException).message
                : '通信環境を確認して、もう一度アプリを開いてください。',
          );
        }
        final result = snapshot.data!;
        if (result.status == AccountConnectionStatus.invitationRequired) {
          return _InvitationAccessScreen(
            authService: widget.authService,
            user: widget.user,
            initialMessage: result.message,
            onSubmit: _submitInvite,
            onResolved: _useConnectionResult,
          );
        }
        if (result.status == AccountConnectionStatus.accountMismatch) {
          return _AccountAccessScreen(
            authService: widget.authService,
            title: '別のアカウントのデータがあります',
            message: 'この端末の資格・実績は別のアカウントに関連付けられています。元のアカウントでログインしてください。',
          );
        }

        return _buildAppContent();
      },
    );
  }
}

class _InvitationAccessScreen extends StatefulWidget {
  const _InvitationAccessScreen({
    required this.authService,
    required this.user,
    required this.onSubmit,
    required this.onResolved,
    this.initialMessage,
  });

  final AuthService authService;
  final AuthUser user;
  final String? initialMessage;
  final Future<AccountConnectionResult> Function(String code) onSubmit;
  final ValueChanged<AccountConnectionResult> onResolved;

  @override
  State<_InvitationAccessScreen> createState() =>
      _InvitationAccessScreenState();
}

class _InvitationAccessScreenState extends State<_InvitationAccessScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  bool _signingOut = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _submitting) {
      setState(() => _errorMessage = '招待コードを入力してください。');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.onSubmit(code);
      if (!mounted) return;
      if (result.isConnected ||
          result.status == AccountConnectionStatus.accountMismatch) {
        widget.onResolved(result);
      } else {
        setState(() {
          _errorMessage = result.message ?? '招待コードを確認してください。';
          _submitting = false;
        });
      }
    } on CloudApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _submitting = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _errorMessage = '招待コードを確認できませんでした。通信環境をご確認ください。';
          _submitting = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.authService.signOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: _primary,
                        size: 48,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '招待コードを入力',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.user.email == null
                            ? '資格更新ノートは現在、招待された方のみ利用できます。'
                            : '${widget.user.email} で利用を開始します。',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const ValueKey('invite-code'),
                        controller: _codeController,
                        enabled: !_submitting,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: '招待コード',
                          hintText: '例：ABCD-EFGH-IJKL',
                          prefixIcon: Icon(Icons.key_rounded),
                        ),
                      ),
                      if (_errorMessage ?? widget.initialMessage
                          case final message?) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _danger),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('submit-invite'),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('利用を開始'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _signingOut ? null : _signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('別のアカウントでログイン'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountAccessScreen extends StatefulWidget {
  const _AccountAccessScreen({
    required this.authService,
    required this.title,
    required this.message,
  });

  final AuthService authService;
  final String title;
  final String message;

  @override
  State<_AccountAccessScreen> createState() => _AccountAccessScreenState();
}

class _AccountAccessScreenState extends State<_AccountAccessScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: _warning,
                        size: 48,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(widget.message, textAlign: TextAlign.center),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: _isSigningOut ? null : _signOut,
                        icon: _isSigningOut
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: const Text('ログアウトして戻る'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, color: _primary, size: 52),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String? _activeProvider;
  String? _errorMessage;

  Future<void> _signIn(String provider, Future<void> Function() action) async {
    if (_activeProvider != null || !widget.authService.isConfigured) return;
    setState(() {
      _activeProvider = provider;
      _errorMessage = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted && !error.wasCanceled) {
        setState(() => _errorMessage = error.message);
      }
    } on Object {
      if (mounted) {
        setState(() => _errorMessage = 'ログインに失敗しました。もう一度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _activeProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = widget.authService.isConfigured;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: _primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: _primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '資格更新ノート',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '資格・単位・参加証を、あなたのアカウントで安全に管理します',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _inkSoft),
                  ),
                  const SizedBox(height: 34),
                  if (!isConfigured) ...[
                    _AuthMessageCard(
                      icon: Icons.settings_suggest_outlined,
                      message:
                          widget.authService.configurationMessage ??
                          '認証設定を確認してください。',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    _AuthMessageCard(
                      icon: Icons.error_outline_rounded,
                      message: _errorMessage!,
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    key: const ValueKey('sign-in-google'),
                    onPressed: !isConfigured || _activeProvider != null
                        ? null
                        : () => _signIn(
                            'google',
                            widget.authService.signInWithGoogle,
                          ),
                    icon: _activeProvider == 'google'
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const _GoogleMark(),
                    label: const Text('Googleで続ける'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: Colors.white,
                      foregroundColor: _ink,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_appleSignInEnabled) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('sign-in-apple'),
                      onPressed: !isConfigured || _activeProvider != null
                          ? null
                          : () => _signIn(
                              'apple',
                              widget.authService.signInWithApple,
                            ),
                      icon: _activeProvider == 'apple'
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.apple_rounded),
                      label: const Text('Appleで続ける'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF111111),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'ログイン情報は本人確認に使用します。資格・実績はクラウド同期し、参加証は非公開ストレージへ保存します。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _inkSoft, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessageCard extends StatelessWidget {
  const _AuthMessageCard({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? _danger : _warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

enum QualificationState { needsAttention, onTrack, almostDue }

class RequirementProgress {
  const RequirementProgress({
    required this.label,
    required this.current,
    required this.requiredValue,
    required this.unit,
    this.note,
  });

  final String label;
  final double current;
  final double requiredValue;
  final String unit;
  final String? note;

  bool get isComplete => current >= requiredValue;
  double get progress => (current / requiredValue).clamp(0, 1);
}

class Qualification {
  const Qualification({
    this.id = '',
    required this.name,
    required this.organization,
    required this.deadline,
    required this.remainingDays,
    required this.state,
    required this.total,
    required this.requiredTotal,
    required this.headline,
    required this.requirements,
    this.plannedTotal = 0,
    this.licenseNumber = '',
    this.memberId = '',
    this.memberPortalUrl = '',
    this.currentByCategory = const {},
    this.plannedByCategory = const {},
    this.creditEntries = const [],
    this.isDemo = false,
    this.hasVerifiedRequirements = true,
    this.systemType,
    this.renewalCycleYears,
    this.renewalYearFrom,
    this.renewalYearTo,
    this.sourceTitle,
    this.sourceUrl,
    this.sourceCheckedAt,
    this.mandatoryNotes = const [],
    this.otherConditions = const [],
  });

  final String id;
  final String name;
  final String organization;
  final String deadline;
  final int remainingDays;
  final QualificationState state;
  final double total;
  final double plannedTotal;
  final double requiredTotal;
  final String headline;
  final List<RequirementProgress> requirements;
  final bool hasVerifiedRequirements;
  final String? systemType;
  final double? renewalCycleYears;
  final int? renewalYearFrom;
  final int? renewalYearTo;
  final String? sourceTitle;
  final String? sourceUrl;
  final DateTime? sourceCheckedAt;
  final List<String> mandatoryNotes;
  final List<String> otherConditions;
  final String licenseNumber;
  final String memberId;
  final String memberPortalUrl;
  final Map<String, double> currentByCategory;
  final Map<String, double> plannedByCategory;
  final List<CreditBreakdownEntry> creditEntries;
  final bool isDemo;

  double get progress =>
      requiredTotal <= 0 ? 0 : (total / requiredTotal).clamp(0, 1);
  double get projectedTotal => total + plannedTotal;
  double get projectedProgress =>
      requiredTotal <= 0 ? 0 : (projectedTotal / requiredTotal).clamp(0, 1);

  double currentForCategory(String label) =>
      _creditsForCategory(currentByCategory, label);
}

class QualificationCatalogEntry {
  const QualificationCatalogEntry({
    required this.name,
    required this.organization,
    required this.category,
    this.keywords = const [],
    this.parentQualification,
  });

  final String name;
  final String organization;
  final String category;
  final List<String> keywords;
  final String? parentQualification;

  int? matchScore(String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return 0;

    final normalizedName = _normalizeSearchText(name);
    if (normalizedName.startsWith(normalizedQuery)) return 0;

    final normalizedKeywords = keywords.map(_normalizeSearchText);
    if (normalizedKeywords.any(
      (keyword) => keyword.startsWith(normalizedQuery),
    )) {
      return 1;
    }
    if (normalizedName.contains(normalizedQuery)) return 2;
    if (normalizedKeywords.any(
      (keyword) => keyword.contains(normalizedQuery),
    )) {
      return 3;
    }

    final supplementaryText = _normalizeSearchText(
      '$organization $category ${parentQualification ?? ''}',
    );
    return supplementaryText.contains(normalizedQuery) ? 4 : null;
  }

  bool matches(String query) {
    return matchScore(query) != null;
  }
}

String _normalizeSearchText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s　・･（）()/／ー_-]'), '');
}

const surgeryBaseQualificationName = '外科専門医';
const internalMedicineBaseQualificationName = '内科専門医';

const qualificationCatalog = <QualificationCatalogEntry>[
  QualificationCatalogEntry(
    name: '内科専門医',
    organization: '日本専門医機構／日本内科学会',
    category: '基本領域',
    keywords: ['内科', 'ないか'],
  ),
  QualificationCatalogEntry(
    name: '小児科専門医',
    organization: '日本専門医機構／日本小児科学会',
    category: '基本領域',
    keywords: ['小児科', '小児', 'こども', 'しょうに', 'しょうにか'],
  ),
  QualificationCatalogEntry(
    name: '小児神経専門医',
    organization: '日本専門医機構／日本小児神経学会',
    category: 'サブスペシャルティ',
    keywords: ['小児', 'こども', 'しょうに', '神経', '発達', 'てんかん'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: '小児循環器専門医',
    organization: '日本専門医機構／日本小児循環器学会',
    category: 'サブスペシャルティ',
    keywords: ['小児', 'こども', 'しょうに', '循環器', '心臓', '先天性心疾患'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: '内分泌代謝科（小児科）専門医',
    organization: '日本内分泌学会',
    category: '学会認定',
    keywords: ['小児', 'こども', 'しょうに', '小児内分泌', '内分泌', '成長', '低身長'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: '小児血液・がん専門医',
    organization: '日本小児血液・がん学会',
    category: '学会認定',
    keywords: ['小児', 'こども', 'しょうに', '血液', 'がん', '癌', '腫瘍'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: '新生児専門医',
    organization: '日本周産期・新生児医学会',
    category: '学会認定',
    keywords: ['小児', 'こども', 'しょうに', '新生児', '周産期', 'NICU'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: '小児感染症認定指導医（専門医）',
    organization: '日本小児感染症学会',
    category: '学会認定',
    keywords: ['小児', 'こども', 'しょうに', '感染症', 'ワクチン'],
    parentQualification: '小児科専門医',
  ),
  QualificationCatalogEntry(
    name: 'アレルギー専門医',
    organization: '日本アレルギー学会',
    category: '学会認定',
    keywords: ['小児', 'こども', 'しょうに', '小児科', 'アレルギー', '喘息', '食物アレルギー'],
  ),
  QualificationCatalogEntry(
    name: '皮膚科専門医',
    organization: '日本専門医機構／日本皮膚科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '精神科専門医',
    organization: '日本専門医機構／日本精神神経学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '外科専門医',
    organization: '日本専門医機構／日本外科学会',
    category: '基本領域',
    keywords: ['外科', 'げか'],
  ),
  QualificationCatalogEntry(
    name: '整形外科専門医',
    organization: '日本専門医機構／日本整形外科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '産婦人科専門医',
    organization: '日本専門医機構／日本産科婦人科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '眼科専門医',
    organization: '日本専門医機構／日本眼科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '耳鼻咽喉科専門医',
    organization: '日本専門医機構／日本耳鼻咽喉科頭頸部外科学会',
    category: '基本領域',
    keywords: ['耳鼻科'],
  ),
  QualificationCatalogEntry(
    name: '泌尿器科専門医',
    organization: '日本専門医機構／日本泌尿器科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '脳神経外科専門医',
    organization: '日本専門医機構／日本脳神経外科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '放射線科専門医',
    organization: '日本専門医機構／日本医学放射線学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '麻酔科専門医',
    organization: '日本専門医機構／日本麻酔科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '病理専門医',
    organization: '日本専門医機構／日本病理学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '臨床検査専門医',
    organization: '日本専門医機構／日本臨床検査医学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '救急科専門医',
    organization: '日本専門医機構／日本救急医学会',
    category: '基本領域',
    keywords: ['救急医'],
  ),
  QualificationCatalogEntry(
    name: '形成外科専門医',
    organization: '日本専門医機構／日本形成外科学会',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: 'リハビリテーション科専門医',
    organization: '日本専門医機構／日本リハビリテーション医学会',
    category: '基本領域',
    keywords: ['リハビリ', 'リハビリ科', 'リハ科', 'rehabilitation'],
  ),
  QualificationCatalogEntry(
    name: '認定臨床医',
    organization: '日本リハビリテーション医学会',
    category: '学会認定',
    keywords: ['リハビリ', 'リハビリ科', 'リハ医学', '認定臨床医'],
  ),
  QualificationCatalogEntry(
    name: '運動器リハビリテーション医',
    organization: '日本整形外科学会',
    category: '学会認定',
    keywords: ['リハビリ', '運動器', '整形外科', '運動器リハビリテーション医'],
  ),
  QualificationCatalogEntry(
    name: '総合診療専門医',
    organization: '日本専門医機構',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '消化器病専門医',
    organization: '日本消化器病学会',
    category: 'サブスペシャルティ',
    keywords: ['消化器内科', '消化器', '胃腸', 'しょうかき'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '呼吸器専門医',
    organization: '日本呼吸器学会',
    category: 'サブスペシャルティ',
    keywords: ['呼吸器内科', '呼吸器', '肺', 'こきゅうき'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '血液専門医',
    organization: '日本血液学会',
    category: 'サブスペシャルティ',
    keywords: ['血液内科', '血液', '造血', 'けつえき'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '内分泌代謝・糖尿病内科専門医',
    organization: '日本専門医機構／日本内分泌学会・日本糖尿病学会',
    category: 'サブスペシャルティ（新制度）',
    keywords: ['内分泌', '代謝', '糖尿病', '内分泌内科', 'ないぶんぴつ', 'とうにょうびょう'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '内分泌代謝科専門医',
    organization: '日本内分泌学会',
    category: '学会認定',
    keywords: ['内分泌', '代謝', '内分泌内科', 'ないぶんぴつ'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '糖尿病専門医',
    organization: '日本糖尿病学会',
    category: '学会認定',
    keywords: ['糖尿病内科', '糖尿病', '代謝', 'とうにょうびょう'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '腎臓専門医',
    organization: '日本腎臓学会',
    category: 'サブスペシャルティ',
    keywords: ['腎臓内科', '腎臓', '腎', '透析', 'じんぞう'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '肝臓専門医',
    organization: '日本肝臓学会',
    category: 'サブスペシャルティ',
    keywords: ['肝臓内科', '肝臓', '肝', 'かんぞう'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '感染症専門医',
    organization: '日本感染症学会',
    category: 'サブスペシャルティ',
    keywords: ['感染症内科', '感染症', 'かんせんしょう'],
  ),
  QualificationCatalogEntry(
    name: '老年科専門医',
    organization: '日本老年医学会',
    category: 'サブスペシャルティ',
    keywords: ['老年内科', '高齢者', '老年', 'ろうねん'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '神経内科専門医',
    organization: '日本神経学会',
    category: 'サブスペシャルティ',
    keywords: ['脳神経内科', '脳神経', '神経', 'しんけい'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: 'リウマチ専門医',
    organization: '日本リウマチ学会',
    category: 'サブスペシャルティ',
    keywords: ['膠原病', 'リウマチ内科', 'りうまち'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '消化器内視鏡専門医',
    organization: '日本消化器内視鏡学会',
    category: 'サブスペシャルティ',
    keywords: ['消化器', '内視鏡', '胃カメラ', '大腸カメラ', 'しょうかき'],
    parentQualification: internalMedicineBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: 'がん薬物療法専門医',
    organization: '日本臨床腫瘍学会',
    category: 'サブスペシャルティ',
    keywords: ['腫瘍内科', 'がん', '癌', '抗がん剤', '化学療法'],
  ),
  QualificationCatalogEntry(
    name: '放射線診断専門医',
    organization: '日本専門医機構／日本医学放射線学会',
    category: 'サブスペシャルティ',
    keywords: ['放射線', '画像診断', 'CT', 'MRI', 'ほうしゃせん'],
    parentQualification: '放射線科専門医',
  ),
  QualificationCatalogEntry(
    name: '放射線治療専門医',
    organization: '日本専門医機構／日本医学放射線学会・日本放射線腫瘍学会',
    category: 'サブスペシャルティ',
    keywords: ['放射線', '放射線治療', '腫瘍', 'ほうしゃせん'],
    parentQualification: '放射線科専門医',
  ),
  QualificationCatalogEntry(
    name: '放射線カテーテル治療専門医',
    organization: '日本専門医機構／日本IVR学会',
    category: 'サブスペシャルティ',
    keywords: ['放射線', 'カテーテル', 'IVR', '画像下治療', 'ほうしゃせん'],
    parentQualification: '放射線科専門医',
  ),
  QualificationCatalogEntry(
    name: '集中治療科専門医',
    organization: '日本専門医機構／日本集中治療医学会',
    category: 'サブスペシャルティ',
    keywords: ['集中治療', 'ICU', '救急', 'しゅうちゅう'],
  ),
  QualificationCatalogEntry(
    name: '脊椎脊髄外科専門医',
    organization: '日本専門医機構／脊椎脊髄外科専門医委員会',
    category: 'サブスペシャルティ',
    keywords: ['脊椎', '脊髄', '背骨', 'せきつい', 'せきずい'],
  ),
  QualificationCatalogEntry(
    name: '消化器外科専門医',
    organization: '日本専門医機構／日本消化器外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '消化器', '胃腸', '腹部'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '呼吸器外科専門医',
    organization: '日本専門医機構／呼吸器外科専門医合同委員会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '呼吸器', '胸部', '肺'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '心臓血管外科専門医',
    organization: '日本専門医機構／心臓血管外科専門医認定機構',
    category: 'サブスペシャルティ',
    keywords: ['外科', '心臓', '血管', '循環器'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '小児外科専門医',
    organization: '日本専門医機構／日本小児外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '小児', 'こども', 'しょうに'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '乳腺外科専門医',
    organization: '日本専門医機構／日本乳癌学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '乳腺', '乳がん', '乳癌'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '内分泌外科専門医',
    organization: '日本専門医機構／日本内分泌外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '内分泌', '甲状腺', '副甲状腺', '副腎'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '乳腺専門医',
    organization: '日本乳癌学会',
    category: '学会認定（旧制度）',
    keywords: ['外科', '乳腺', '乳がん', '乳癌'],
    parentQualification: surgeryBaseQualificationName,
  ),
  QualificationCatalogEntry(
    name: '大腸肛門病専門医',
    organization: '日本大腸肛門病学会',
    category: '学会認定',
    keywords: ['外科', '大腸', '肛門', '消化器'],
  ),
  QualificationCatalogEntry(
    name: '肝胆膵外科高度技能専門医',
    organization: '日本肝胆膵外科学会',
    category: '高度技能',
    keywords: ['外科', '肝臓', '胆道', '膵臓', '消化器'],
  ),
  QualificationCatalogEntry(
    name: '内視鏡外科技術認定医',
    organization: '日本内視鏡外科学会',
    category: '技術認定',
    keywords: ['外科', '内視鏡', '腹腔鏡', 'ロボット'],
  ),
  QualificationCatalogEntry(
    name: '脈管専門医',
    organization: '日本脈管学会',
    category: '学会認定',
    keywords: ['外科', '血管', '脈管'],
  ),
  QualificationCatalogEntry(
    name: '移植認定医',
    organization: '日本移植学会',
    category: '学会認定',
    keywords: ['外科', '移植', '臓器移植'],
  ),
  QualificationCatalogEntry(
    name: 'がん治療認定医',
    organization: '日本がん治療認定医機構',
    category: '機構認定',
    keywords: ['外科', 'がん', '癌', '腫瘍'],
  ),
  QualificationCatalogEntry(
    name: '総合内科専門医',
    organization: '日本内科学会',
    category: '学会認定',
    keywords: ['内科', '総合内科'],
  ),
  QualificationCatalogEntry(
    name: '循環器専門医',
    organization: '日本循環器学会',
    category: '学会認定',
    keywords: ['心臓', '循環器'],
  ),
  QualificationCatalogEntry(
    name: '超音波専門医',
    organization: '日本超音波医学会',
    category: '学会認定',
    keywords: ['エコー', '超音波'],
  ),
];

List<QualificationCatalogEntry> get surgicalSubspecialtyCatalog =>
    qualificationCatalog
        .where(
          (entry) => entry.parentQualification == surgeryBaseQualificationName,
        )
        .toList(growable: false);

class CreditBreakdownEntry {
  const CreditBreakdownEntry({
    required this.title,
    required this.eventType,
    required this.category,
    required this.date,
    required this.organizer,
    required this.credits,
    required this.certificationId,
  });

  final String title;
  final String eventType;
  final String category;
  final String date;
  final String organizer;
  final double credits;
  final String certificationId;
}

const sampleQualifications = <Qualification>[
  Qualification(
    name: '超音波専門医',
    organization: '日本超音波医学会（サンプル）',
    deadline: '2026年12月31日',
    remainingDays: 131,
    state: QualificationState.almostDue,
    total: 34,
    requiredTotal: 40,
    headline: '必須講習が1回不足しています',
    requirements: [
      RequirementProgress(
        label: '総単位',
        current: 34,
        requiredValue: 40,
        unit: '単位',
      ),
      RequirementProgress(
        label: '専門講習',
        current: 18,
        requiredValue: 20,
        unit: '単位',
      ),
      RequirementProgress(
        label: '医療安全講習',
        current: 0,
        requiredValue: 1,
        unit: '回',
        note: '必須項目',
      ),
    ],
    isDemo: true,
  ),
  Qualification(
    name: '内科専門医',
    organization: '日本専門医機構／日本内科学会（サンプル）',
    deadline: '2027年3月31日',
    remainingDays: 221,
    state: QualificationState.needsAttention,
    total: 42,
    requiredTotal: 50,
    headline: '確認待ちの参加証が1件あります',
    requirements: [
      RequirementProgress(
        label: '総単位',
        current: 42,
        requiredValue: 50,
        unit: '単位',
      ),
      RequirementProgress(
        label: '共通講習',
        current: 8,
        requiredValue: 10,
        unit: '単位',
      ),
      RequirementProgress(
        label: '医療安全講習',
        current: 1,
        requiredValue: 1,
        unit: '回',
        note: '達成済み',
      ),
    ],
    isDemo: true,
  ),
  Qualification(
    name: '循環器専門医',
    organization: '日本循環器学会（サンプル）',
    deadline: '2028年3月31日',
    remainingDays: 587,
    state: QualificationState.onTrack,
    total: 28,
    requiredTotal: 40,
    headline: '現在のペースで順調です',
    requirements: [
      RequirementProgress(
        label: '総単位',
        current: 28,
        requiredValue: 40,
        unit: '単位',
      ),
      RequirementProgress(
        label: '専門単位',
        current: 22,
        requiredValue: 30,
        unit: '単位',
      ),
      RequirementProgress(
        label: '必須講習',
        current: 2,
        requiredValue: 2,
        unit: '回',
        note: '達成済み',
      ),
    ],
    isDemo: true,
  ),
];

Qualification qualificationFromStored(
  StoredQualification stored,
  AppSnapshot snapshot,
) {
  final deadline = _parseFlexibleDate(stored.deadline);
  final remainingDays = deadline == null
      ? 0
      : DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
        ).difference(DateTime.now()).inDays;
  final points = snapshot.pointsForQualification(stored.id);
  final state = remainingDays < 0 || (deadline != null && remainingDays <= 180)
      ? QualificationState.almostDue
      : points.current > 0
      ? QualificationState.onTrack
      : QualificationState.needsAttention;
  final headline = points.planned > 0
      ? '現在${_formatNumber(points.current)}単位・参加予定 +${_formatNumber(points.planned)}単位'
      : points.current > 0
      ? '現在${_formatNumber(points.current)}単位を登録済みです'
      : '実績または参加予定を登録してください';
  return Qualification(
    id: stored.id,
    name: stored.name,
    organization: stored.organization,
    deadline: deadline == null
        ? '未登録'
        : '${deadline.year}年${deadline.month}月${deadline.day}日',
    remainingDays: remainingDays,
    state: state,
    total: points.current,
    plannedTotal: points.planned,
    requiredTotal: 0,
    headline: headline,
    requirements: const [],
    hasVerifiedRequirements: false,
    licenseNumber: stored.licenseNumber,
    memberId: stored.memberId,
    memberPortalUrl: stored.memberPortalUrl,
    currentByCategory: points.currentByCategory,
    plannedByCategory: points.plannedByCategory,
    creditEntries: _creditEntriesForQualification(snapshot, stored.id),
  );
}

Qualification qualificationWithOfficialRule(
  Qualification qualification,
  OfficialRenewalRule rule,
) {
  final requiredTotal = rule.requiredTotalCredits ?? 0;
  final projectedGap = requiredTotal - qualification.projectedTotal;
  final headline = requiredTotal <= 0
      ? qualification.headline
      : projectedGap <= 0 && qualification.plannedTotal > 0
      ? '参加予定を含めると必要単位に到達する見込みです'
      : projectedGap <= 0
      ? '必要な総単位に到達しています'
      : qualification.plannedTotal > 0
      ? '参加予定を含めてあと${_formatNumber(projectedGap)}単位です'
      : '必要な総単位まであと${_formatNumber(projectedGap)}単位です';
  final requirements = <RequirementProgress>[];
  if (requiredTotal > 0) {
    requirements.add(
      RequirementProgress(
        label: '総単位',
        current: qualification.total,
        requiredValue: requiredTotal,
        unit: '単位',
        note: '資格更新に必要な合計',
      ),
    );
  }
  for (final requirement in rule.requirements) {
    final target = requirement.trackingTarget;
    if (target == null || target <= 0) continue;
    final duplicatesTotal =
        requiredTotal > 0 &&
        target == requiredTotal &&
        (requirement.label.contains('更新単位') ||
            requirement.label.contains('総単位'));
    if (duplicatesTotal) continue;
    final notes = <String>[
      if (requirement.mandatory) '必須',
      if (requirement.maximum != null)
        '上限 ${_formatNumber(requirement.maximum!)}${requirement.unit}',
    ];
    requirements.add(
      RequirementProgress(
        label: requirement.label,
        current: qualification.currentForCategory(requirement.label),
        requiredValue: target,
        unit: requirement.unit,
        note: notes.isEmpty ? null : notes.join('・'),
      ),
    );
  }
  return Qualification(
    id: qualification.id,
    name: qualification.name,
    organization: qualification.organization,
    deadline: qualification.deadline,
    remainingDays: qualification.remainingDays,
    state: qualification.state,
    total: qualification.total,
    plannedTotal: qualification.plannedTotal,
    requiredTotal: requiredTotal,
    headline: headline,
    requirements: requirements,
    hasVerifiedRequirements: true,
    systemType: rule.systemType,
    renewalCycleYears: rule.renewalCycleYears,
    renewalYearFrom: rule.renewalYearFrom,
    renewalYearTo: rule.renewalYearTo,
    sourceTitle: rule.source.title,
    sourceUrl: rule.source.url,
    sourceCheckedAt: rule.source.checkedAt,
    mandatoryNotes: rule.mandatoryNotes,
    otherConditions: rule.otherConditions,
    licenseNumber: qualification.licenseNumber,
    memberId: qualification.memberId,
    memberPortalUrl: qualification.memberPortalUrl,
    currentByCategory: qualification.currentByCategory,
    plannedByCategory: qualification.plannedByCategory,
    creditEntries: qualification.creditEntries,
    isDemo: qualification.isDemo,
  );
}

double _creditsForCategory(Map<String, double> values, String label) {
  final normalizedLabel = _normalizeSearchText(label);
  return values.entries
      .where((entry) {
        final category = _normalizeSearchText(entry.key);
        return category == normalizedLabel ||
            category.contains(normalizedLabel) ||
            normalizedLabel.contains(category);
      })
      .fold<double>(0, (sum, entry) => sum + entry.value);
}

List<CreditBreakdownEntry> _creditEntriesForQualification(
  AppSnapshot snapshot,
  String qualificationId,
) {
  final entries = <CreditBreakdownEntry>[];
  for (final activity in snapshot.activities) {
    if (activity.status != '確定') continue;
    var allocations = activity.allocations;
    if (allocations.isEmpty && snapshot.qualifications.length == 1) {
      allocations = [
        StoredActivityAllocation(
          qualificationId: snapshot.qualifications.single.id,
          credits: activity.credits,
        ),
      ];
    }
    for (final allocation in allocations) {
      if (allocation.qualificationId != qualificationId ||
          allocation.credits <= 0) {
        continue;
      }
      final isConference =
          allocation.category.contains('学会') ||
          allocation.category.contains('発表');
      entries.add(
        CreditBreakdownEntry(
          title: activity.title,
          eventType: isConference ? '学会' : '講習',
          category: allocation.category,
          date: activity.date.isEmpty ? '日付未入力' : activity.date,
          organizer: activity.organizer.isEmpty ? '主催者未入力' : activity.organizer,
          credits: allocation.credits,
          certificationId: activity.certificationId,
        ),
      );
    }
  }
  return entries;
}

DateTime? _parseFlexibleDate(String value) {
  final normalized = value
      .trim()
      .replaceAll('年', '/')
      .replaceAll('月', '/')
      .replaceAll('日', '');
  final parts = normalized.split('/');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

const creditBreakdownByQualification = <String, List<CreditBreakdownEntry>>{
  '超音波専門医': [
    CreditBreakdownEntry(
      title: '日本超音波医学会 第99回学術集会',
      eventType: '学会',
      category: '学術集会参加',
      date: '2026/05/29',
      organizer: '日本超音波医学会',
      credits: 10,
      certificationId: '2605290099',
    ),
    CreditBreakdownEntry(
      title: '第38回 東日本地方会',
      eventType: '学会',
      category: '地方会参加',
      date: '2026/04/21',
      organizer: '日本超音波医学会',
      credits: 6,
      certificationId: '2604210147',
    ),
    CreditBreakdownEntry(
      title: '腹部超音波ハンズオン講習会',
      eventType: '講習',
      category: '専門講習',
      date: '2026/03/15',
      organizer: '超音波研修センター',
      credits: 6,
      certificationId: '2603150064',
    ),
    CreditBreakdownEntry(
      title: '救急超音波実践セミナー',
      eventType: '講習',
      category: '専門講習',
      date: '2026/02/18',
      organizer: '救急超音波研究会',
      credits: 4,
      certificationId: '2602180218',
    ),
    CreditBreakdownEntry(
      title: '症例発表：心エコー評価',
      eventType: '学会',
      category: '学会発表',
      date: '2026/01/28',
      organizer: '地域超音波研究会',
      credits: 5,
      certificationId: '2601280032',
    ),
    CreditBreakdownEntry(
      title: '超音波安全管理 eラーニング',
      eventType: '講習',
      category: '安全管理講習',
      date: '2025/12/08',
      organizer: '認定団体',
      credits: 3,
      certificationId: '2512080175',
    ),
  ],
  '内科専門医': [
    CreditBreakdownEntry(
      title: '日本内科学会 総会・講演会',
      eventType: '学会',
      category: '学術集会参加',
      date: '2026/04/12',
      organizer: '日本内科学会',
      credits: 10,
      certificationId: '2604120108',
    ),
    CreditBreakdownEntry(
      title: '第42回 地域医療研修会',
      eventType: '講習',
      category: '共通講習',
      date: '2026/08/18',
      organizer: '地域医療研修センター',
      credits: 2,
      certificationId: '2608180042',
    ),
    CreditBreakdownEntry(
      title: '医療安全講習会',
      eventType: '講習',
      category: '医療安全',
      date: '2026/07/12',
      organizer: '県医師会',
      credits: 1,
      certificationId: '2607120185',
    ),
    CreditBreakdownEntry(
      title: '感染対策アップデート',
      eventType: '講習',
      category: '感染対策',
      date: '2026/06/08',
      organizer: '県医師会',
      credits: 4,
      certificationId: '2606080124',
    ),
    CreditBreakdownEntry(
      title: '内科地方会・症例発表',
      eventType: '学会',
      category: '学会発表',
      date: '2026/03/22',
      organizer: '日本内科学会',
      credits: 15,
      certificationId: '2603220316',
    ),
    CreditBreakdownEntry(
      title: '内科診療 eラーニング',
      eventType: '講習',
      category: '専門講習',
      date: '2026/02/05',
      organizer: '認定団体',
      credits: 10,
      certificationId: '2602050087',
    ),
  ],
  '循環器専門医': [
    CreditBreakdownEntry(
      title: '日本循環器学会 学術集会',
      eventType: '学会',
      category: '学術集会参加',
      date: '2026/03/20',
      organizer: '日本循環器学会',
      credits: 10,
      certificationId: '2603200101',
    ),
    CreditBreakdownEntry(
      title: '循環器カンファレンス',
      eventType: '講習',
      category: '専門講習',
      date: '2026/06/28',
      organizer: '循環器学会',
      credits: 3,
      certificationId: '2606280226',
    ),
    CreditBreakdownEntry(
      title: '心不全診療アップデート',
      eventType: '講習',
      category: '専門講習',
      date: '2026/05/11',
      organizer: '心不全研究会',
      credits: 5,
      certificationId: '2605110055',
    ),
    CreditBreakdownEntry(
      title: '循環器地方会',
      eventType: '学会',
      category: '地方会参加',
      date: '2026/02/14',
      organizer: '日本循環器学会',
      credits: 6,
      certificationId: '2602140114',
    ),
    CreditBreakdownEntry(
      title: '心電図判読 eラーニング',
      eventType: '講習',
      category: '専門講習',
      date: '2026/01/19',
      organizer: '認定団体',
      credits: 4,
      certificationId: '2601190078',
    ),
  ],
};

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int _currentStep = 0;
  int _nextQualificationId = 2;
  bool _notificationsEnabled = true;
  final TextEditingController _displayNameController = TextEditingController();
  final List<_QualificationDraft> _qualifications = [
    _QualificationDraft(
      id: 1,
      name: '',
      organization: '',
      licenseNumber: '',
      deadline: '',
    ),
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _openDemo() {
    widget.controller.enterDemoMode();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      return;
    }

    final selected = _qualifications
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保有資格を1件以上選択してください')));
      return;
    }

    final storedQualifications = <StoredQualification>[];
    for (final draft in selected) {
      storedQualifications.add(
        StoredQualification(
          id: 'qualification-${draft.id}',
          name: draft.name.trim(),
          organization: draft.organization.trim(),
          licenseNumber: draft.licenseNumber.trim(),
          deadline: draft.deadline.trim(),
          memberId: draft.memberId.trim(),
          memberPortalUrl: draft.memberPortalUrl.trim(),
        ),
      );
      for (final subspecialtyName in draft.subspecialtyNames) {
        final entry = qualificationCatalog.firstWhere(
          (item) => item.name == subspecialtyName,
        );
        storedQualifications.add(
          StoredQualification(
            id: 'qualification-${draft.id}-${entry.name.hashCode.abs()}',
            name: entry.name,
            organization: entry.organization,
            licenseNumber: '',
            deadline: '',
            parentQualification: draft.name,
          ),
        );
      }
    }
    await widget.controller.completeSetup(
      displayName: _displayNameController.text,
      qualifications: storedQualifications,
      notificationsEnabled: _notificationsEnabled,
    );
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  void _addQualification() {
    setState(() {
      _qualifications.add(
        _QualificationDraft(
          id: _nextQualificationId++,
          name: '',
          organization: '',
          licenseNumber: '',
          deadline: '',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_currentStep) {
      1 => _ProfileSetupPage(controller: _displayNameController),
      2 => _QualificationSetupPage(
        qualifications: _qualifications,
        notificationsEnabled: _notificationsEnabled,
        onNotificationsChanged: (value) {
          setState(() => _notificationsEnabled = value);
        },
        onAddQualification: _addQualification,
        onRemoveQualification: (id) {
          setState(() {
            _qualifications.removeWhere((item) => item.id == id);
          });
        },
      ),
      _ => const _SetupWelcomePage(),
    };

    return Scaffold(
      appBar: _currentStep == 0
          ? null
          : AppBar(
              backgroundColor: _canvas,
              leading: IconButton(
                tooltip: '戻る',
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text('初期設定'),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: ValueKey('setup-step-$_currentStep'),
              padding: EdgeInsets.fromLTRB(
                20,
                _currentStep == 0 ? 28 : 8,
                20,
                28,
              ),
              children: [
                const _SetupBrand(),
                const SizedBox(height: 24),
                _SetupProgressIndicator(currentStep: _currentStep + 1),
                const SizedBox(height: 28),
                page,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _nextStep,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(switch (_currentStep) {
                      0 => '設定を始める',
                      2 => '登録して始める',
                      _ => '次へ',
                    }),
                  ),
                  if (_currentStep == 0) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _openDemo,
                      child: const Text('サンプルデータで見る'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QualificationDraft {
  _QualificationDraft({
    required this.id,
    required this.name,
    required this.organization,
    required this.licenseNumber,
    required this.deadline,
  }) : memberId = '',
       memberPortalUrl = '',
       subspecialtyNames = {};

  final int id;
  String name;
  String organization;
  String licenseNumber;
  String deadline;
  String memberId;
  String memberPortalUrl;
  Set<String> subspecialtyNames;
}

class _SetupBrand extends StatelessWidget {
  const _SetupBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _IconTile(
          icon: Icons.workspace_premium_outlined,
          color: Colors.white,
          background: _primary,
        ),
        SizedBox(width: 12),
        Text(
          '資格更新ノート',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SetupProgressIndicator extends StatelessWidget {
  const _SetupProgressIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['ご案内', '本人情報', '資格登録'];
    return Row(
      children: List.generate(labels.length, (index) {
        final step = index + 1;
        final active = step <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? _primary : _track,
                        shape: BoxShape.circle,
                      ),
                      child: step < currentStep
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              '$step',
                              style: TextStyle(
                                color: active ? Colors.white : _inkSoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: active ? _ink : _inkSoft,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < labels.length - 1)
                Container(
                  width: 22,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 25),
                  color: step < currentStep ? _primary : _line,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SetupWelcomePage extends StatelessWidget {
  const _SetupWelcomePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: _primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: _primary,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '資格の更新情報を\nひとつにまとめます',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          '保有資格・更新期限・必要単位を登録すると、現在の不足状況が分かるようになります。',
          textAlign: TextAlign.center,
          style: TextStyle(color: _inkSoft, fontSize: 15, height: 1.55),
        ),
        const SizedBox(height: 28),
        const _SetupFeatureRow(
          icon: Icons.event_available_outlined,
          title: '更新期限をまとめて確認',
          subtitle: '期限が近い資格から表示します',
        ),
        const SizedBox(height: 12),
        const _SetupFeatureRow(
          icon: Icons.pie_chart_outline_rounded,
          title: '単位と必須条件を管理',
          subtitle: '講習・学会ごとの内訳も確認できます',
        ),
        const SizedBox(height: 12),
        const _SetupFeatureRow(
          icon: Icons.document_scanner_outlined,
          title: '参加証から実績を登録',
          subtitle: '読み取り結果は確定前に本人が確認します',
        ),
        const SizedBox(height: 20),
        const _SetupPrivacyNotice(),
      ],
    );
  }
}

class _SetupFeatureRow extends StatelessWidget {
  const _SetupFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          _IconTile(icon: icon, color: _primary, background: _primarySoft),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _inkSoft, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupPrivacyNotice extends StatelessWidget {
  const _SetupPrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _warning, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '患者情報は登録しません。表示結果は自己管理用のため、最終確認は資格団体の公式情報で行ってください。',
              style: TextStyle(color: _warningInk, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupPage extends StatelessWidget {
  const _ProfileSetupPage({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本人情報を登録', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'アプリ内での表示に使用します。後から設定画面で変更できます。',
          style: TextStyle(color: _inkSoft, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'お名前・呼び名',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例：田中 太郎',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconTile(
                  icon: Icons.lock_outline_rounded,
                  color: _primary,
                  background: _primarySoft,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '本人専用として管理',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'このMVPでは複数利用者や病院管理者の設定はありません。',
                        style: TextStyle(
                          color: _inkSoft,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QualificationSetupPage extends StatelessWidget {
  const _QualificationSetupPage({
    required this.qualifications,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onAddQualification,
    required this.onRemoveQualification,
  });

  final List<_QualificationDraft> qualifications;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onAddQualification;
  final ValueChanged<int> onRemoveQualification;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('保有資格を登録', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          '外科・内科は下のボタンからすぐ選べます。それ以外は「その他」から診療分野で検索できます。',
          style: TextStyle(color: _inkSoft, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 22),
        ...qualifications.asMap().entries.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SetupQualificationCard(
              key: ValueKey(item.value.id),
              number: item.key + 1,
              draft: item.value,
              canRemove: qualifications.length > 1,
              onRemove: () => onRemoveQualification(item.value.id),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddQualification,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('資格を追加'),
        ),
        const SizedBox(height: 18),
        Card(
          child: SwitchListTile(
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: _primary,
            ),
            title: const Text(
              '更新期限のお知らせ',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('既定：365・180・90・30・7日前'),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _neutralSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _ink, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '資格を選ぶと、総単位・区分別単位・必須講習などの更新条件を自動設定します。登録後に内容を確認・修正できます。',
                  style: TextStyle(color: _ink, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupQualificationCard extends StatefulWidget {
  const _SetupQualificationCard({
    super.key,
    required this.number,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final int number;
  final _QualificationDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_SetupQualificationCard> createState() =>
      _SetupQualificationCardState();
}

class _SetupQualificationCardState extends State<_SetupQualificationCard> {
  late final TextEditingController _organizationController;
  TextEditingController? _qualificationController;
  FocusNode? _qualificationFocusNode;
  QualificationCatalogEntry? _selectedEntry;
  bool _isOtherSelected = false;
  final Set<String> _selectedSubspecialtyNames = {};

  bool get _showsSurgicalSubspecialties =>
      _selectedEntry?.name == surgeryBaseQualificationName;

  @override
  void initState() {
    super.initState();
    _organizationController = TextEditingController(
      text: widget.draft.organization,
    );
    _selectedSubspecialtyNames.addAll(widget.draft.subspecialtyNames);
    for (final entry in qualificationCatalog) {
      if (entry.name == widget.draft.name) {
        _selectedEntry = entry;
        _isOtherSelected =
            entry.name != surgeryBaseQualificationName &&
            entry.name != internalMedicineBaseQualificationName;
        break;
      }
    }
    if (_selectedEntry == null && widget.draft.name.trim().isNotEmpty) {
      _isOtherSelected = true;
    }
  }

  @override
  void dispose() {
    _organizationController.dispose();
    super.dispose();
  }

  Iterable<QualificationCatalogEntry> _findOptions(
    TextEditingValue textEditingValue,
  ) {
    final query = textEditingValue.text.trim();
    if (query.isEmpty) return qualificationCatalog.take(12);
    final options = qualificationCatalog
        .where((entry) => entry.matches(query))
        .toList();
    options.sort((a, b) {
      final scoreComparison = a
          .matchScore(query)!
          .compareTo(b.matchScore(query)!);
      if (scoreComparison != 0) return scoreComparison;
      return qualificationCatalog
          .indexOf(a)
          .compareTo(qualificationCatalog.indexOf(b));
    });
    return options.take(50);
  }

  QualificationCatalogEntry _entryNamed(String name) {
    return qualificationCatalog.firstWhere((entry) => entry.name == name);
  }

  void _selectQualification(
    QualificationCatalogEntry entry, {
    bool updateQualificationName = false,
  }) {
    if (updateQualificationName) {
      _qualificationController?.value = TextEditingValue(
        text: entry.name,
        selection: TextSelection.collapsed(offset: entry.name.length),
      );
    }
    _organizationController.text = entry.organization;
    widget.draft.name = entry.name;
    widget.draft.organization = entry.organization;
    setState(() {
      _selectedEntry = entry;
      _isOtherSelected =
          entry.name != surgeryBaseQualificationName &&
          entry.name != internalMedicineBaseQualificationName;
      if (entry.name != surgeryBaseQualificationName) {
        _selectedSubspecialtyNames.clear();
      }
    });
  }

  void _selectQuickQualification(String name) {
    FocusScope.of(context).unfocus();
    _selectQualification(_entryNamed(name), updateQualificationName: true);
  }

  void _selectOtherQualification() {
    _qualificationController?.clear();
    _organizationController.clear();
    widget.draft.name = '';
    widget.draft.organization = '';
    widget.draft.subspecialtyNames = {};
    setState(() {
      _isOtherSelected = true;
      _selectedEntry = null;
      _selectedSubspecialtyNames.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _qualificationFocusNode?.requestFocus();
    });
  }

  void _handleQualificationTextChanged(String value) {
    widget.draft.name = value;
    if (_selectedEntry?.name == value) return;
    setState(() {
      _isOtherSelected = true;
      _selectedEntry = null;
      _selectedSubspecialtyNames.clear();
      widget.draft.subspecialtyNames = {};
    });
  }

  void _setSubspecialtySelected(String name, bool selected) {
    setState(() {
      if (selected) {
        _selectedSubspecialtyNames.add(name);
      } else {
        _selectedSubspecialtyNames.remove(name);
      }
      widget.draft.subspecialtyNames = Set<String>.from(
        _selectedSubspecialtyNames,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '資格 ${widget.number}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    tooltip: '資格を削除',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'よく使う基本領域',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '当てはまる方を1つ選んでください',
              style: TextStyle(color: _inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PrimaryQualificationButton(
                    key: const ValueKey('quick-primary-surgery'),
                    title: surgeryBaseQualificationName,
                    subtitle: '外科系',
                    icon: Icons.medical_services_outlined,
                    selected:
                        _selectedEntry?.name == surgeryBaseQualificationName,
                    onTap: () =>
                        _selectQuickQualification(surgeryBaseQualificationName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PrimaryQualificationButton(
                    key: const ValueKey('quick-primary-internal-medicine'),
                    title: internalMedicineBaseQualificationName,
                    subtitle: '内科系',
                    icon: Icons.healing_outlined,
                    selected:
                        _selectedEntry?.name ==
                        internalMedicineBaseQualificationName,
                    onTap: () => _selectQuickQualification(
                      internalMedicineBaseQualificationName,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PrimaryQualificationButton(
              key: const ValueKey('quick-primary-other'),
              title: 'その他',
              subtitle: '診療分野から検索',
              icon: Icons.grid_view_rounded,
              selected: _isOtherSelected,
              onTap: _selectOtherQualification,
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '資格名・診療分野から検索',
                    style: TextStyle(color: _inkSoft, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            Autocomplete<QualificationCatalogEntry>(
              initialValue: TextEditingValue(text: widget.draft.name),
              displayStringForOption: (entry) => entry.name,
              optionsBuilder: _findOptions,
              onSelected: _selectQualification,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    _qualificationController = controller;
                    _qualificationFocusNode = focusNode;
                    return TextFormField(
                      key: ValueKey('qualification-name-${widget.draft.id}'),
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: _handleQualificationTextChanged,
                      decoration: const InputDecoration(
                        labelText: '資格名（候補から選択）',
                        hintText: '例：小児、循環器、超音波',
                        helperText: '資格名の先頭1文字から検索できます',
                        suffixIcon: Icon(Icons.search_rounded),
                      ),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                final entries = options.toList();
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 520,
                        maxHeight: 300,
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return InkWell(
                            onTap: () => onSelected(entry),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.name,
                                          style: const TextStyle(
                                            color: _ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primarySoft,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          entry.category,
                                          style: const TextStyle(
                                            color: _primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.organization,
                                    style: const TextStyle(
                                      color: _inkSoft,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _selectedEntry == null
                  ? const Row(
                      key: ValueKey('qualification-search-hint'),
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _inkSoft,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '候補を選ぶと認定団体と更新条件を自動設定します',
                            style: TextStyle(color: _inkSoft, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      key: ValueKey('organization-autofilled'),
                      children: [
                        Icon(Icons.check_circle, size: 16, color: _primary),
                        SizedBox(width: 6),
                        Text(
                          '認定団体と更新条件を自動設定しました',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('qualification-organization-${widget.draft.id}'),
              controller: _organizationController,
              onChanged: (value) => widget.draft.organization = value,
              decoration: const InputDecoration(
                labelText: '認定団体',
                helperText: '必要に応じて修正できます',
              ),
            ),
            if (_showsSurgicalSubspecialties) ...[
              const SizedBox(height: 18),
              _SurgicalSubspecialtySection(
                qualificationId: widget.draft.id,
                entries: surgicalSubspecialtyCatalog,
                selectedNames: _selectedSubspecialtyNames,
                onChanged: _setSubspecialtySelected,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.licenseNumber,
              onChanged: (value) => widget.draft.licenseNumber = value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _selectedEntry == null
                    ? '資格番号（任意）'
                    : '${_selectedEntry!.name}の資格番号（任意）',
                hintText: '認定証・会員マイページを確認',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.memberId,
              onChanged: (value) => widget.draft.memberId = value,
              decoration: const InputDecoration(
                labelText: '学会会員ID（任意）',
                hintText: '会員サイトで使うID・会員番号',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.memberPortalUrl,
              onChanged: (value) => widget.draft.memberPortalUrl = value,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '学会会員サイトURL（任意）',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.deadline,
              onChanged: (value) => widget.draft.deadline = value,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: _selectedEntry == null
                    ? '次回更新期限'
                    : '${_selectedEntry!.name}の次回更新期限',
                hintText: 'YYYY/MM/DD',
                suffixIcon: const Icon(Icons.event_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryQualificationButton extends StatelessWidget {
  const _PrimaryQualificationButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$titleを選択',
      child: Material(
        color: selected ? _primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _primary : _line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _primary : _track,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : icon,
                    color: selected ? Colors.white : _primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _inkSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurgicalSubspecialtySection extends StatelessWidget {
  const _SurgicalSubspecialtySection({
    required this.qualificationId,
    required this.entries,
    required this.selectedNames,
    required this.onChanged,
  });

  final int qualificationId;
  final List<QualificationCatalogEntry> entries;
  final Set<String> selectedNames;
  final void Function(String name, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surgical-subspecialty-section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _sectionTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _sectionLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconTile(
                icon: Icons.account_tree_outlined,
                color: _primary,
                background: _primarySoft,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '外科のサブスペシャルティ',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '保有している資格を複数選択できます',
                      style: TextStyle(color: _inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map((entry) {
            final selected = selectedNames.contains(entry.name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SubspecialtyChoice(
                key: ValueKey('subspecialty-$qualificationId-${entry.name}'),
                entry: entry,
                selected: selected,
                onChanged: (value) => onChanged(entry.name, value),
              ),
            );
          }),
          const SizedBox(height: 2),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _inkSoft),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '日本専門医機構の領域一覧に基づく6領域です。更新方法は各団体の公式情報で確認してください。',
                  style: TextStyle(color: _inkSoft, fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubspecialtyChoice extends StatelessWidget {
  const _SubspecialtyChoice({
    super.key,
    required this.entry,
    required this.selected,
    required this.onChanged,
  });

  final QualificationCatalogEntry entry;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _primary : _line),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            title: Text(
              entry.name,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              entry.organization,
              style: const TextStyle(
                color: _inkSoft,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          if (selected) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '資格番号（任意）',
                      hintText: '認定証を確認',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: '次回更新期限',
                      hintText: 'YYYY/MM/DD',
                      suffixIcon: Icon(Icons.event_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.controller,
    this.authService,
    this.authUser,
  });

  final AppController controller;
  final AuthService? authService;
  final AuthUser? authUser;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final AttachmentService _attachmentService = createAttachmentService();

  Future<void> _openRegistration() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RegistrationChoiceSheet(),
    );
    if (!mounted || source == null) return;
    PickedAttachment? attachment;
    final usesAttachment = source != '手入力' && source != '参加予定';
    if (widget.controller.demoMode && usesAttachment) {
      attachment = const PickedAttachment(displayName: '受講証明書_0818.jpg');
    } else if (usesAttachment) {
      try {
        attachment = await _attachmentService.pick(source);
      } on Object {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ファイルを取り込めませんでした。もう一度お試しください')),
        );
        return;
      }
      if (!mounted || attachment == null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CertificateReviewScreen(
          source: source,
          controller: widget.controller,
          attachment: attachment,
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    if (index == 1) {
      _openRegistration();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selectedIndex) {
      2 => ActivityListScreen(controller: widget.controller),
      3 => SettingsScreen(
        controller: widget.controller,
        authService: widget.authService,
        authUser: widget.authUser,
      ),
      _ => HomeScreen(
        controller: widget.controller,
        onRegister: _openRegistration,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 78,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            selectedIcon: Icon(Icons.add_a_photo_rounded),
            label: '参加証',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: '実績',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onRegister,
  });

  final AppController controller;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final qualifications = controller.demoMode
        ? sampleQualifications
        : controller.snapshot.qualifications
              .map(
                (stored) =>
                    qualificationFromStored(stored, controller.snapshot),
              )
              .toList(growable: false);
    final datedQualifications =
        qualifications.where((item) => item.deadline != '未登録').toList()
          ..sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
    final nextQualification = datedQualifications.firstOrNull;
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList.list(
            children: [
              _TopBar(
                displayName: controller.snapshot.displayName,
                isDemo: controller.demoMode,
              ),
              const SizedBox(height: 26),
              Text(
                '資格更新の状況',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日 現在',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _inkSoft),
              ),
              const SizedBox(height: 20),
              if (controller.demoMode) ...[
                _AttentionBanner(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CertificateReviewScreen(
                          source: '保存済みの写真',
                          controller: controller,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
              if (nextQualification != null) ...[
                _NextDeadlineCard(
                  qualification: nextQualification,
                  onTap: () => _openQualification(context, nextQualification),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('参加証を登録する'),
              ),
              const SizedBox(height: 30),
              _SectionHeading(title: '保有資格', trailing: '期限が近い順', onTap: () {}),
              const SizedBox(height: 12),
              ...qualifications.map(
                (qualification) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QualificationCard(
                    qualification: qualification,
                    onTap: () => _openQualification(context, qualification),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _OfficialInfoNote(),
            ],
          ),
        ),
      ],
    );
  }

  void _openQualification(BuildContext context, Qualification qualification) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QualificationDetailScreen(
          qualification: qualification,
          controller: controller,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.displayName, required this.isDemo});

  final String displayName;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.workspace_premium_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '資格更新ノート',
                style: TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (displayName.trim().isNotEmpty)
                Text(
                  '${displayName.trim()}さんの資格管理',
                  style: const TextStyle(color: _inkSoft, fontSize: 14),
                ),
              const SizedBox(height: 2),
              const Text(
                '本人専用',
                style: TextStyle(color: _inkSoft, fontSize: 14),
              ),
            ],
          ),
        ),
        if (isDemo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'サンプルデータ',
              style: TextStyle(
                color: _primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _warningSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _warningStrong, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _IconTile(
                icon: Icons.priority_high_rounded,
                color: _warning,
                background: _warningStrong,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '確認が必要な実績が1件あります',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '読み取り内容を確認してください',
                      style: TextStyle(color: _warningInk, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _warningInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextDeadlineCard extends StatelessWidget {
  const _NextDeadlineCard({required this.qualification, required this.onTap});

  final Qualification qualification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '次の更新期限',
                      style: TextStyle(
                        color: _onInkMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      qualification.remainingDays >= 0
                          ? 'あと${qualification.remainingDays}日'
                          : '${-qualification.remainingDays}日超過',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                qualification.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                qualification.deadline,
                style: const TextStyle(color: _onInkSoft, fontSize: 16),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _accentGold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qualification.headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing, this.onTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (trailing != null)
          TextButton(onPressed: onTap, child: Text(trailing!)),
      ],
    );
  }
}

class QualificationCard extends StatelessWidget {
  const QualificationCard({
    super.key,
    required this.qualification,
    required this.onTap,
  });

  final Qualification qualification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(qualification.state);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          qualification.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '期限 ${qualification.deadline}',
                          style: const TextStyle(color: _inkSoft, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: style.label,
                    foreground: style.foreground,
                    background: style.background,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (qualification.hasVerifiedRequirements)
                Row(
                  children: [
                    Text(
                      '${qualification.total.toInt()} / ${qualification.requiredTotal.toInt()} 単位',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(qualification.progress * 100).round()}%',
                      style: const TextStyle(
                        color: _primaryDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Text(
                      '現在 ${_formatNumber(qualification.total)}単位',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    if (qualification.plannedTotal > 0) ...[
                      const SizedBox(width: 10),
                      _MiniPill(
                        label:
                            '予定 +${_formatNumber(qualification.plannedTotal)}単位',
                        emphasized: true,
                      ),
                    ],
                  ],
                ),
              if (qualification.requiredTotal > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: qualification.progress,
                    minHeight: 10,
                    backgroundColor: _track,
                    color: style.foreground,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    qualification.state == QualificationState.onTrack
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    color: style.foreground,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qualification.headline,
                      style: TextStyle(
                        color: style.foreground,
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _inkSoft),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficialInfoNote extends StatelessWidget {
  const _OfficialInfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _neutralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: _ink, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'このアプリは自己管理を支援するものです。更新申請前に、必ず資格団体の公式情報をご確認ください。',
              style: TextStyle(color: _ink, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OfficialRuleViewState { ready, loading, unavailable, failed }

class QualificationDetailScreen extends StatefulWidget {
  const QualificationDetailScreen({
    super.key,
    required this.qualification,
    this.controller,
    this.officialRuleLoader,
  });

  final Qualification qualification;
  final AppController? controller;
  final OfficialRuleLoader? officialRuleLoader;

  @override
  State<QualificationDetailScreen> createState() =>
      _QualificationDetailScreenState();
}

class _QualificationDetailScreenState extends State<QualificationDetailScreen> {
  late Qualification _qualification;
  late _OfficialRuleViewState _ruleState;
  String? _ruleError;

  @override
  void initState() {
    super.initState();
    _qualification = widget.qualification;
    _ruleState = _qualification.hasVerifiedRequirements
        ? _OfficialRuleViewState.ready
        : _OfficialRuleViewState.loading;
    if (!_qualification.hasVerifiedRequirements) {
      unawaited(_loadOfficialRule());
    }
  }

  Future<void> _loadOfficialRule() async {
    if (mounted) {
      setState(() {
        _ruleState = _OfficialRuleViewState.loading;
        _ruleError = null;
      });
    }
    try {
      final customLoader = widget.officialRuleLoader;
      final lookup = customLoader != null
          ? await customLoader(_qualification.name)
          : await const OfficialRuleService().fetchForQualification(
              _qualification.name,
              renewalYear: _parseFlexibleDate(_qualification.deadline)?.year,
            );
      if (!mounted) return;
      setState(() {
        final rule = lookup.rule;
        if (rule == null) {
          _ruleState = _OfficialRuleViewState.unavailable;
        } else {
          _qualification = qualificationWithOfficialRule(_qualification, rule);
          _ruleState = _OfficialRuleViewState.ready;
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _ruleState = _OfficialRuleViewState.failed;
        _ruleError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String get _ringLabel => switch (_ruleState) {
    _OfficialRuleViewState.ready when _qualification.requiredTotal > 0 =>
      '${(_qualification.progress * 100).round()}%',
    _OfficialRuleViewState.ready => '取得済',
    _OfficialRuleViewState.loading => '取得中',
    _OfficialRuleViewState.unavailable => '未公開',
    _OfficialRuleViewState.failed => '再取得',
  };

  String get _progressLabel => switch (_ruleState) {
    _OfficialRuleViewState.ready when _qualification.requiredTotal > 0 =>
      '${_formatNumber(_qualification.total)} / ${_formatNumber(_qualification.requiredTotal)} 単位',
    _OfficialRuleViewState.ready => '公式条件を取得しました',
    _OfficialRuleViewState.loading => '条件を自動取得しています',
    _OfficialRuleViewState.unavailable => '承認済み条件はまだありません',
    _OfficialRuleViewState.failed => '条件を取得できませんでした',
  };

  String get _headline => switch (_ruleState) {
    _OfficialRuleViewState.ready => _qualification.headline,
    _OfficialRuleViewState.loading => '公開APIから最新条件を確認中です',
    _OfficialRuleViewState.unavailable => '管理画面で承認されると自動表示されます',
    _OfficialRuleViewState.failed => '通信状況を確認して再取得してください',
  };

  Future<void> _editQualification() async {
    final controller = widget.controller;
    if (controller == null || _qualification.id.isEmpty) return;
    final stored = controller.snapshot.qualifications
        .where((item) => item.id == _qualification.id)
        .firstOrNull;
    if (stored == null) return;
    final updated = await showDialog<StoredQualification>(
      context: context,
      builder: (context) => _QualificationEditDialog(qualification: stored),
    );
    if (updated == null) return;
    await controller.updateQualification(updated);
    if (!mounted) return;
    setState(() {
      _qualification = qualificationFromStored(updated, controller.snapshot);
      _ruleState = _OfficialRuleViewState.loading;
    });
    await _loadOfficialRule();
  }

  @override
  Widget build(BuildContext context) {
    final qualification = _qualification;
    final status = _statusStyle(qualification.state);
    final creditEntries = qualification.isDemo
        ? creditBreakdownByQualification[qualification.name] ?? const []
        : qualification.creditEntries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('資格の詳細'),
        backgroundColor: _canvas,
        actions: [
          IconButton(
            tooltip: '編集',
            onPressed: widget.controller != null && qualification.id.isNotEmpty
                ? _editQualification
                : null,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  qualification.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  qualification.organization,
                  style: TextStyle(color: _inkSoft),
                ),
                const SizedBox(height: 20),
                Card(
                  color: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value:
                                      _ruleState ==
                                          _OfficialRuleViewState.loading
                                      ? null
                                      : qualification.progress,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .14,
                                  ),
                                  color: _onInkAccent,
                                ),
                              ),
                              Text(
                                _ringLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '現在の進捗',
                                style: TextStyle(
                                  color: _onInkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _progressLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _headline,
                                style: TextStyle(
                                  color: status.background,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _DeadlineRow(qualification: qualification),
                const SizedBox(height: 12),
                _PointForecastCard(qualification: qualification),
                if (qualification.licenseNumber.isNotEmpty ||
                    qualification.memberId.isNotEmpty ||
                    qualification.memberPortalUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MembershipCard(qualification: qualification),
                ],
                const SizedBox(height: 28),
                const _SectionHeading(title: '更新条件'),
                const SizedBox(height: 12),
                if (!qualification.hasVerifiedRequirements)
                  _OfficialRuleStateCard(
                    state: _ruleState,
                    error: _ruleError,
                    onRetry: _loadOfficialRule,
                  )
                else ...[
                  _OfficialRuleSummary(qualification: qualification),
                  const SizedBox(height: 10),
                ],
                ...qualification.requirements.map(
                  (requirement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RequirementCard(requirement: requirement),
                  ),
                ),
                if (qualification.hasVerifiedRequirements &&
                    (qualification.mandatoryNotes.isNotEmpty ||
                        qualification.otherConditions.isNotEmpty)) ...[
                  const SizedBox(height: 2),
                  _OfficialConditionsCard(qualification: qualification),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '単位の内訳',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${creditEntries.length}件・合計${_formatNumber(creditEntries.fold<double>(0, (sum, entry) => sum + entry.credits))}単位',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('講習・学会ごとの取得単位を確認できます', style: TextStyle(color: _inkSoft)),
                const SizedBox(height: 12),
                if (creditEntries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'この資格に割り当てられた確定実績はまだありません。',
                        style: TextStyle(color: _inkSoft),
                      ),
                    ),
                  )
                else ...[
                  _CreditBreakdownSummary(entries: creditEntries),
                  const SizedBox(height: 12),
                  ...creditEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CreditBreakdownCard(
                        entry: entry,
                        onTap: () => _showCreditBreakdownDetail(
                          context,
                          qualification,
                          entry,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 5,
                        ),
                        leading: const _IconTile(
                          icon: Icons.receipt_long_outlined,
                          color: _primary,
                          background: _primarySoft,
                        ),
                        title: const Text(
                          '登録済みの実績',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${creditEntries.length}件'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showPrototypeMessage(
                          context,
                          'この資格に反映された実績を表示します',
                        ),
                      ),
                      const Divider(height: 1, indent: 76),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 5,
                        ),
                        leading: const _IconTile(
                          icon: Icons.policy_outlined,
                          color: _ink,
                          background: _neutralSoft,
                        ),
                        title: const Text(
                          '規定・根拠資料',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          qualification.sourceCheckedAt == null
                              ? '承認済みの公式資料はまだありません'
                              : '公式資料を${_formatJapaneseDate(qualification.sourceCheckedAt!)}に確認',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: qualification.sourceUrl == null
                            ? null
                            : () => _showEvidenceSheet(context, qualification),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _showPrototypeMessage(
                    context,
                    '通知は期限の180日前・90日前・30日前に設定されています',
                  ),
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('通知設定を確認'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialRuleStateCard extends StatelessWidget {
  const _OfficialRuleStateCard({
    required this.state,
    required this.onRetry,
    this.error,
  });

  final _OfficialRuleViewState state;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final loading = state == _OfficialRuleViewState.loading;
    final failed = state == _OfficialRuleViewState.failed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(
                failed
                    ? Icons.cloud_off_outlined
                    : Icons.pending_actions_outlined,
                color: failed ? _danger : _warning,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? '承認済みの更新条件を自動取得しています'
                        : failed
                        ? '更新条件を取得できませんでした'
                        : '承認済みの更新条件はまだありません',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    loading
                        ? '資格名に一致する制度区分・単位条件・出典を確認しています。'
                        : failed
                        ? (error ?? '通信状況を確認して再度お試しください。')
                        : '管理画面で公式資料の内容を承認すると、この画面へ自動表示されます。',
                    style: const TextStyle(color: _inkSoft, height: 1.5),
                  ),
                  if (!loading) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('再取得する'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialRuleSummary extends StatelessWidget {
  const _OfficialRuleSummary({required this.qualification});

  final Qualification qualification;

  @override
  Widget build(BuildContext context) {
    final cycle = qualification.renewalCycleYears;
    final total = qualification.requiredTotal;
    return Card(
      color: _primarySoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: _primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '承認済みの公式条件',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (qualification.systemType != null)
                  _RuleFactChip(label: qualification.systemType!),
                if (cycle != null)
                  _RuleFactChip(label: '更新周期 ${_formatNumber(cycle)}年'),
                if (qualification.renewalYearFrom != null &&
                    qualification.renewalYearTo != null)
                  _RuleFactChip(
                    label:
                        qualification.renewalYearFrom ==
                            qualification.renewalYearTo
                        ? '更新期限 ${qualification.renewalYearFrom}年'
                        : '更新期限 ${qualification.renewalYearFrom}〜${qualification.renewalYearTo}年',
                  ),
                if (total > 0)
                  _RuleFactChip(label: '必要総単位 ${_formatNumber(total)}単位'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleFactChip extends StatelessWidget {
  const _RuleFactChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OfficialConditionsCard extends StatelessWidget {
  const _OfficialConditionsCard({required this.qualification});

  final Qualification qualification;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (qualification.mandatoryNotes.isNotEmpty) ...[
              const Text(
                '必須事項',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...qualification.mandatoryNotes.map(
                (item) => _ConditionBullet(text: item, color: _warning),
              ),
            ],
            if (qualification.mandatoryNotes.isNotEmpty &&
                qualification.otherConditions.isNotEmpty)
              const Divider(height: 24),
            if (qualification.otherConditions.isNotEmpty) ...[
              const Text(
                'その他の条件',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...qualification.otherConditions.map(
                (item) => _ConditionBullet(text: item, color: _primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConditionBullet extends StatelessWidget {
  const _ConditionBullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _ink, fontSize: 14, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatJapaneseDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}年${local.month}月${local.day}日';
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.qualification});

  final Qualification qualification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const _IconTile(
            icon: Icons.event_outlined,
            color: _primary,
            background: _primarySoft,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '次回の更新期限',
                  style: TextStyle(color: _inkSoft, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  qualification.deadline,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (qualification.deadline != '未登録')
            Text(
              qualification.remainingDays >= 0
                  ? 'あと${qualification.remainingDays}日'
                  : '${-qualification.remainingDays}日超過',
              style: const TextStyle(
                color: _danger,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _PointForecastCard extends StatelessWidget {
  const _PointForecastCard({required this.qualification});

  final Qualification qualification;

  @override
  Widget build(BuildContext context) {
    final gap = qualification.requiredTotal - qualification.projectedTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ポイント見込み',
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PointMetric(
                    label: '現在',
                    value: _formatNumber(qualification.total),
                    color: _primary,
                  ),
                ),
                Expanded(
                  child: _PointMetric(
                    label: '参加予定',
                    value: '+${_formatNumber(qualification.plannedTotal)}',
                    color: _warning,
                  ),
                ),
                Expanded(
                  child: _PointMetric(
                    label: '見込み',
                    value: _formatNumber(qualification.projectedTotal),
                    color: _ink,
                  ),
                ),
              ],
            ),
            if (qualification.requiredTotal > 0) ...[
              const SizedBox(height: 14),
              Text(
                gap <= 0
                    ? '予定を含めると必要な${_formatNumber(qualification.requiredTotal)}単位に到達します'
                    : '予定を含めてもあと${_formatNumber(gap)}単位必要です',
                style: TextStyle(
                  color: gap <= 0 ? _primary : _warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PointMetric extends StatelessWidget {
  const _PointMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _inkSoft, fontSize: 13)),
        const SizedBox(height: 3),
        Text(
          '$value単位',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.qualification});

  final Qualification qualification;

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$labelをコピーしました')));
  }

  Future<void> _openPortal(BuildContext context) async {
    final raw = qualification.memberPortalUrl.trim();
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('会員サイトを開けませんでした')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (qualification.licenseNumber.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('資格番号'),
              subtitle: SelectableText(qualification.licenseNumber),
              trailing: const Icon(Icons.copy_rounded),
              onTap: () => _copy(context, qualification.licenseNumber, '資格番号'),
            ),
          if (qualification.licenseNumber.isNotEmpty &&
              qualification.memberId.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          if (qualification.memberId.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('学会会員ID'),
              subtitle: SelectableText(qualification.memberId),
              trailing: const Icon(Icons.copy_rounded),
              onTap: () => _copy(context, qualification.memberId, '学会会員ID'),
            ),
          if ((qualification.licenseNumber.isNotEmpty ||
                  qualification.memberId.isNotEmpty) &&
              qualification.memberPortalUrl.isNotEmpty)
            const Divider(height: 1, indent: 16, endIndent: 16),
          if (qualification.memberPortalUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded, color: _primary),
              title: const Text('学会会員サイトを開く'),
              subtitle: Text(
                qualification.memberPortalUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openPortal(context),
            ),
        ],
      ),
    );
  }
}

class _QualificationEditDialog extends StatefulWidget {
  const _QualificationEditDialog({required this.qualification});

  final StoredQualification qualification;

  @override
  State<_QualificationEditDialog> createState() =>
      _QualificationEditDialogState();
}

class _QualificationEditDialogState extends State<_QualificationEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _organizationController;
  late final TextEditingController _licenseController;
  late final TextEditingController _memberIdController;
  late final TextEditingController _portalController;
  late final TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    final qualification = widget.qualification;
    _nameController = TextEditingController(text: qualification.name);
    _organizationController = TextEditingController(
      text: qualification.organization,
    );
    _licenseController = TextEditingController(
      text: qualification.licenseNumber,
    );
    _memberIdController = TextEditingController(text: qualification.memberId);
    _portalController = TextEditingController(
      text: qualification.memberPortalUrl,
    );
    _deadlineController = TextEditingController(text: qualification.deadline);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _licenseController.dispose();
    _memberIdController.dispose();
    _portalController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      widget.qualification.copyWith(
        name: _nameController.text.trim(),
        organization: _organizationController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        memberId: _memberIdController.text.trim(),
        memberPortalUrl: _portalController.text.trim(),
        deadline: _deadlineController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('資格情報を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '資格名'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _organizationController,
              decoration: const InputDecoration(labelText: '認定団体・学会'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(labelText: '資格番号（任意）'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _memberIdController,
              decoration: const InputDecoration(labelText: '学会会員ID（任意）'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portalController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: '学会会員サイトURL（任意）'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _deadlineController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: '次回更新期限',
                hintText: 'YYYY/MM/DD',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class RequirementCard extends StatelessWidget {
  const RequirementCard({super.key, required this.requirement});

  final RequirementProgress requirement;

  @override
  Widget build(BuildContext context) {
    final color = requirement.isComplete ? _primary : _warning;
    final missing = requirement.requiredValue - requirement.current;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    requirement.label,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  requirement.isComplete
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: color,
                  size: 21,
                ),
                const SizedBox(width: 5),
                Text(
                  requirement.isComplete
                      ? '達成'
                      : 'あと${_formatNumber(missing)}${requirement.unit}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: requirement.progress,
                      minHeight: 10,
                      backgroundColor: _track,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${_formatNumber(requirement.current)} / ${_formatNumber(requirement.requiredValue)} ${requirement.unit}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (requirement.note != null) ...[
              const SizedBox(height: 8),
              Text(
                requirement.note!,
                style: TextStyle(color: _inkSoft, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreditBreakdownSummary extends StatelessWidget {
  const _CreditBreakdownSummary({required this.entries});

  final List<CreditBreakdownEntry> entries;

  @override
  Widget build(BuildContext context) {
    final conferenceCredits = entries
        .where((entry) => entry.eventType == '学会')
        .fold<double>(0, (sum, entry) => sum + entry.credits);
    final lectureCredits = entries
        .where((entry) => entry.eventType == '講習')
        .fold<double>(0, (sum, entry) => sum + entry.credits);

    return Row(
      children: [
        Expanded(
          child: _BreakdownTotalTile(
            icon: Icons.groups_2_outlined,
            label: '学会・発表',
            value: '${_formatNumber(conferenceCredits)}単位',
            color: _ink,
            background: _neutralSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BreakdownTotalTile(
            icon: Icons.school_outlined,
            label: '講習',
            value: '${_formatNumber(lectureCredits)}単位',
            color: _primary,
            background: _primarySoft,
          ),
        ),
      ],
    );
  }
}

class _BreakdownTotalTile extends StatelessWidget {
  const _BreakdownTotalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreditBreakdownCard extends StatelessWidget {
  const CreditBreakdownCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final CreditBreakdownEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isConference = entry.eventType == '学会';
    final color = isConference ? _ink : _primary;
    final background = isConference ? _neutralSoft : _primarySoft;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: isConference
                    ? Icons.groups_2_outlined
                    : Icons.school_outlined,
                color: color,
                background: background,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_formatNumber(entry.credits)}単位',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.date} ・ ${entry.organizer}',
                      style: const TextStyle(color: _inkSoft, fontSize: 14),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _MiniPill(label: entry.eventType),
                        _MiniPill(label: entry.category, emphasized: true),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: _inkSoft,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          entry.certificationId.isEmpty
                              ? 'タップして実績の詳細を確認'
                              : 'タップして10桁IDを確認',
                          style: const TextStyle(
                            color: _inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 38),
                child: Icon(Icons.chevron_right_rounded, color: _inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationChoiceSheet extends StatelessWidget {
  const RegistrationChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 22 + bottomPadding),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '参加証・参加予定を登録',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '登録方法を選んでください',
                style: TextStyle(color: _inkSoft, fontSize: 15),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _RegistrationChoice(
                    icon: Icons.photo_camera_outlined,
                    label: 'カメラで撮る',
                    subtitle: '紙の参加証',
                    onTap: () => Navigator.pop(context, 'カメラ撮影'),
                  ),
                  _RegistrationChoice(
                    icon: Icons.photo_library_outlined,
                    label: '写真から選ぶ',
                    subtitle: '保存済みの画像',
                    onTap: () => Navigator.pop(context, '写真ライブラリ'),
                  ),
                  _RegistrationChoice(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDFを選ぶ',
                    subtitle: '受講証明書など',
                    onTap: () => Navigator.pop(context, 'PDFファイル'),
                  ),
                  _RegistrationChoice(
                    icon: Icons.edit_note_outlined,
                    label: '手入力する',
                    subtitle: '証明書がない場合',
                    onTap: () => Navigator.pop(context, '手入力'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                width: double.infinity,
                child: _RegistrationChoice(
                  icon: Icons.event_available_outlined,
                  label: '参加予定を登録',
                  subtitle: '予定ポイントを見込みへ反映',
                  onTap: () => Navigator.pop(context, '参加予定'),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 19, color: _primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '患者情報が写った画像は登録しないでください。画像は対応端末では端末内でOCRし、氏名・会員番号などラベル付き個人情報を除いた文字を認証済みAI APIへ送ります。Web版または端末内OCR失敗時は添付ファイルを送る場合があります。読み取り内容は確定前に必ず確認します。',
                      style: TextStyle(
                        color: _inkSoft,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistrationChoice extends StatelessWidget {
  const _RegistrationChoice({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconTile(icon: icon, color: _primary, background: _primarySoft),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _inkSoft, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CertificateReviewScreen extends StatefulWidget {
  const CertificateReviewScreen({
    super.key,
    required this.source,
    required this.controller,
    this.attachment,
    this.ocrService,
  });

  final String source;
  final AppController controller;
  final PickedAttachment? attachment;
  final CertificateOcrService? ocrService;

  @override
  State<CertificateReviewScreen> createState() =>
      _CertificateReviewScreenState();
}

class _CertificateReviewScreenState extends State<CertificateReviewScreen> {
  late final CertificateOcrService _ocrService;
  late final TextEditingController _eventController;
  late final TextEditingController _dateController;
  late final TextEditingController _organizerController;
  late final TextEditingController _creditsController;
  late final TextEditingController _categoryController;
  late final TextEditingController _eventUrlController;
  late final TextEditingController _certificationIdController;
  late final TextEditingController _notesController;
  late final FocusNode _certificationIdFocusNode;
  final Set<String> _selectedQualificationIds = {};
  bool _saving = false;
  bool _reading = false;
  CertificateExtraction? _extraction;
  String? _readError;
  String? _ocrEngine;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ?? createCertificateOcrService();
    final usesSample = widget.controller.demoMode;
    _eventController = TextEditingController(
      text: usesSample ? '第42回 地域医療研修会' : '',
    );
    _dateController = TextEditingController(
      text: usesSample ? '2026/08/18' : '',
    );
    _organizerController = TextEditingController(
      text: usesSample ? '地域医療研修センター' : '',
    );
    _creditsController = TextEditingController(text: usesSample ? '2' : '');
    _categoryController = TextEditingController();
    _eventUrlController = TextEditingController();
    _certificationIdController = TextEditingController(
      text: usesSample ? '2608180042' : '',
    );
    _notesController = TextEditingController();
    _certificationIdFocusNode = FocusNode();
    _selectedQualificationIds.addAll(
      widget.controller.snapshot.qualifications.map((item) => item.id),
    );
    if (!usesSample &&
        widget.attachment != null &&
        widget.source != '手入力' &&
        widget.source != '参加予定') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _readAttachment());
    }
  }

  @override
  void dispose() {
    _eventController.dispose();
    _dateController.dispose();
    _organizerController.dispose();
    _creditsController.dispose();
    _categoryController.dispose();
    _eventUrlController.dispose();
    _certificationIdController.dispose();
    _notesController.dispose();
    _certificationIdFocusNode.dispose();
    super.dispose();
  }

  Future<void> _readAttachment() async {
    final attachment = widget.attachment;
    if (_reading || attachment == null) return;
    setState(() {
      _reading = true;
      _readError = null;
    });
    var ocrText = '';
    var includeAttachment = !_ocrService.isSupported;
    try {
      if (_ocrService.isSupported) {
        try {
          final ocr = await _ocrService.recognize(attachment);
          ocrText = ocr.text;
          _ocrEngine = ocr.engine;
        } on CertificateOcrException catch (error) {
          includeAttachment = true;
          _ocrEngine = null;
          _readError = error.message;
        }
      }
      final extraction = await widget.controller.extractCertificate(
        ocrText: ocrText,
        attachment: attachment,
        includeAttachment: includeAttachment,
      );
      if (!mounted) return;
      _applyExtraction(extraction);
      setState(() {
        _extraction = extraction;
        _readError = extraction.hasUsefulValues
            ? null
            : extraction.warnings.isNotEmpty
            ? extraction.warnings.first
            : '参加証の項目を自動判定できませんでした。';
      });
    } on CloudApiException catch (error) {
      if (!mounted) return;
      setState(() => _readError = error.message);
    } on Object {
      if (!mounted) return;
      setState(() => _readError = '参加証を自動読み取りできませんでした。手入力するか、再試行してください。');
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _applyExtraction(CertificateExtraction extraction) {
    if (extraction.title.isNotEmpty) _eventController.text = extraction.title;
    if (extraction.date.isNotEmpty) _dateController.text = extraction.date;
    if (extraction.organizer.isNotEmpty) {
      _organizerController.text = extraction.organizer;
    }
    final credits = extraction.credits;
    if (credits != null) {
      _creditsController.text = credits == credits.roundToDouble()
          ? credits.toInt().toString()
          : credits.toString();
    }
    if (extraction.category.isNotEmpty) {
      _categoryController.text = extraction.category;
    }
    if (extraction.certificationId.isNotEmpty) {
      _certificationIdController.text = extraction.certificationId;
    }
    if (extraction.qualificationNames.isNotEmpty) {
      final matched = widget.controller.snapshot.qualifications
          .where((item) => extraction.qualificationNames.contains(item.name))
          .map((item) => item.id)
          .toSet();
      if (matched.isNotEmpty) {
        _selectedQualificationIds
          ..clear()
          ..addAll(matched);
      }
    }
  }

  String? _confidenceLabel(String field) {
    final score = _extraction?.confidenceFor(field);
    if (score == null) return null;
    return '${(score * 100).round()}%';
  }

  bool _needsCheck(String field) =>
      (_extraction?.confidenceFor(field) ?? 1) < 0.85;

  void _applyCertificateIdSuggestion(_CertificateIdSuggestion suggestion) {
    setState(() {
      _certificationIdController.value = TextEditingValue(
        text: suggestion.certificationId,
        selection: TextSelection.collapsed(
          offset: suggestion.certificationId.length,
        ),
      );
      if (suggestion.title.isNotEmpty) {
        _eventController.text = suggestion.title;
      }
      if (suggestion.date.isNotEmpty) _dateController.text = suggestion.date;
      if (suggestion.organizer.isNotEmpty) {
        _organizerController.text = suggestion.organizer;
      }
      final credits = suggestion.credits;
      if (credits != null) {
        _creditsController.text = credits == credits.roundToDouble()
            ? credits.toInt().toString()
            : credits.toString();
      }
      if (suggestion.category.isNotEmpty) {
        _categoryController.text = suggestion.category;
      }
    });
  }

  Future<void> _save({required bool draft}) async {
    if (_saving) return;
    if (_eventController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('研修会・イベント名を入力してください')));
      return;
    }
    if (widget.source == '参加予定' &&
        _parseFlexibleDate(_dateController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開催日をYYYY/MM/DD形式で入力してください')),
      );
      return;
    }
    final credits = double.tryParse(_creditsController.text.trim()) ?? 0;
    if (credits < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ポイントは0以上で入力してください')));
      return;
    }
    final certificationId = _certificationIdController.text.trim();
    if (certificationId.isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(certificationId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('認定IDは10桁の数字で入力してください')));
      return;
    }
    setState(() => _saving = true);
    try {
      final attachmentPath = await widget.controller.uploadAttachment(
        widget.attachment,
      );
      final activity = StoredActivity(
        id: 'activity-${DateTime.now().microsecondsSinceEpoch}',
        title: _eventController.text.trim(),
        date: _dateController.text.trim(),
        organizer: _organizerController.text.trim(),
        status: draft
            ? '下書き'
            : widget.source == '参加予定'
            ? '参加予定'
            : '確定',
        credits: credits,
        source: widget.source,
        createdAt: DateTime.now().toIso8601String(),
        attachmentPath: attachmentPath,
        eventUrl: _eventUrlController.text.trim(),
        certificationId: certificationId,
        notes: _notesController.text.trim(),
        allocations: _selectedQualificationIds
            .map(
              (qualificationId) => StoredActivityAllocation(
                qualificationId: qualificationId,
                credits: credits,
                category: _categoryController.text.trim().isEmpty
                    ? '未分類'
                    : _categoryController.text.trim(),
              ),
            )
            .toList(growable: false),
      );
      await widget.controller.addActivity(activity);
      if (!mounted) return;
      if (draft) {
        Navigator.of(context).pop();
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationResultScreen(
            qualificationCount: _selectedQualificationIds.length,
            showSampleProgress: widget.controller.demoMode,
            isPlanned: widget.source == '参加予定',
          ),
        ),
      );
    } on CloudApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参加証を保存できませんでした。もう一度お試しください。')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManual = widget.source == '手入力';
    final isPlanned = widget.source == '参加予定';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPlanned
              ? '参加予定を登録'
              : isManual
              ? '実績を手入力'
              : '読み取り内容の確認',
        ),
        backgroundColor: _canvas,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 124),
              children: [
                const _StepIndicator(currentStep: 2),
                const SizedBox(height: 24),
                if (!isManual && !isPlanned) ...[
                  _CertificatePreview(
                    source: widget.source,
                    fileName: widget.attachment?.displayName,
                    hasReadResult:
                        widget.controller.demoMode ||
                        _extraction?.hasUsefulValues == true,
                  ),
                  const SizedBox(height: 14),
                  if (widget.controller.demoMode)
                    const _ReviewWarning()
                  else
                    _CertificateReadStatus(
                      reading: _reading,
                      extraction: _extraction,
                      error: _readError,
                      ocrEngine: _ocrEngine,
                      onRetry: _readAttachment,
                    ),
                  const SizedBox(height: 26),
                ],
                Text('参加情報', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  isPlanned
                      ? '開催情報と、もらえる予定ポイントを入力してください'
                      : isManual
                      ? '参加情報を入力してください'
                      : '読み取った内容が正しいか、参加証と照合してください',
                  style: TextStyle(color: _inkSoft),
                ),
                const SizedBox(height: 16),
                _CertificateIdField(
                  controller: _certificationIdController,
                  focusNode: _certificationIdFocusNode,
                  suggestions: _certificateIdSuggestionsFor(widget.controller),
                  confidence: widget.controller.demoMode
                      ? '94%'
                      : _confidenceLabel('certificationId'),
                  needsCheck: _needsCheck('certificationId'),
                  onSelected: _applyCertificateIdSuggestion,
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '研修会・イベント名',
                  controller: _eventController,
                  confidence: widget.controller.demoMode
                      ? '98%'
                      : _confidenceLabel('title'),
                  needsCheck: _needsCheck('title'),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '開催日',
                  controller: _dateController,
                  confidence: widget.controller.demoMode
                      ? '96%'
                      : _confidenceLabel('date'),
                  needsCheck: _needsCheck('date'),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '主催者',
                  controller: _organizerController,
                  confidence: widget.controller.demoMode
                      ? '82%'
                      : _confidenceLabel('organizer'),
                  needsCheck:
                      widget.controller.demoMode || _needsCheck('organizer'),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '取得単位（不明な場合は空欄）',
                  controller: _creditsController,
                  confidence: _confidenceLabel('credits'),
                  needsCheck: _needsCheck('credits'),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '単位区分（任意）',
                  controller: _categoryController,
                  confidence: _confidenceLabel('category'),
                  needsCheck: _needsCheck('category'),
                ),
                if (isPlanned) ...[
                  const SizedBox(height: 14),
                  _LabeledField(
                    label: '学会・イベントURL（任意）',
                    controller: _eventUrlController,
                    hintText: 'https://...',
                  ),
                ],
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'その他（任意）',
                  controller: _notesController,
                  maxLines: 3,
                  hintText: '会場、備考、会員マイページで使うメモなど',
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '反映する資格',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const _StatusChip(
                      label: '複数選択可',
                      foreground: _primary,
                      background: _primarySoft,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('資格ごとに区分と単位を確認します', style: TextStyle(color: _inkSoft)),
                const SizedBox(height: 14),
                ...widget.controller.snapshot.qualifications.map(
                  (qualification) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AllocationCard(
                      qualification: qualification.name,
                      category: _categoryController.text.trim().isEmpty
                          ? '未分類'
                          : _categoryController.text.trim(),
                      credits: _creditsController.text.trim().isEmpty
                          ? '単位未確認'
                          : '${_creditsController.text.trim()}単位',
                      selected: _selectedQualificationIds.contains(
                        qualification.id,
                      ),
                      reason: isPlanned
                          ? '参加後に参加証を登録すると確定ポイントへ移せます'
                          : 'この資格の現在ポイントへ反映します',
                      onChanged: (value) => setState(() {
                        if (value) {
                          _selectedQualificationIds.add(qualification.id);
                        } else {
                          _selectedQualificationIds.remove(qualification.id);
                        }
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPrototypeMessage(context, '資格・区分・単位を手動で追加できます'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('別の資格を追加'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _saving ? null : () => _save(draft: true),
                  child: const Text('下書き保存', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _selectedQualificationIds.isNotEmpty && !_saving
                      ? () => _save(draft: false)
                      : null,
                  child: Text(isPlanned ? '予定として登録' : '確定して登録'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['取り込み', '内容確認', '登録完了'];
    return Row(
      children: List.generate(labels.length, (index) {
        final step = index + 1;
        final active = step <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? _primary : _track,
                      shape: BoxShape.circle,
                    ),
                    child: step < currentStep
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '$step',
                            style: TextStyle(
                              color: active ? Colors.white : _inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? _ink : _inkSoft,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 23,
                    ),
                    color: step < currentStep ? _primary : _line,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _CertificatePreview extends StatelessWidget {
  const _CertificatePreview({
    required this.source,
    required this.hasReadResult,
    this.fileName,
  });

  final String source;
  final String? fileName;
  final bool hasReadResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 116,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _line),
              boxShadow: const [
                BoxShadow(
                  color: _cardShadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(height: 7),
                  Center(
                    child: Text(
                      '受講証明書',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  _DocumentLine(width: 80),
                  SizedBox(height: 7),
                  _DocumentLine(width: 92),
                  SizedBox(height: 7),
                  _DocumentLine(width: 68),
                  Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.verified_outlined,
                      color: _primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  source,
                  style: const TextStyle(color: _inkSoft, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName?.trim().isNotEmpty == true
                      ? fileName!
                      : '受講証明書_0818.jpg',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _primary,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasReadResult ? '読み取り完了' : 'ファイルを添付済み',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.zoom_in_outlined),
                  label: const Text('画像を拡大'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: _line,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _ReviewWarning extends StatelessWidget {
  const _ReviewWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warningSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '主催者名の読み取り精度が低いため、確認してください',
              style: TextStyle(color: _warningInk, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateReadStatus extends StatelessWidget {
  const _CertificateReadStatus({
    required this.reading,
    required this.onRetry,
    this.extraction,
    this.error,
    this.ocrEngine,
  });

  final bool reading;
  final CertificateExtraction? extraction;
  final String? error;
  final String? ocrEngine;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final result = extraction;
    final succeeded = result?.hasUsefulValues == true;
    final warnings = result?.warnings ?? const <String>[];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: succeeded
            ? _primarySoft
            : error != null
            ? _warningSoft
            : _neutralSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Icon(
              succeeded
                  ? Icons.auto_awesome_rounded
                  : Icons.warning_amber_rounded,
              color: succeeded ? _primary : _warning,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading
                      ? '端末内で文字を読み取り、項目を構造化しています…'
                      : succeeded
                      ? '自動入力しました。確定前にすべての項目を確認してください。'
                      : error ?? '自動読み取りを開始できます。',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!reading && succeeded) ...[
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (ocrEngine != null) 'OCR: $ocrEngine',
                      '抽出: ${result!.extractionMethod}',
                    ].join(' / '),
                    style: const TextStyle(color: _inkSoft, fontSize: 13),
                  ),
                ],
                if (!reading && warnings.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...warnings
                      .take(3)
                      .map(
                        (warning) => Text(
                          '・$warning',
                          style: const TextStyle(
                            color: _warningInk,
                            fontSize: 13,
                          ),
                        ),
                      ),
                ],
                if (!reading && !succeeded) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('再試行'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.confidence,
    this.needsCheck = false,
    this.maxLines = 1,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String? confidence;
  final bool needsCheck;
  final int maxLines;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (confidence != null)
              Text(
                '読取 $confidence',
                style: TextStyle(
                  color: needsCheck ? _warning : _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          key: ValueKey('certificate-field-$label'),
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: _ink, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: maxLines > 1
                ? null
                : const Icon(Icons.edit_outlined, size: 20),
            enabledBorder: needsCheck
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _warning, width: 1.5),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _CertificateIdSuggestion {
  const _CertificateIdSuggestion({
    required this.certificationId,
    required this.title,
    required this.date,
    required this.organizer,
    this.credits,
    this.category = '',
  });

  final String certificationId;
  final String title;
  final String date;
  final String organizer;
  final double? credits;
  final String category;
}

List<_CertificateIdSuggestion> _certificateIdSuggestionsFor(
  AppController controller,
) {
  final suggestions = <_CertificateIdSuggestion>[];
  final seen = <String>{};

  void add(_CertificateIdSuggestion item) {
    final id = item.certificationId.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(id) || !seen.add(id)) return;
    suggestions.add(item);
  }

  for (final activity in controller.snapshot.activities) {
    add(
      _CertificateIdSuggestion(
        certificationId: activity.certificationId,
        title: activity.title,
        date: activity.date,
        organizer: activity.organizer,
        credits: activity.credits > 0 ? activity.credits : null,
        category:
            activity.allocations
                .map((item) => item.category.trim())
                .where((item) => item.isNotEmpty && item != '未分類')
                .firstOrNull ??
            '',
      ),
    );
  }
  for (final entries in creditBreakdownByQualification.values) {
    for (final entry in entries) {
      add(
        _CertificateIdSuggestion(
          certificationId: entry.certificationId,
          title: entry.title,
          date: entry.date,
          organizer: entry.organizer,
          credits: entry.credits,
          category: entry.category,
        ),
      );
    }
  }
  return suggestions;
}

class _CertificateIdField extends StatelessWidget {
  const _CertificateIdField({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.onSelected,
    this.confidence,
    this.needsCheck = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<_CertificateIdSuggestion> suggestions;
  final ValueChanged<_CertificateIdSuggestion> onSelected;
  final String? confidence;
  final bool needsCheck;

  Iterable<_CertificateIdSuggestion> _optionsFor(String query) {
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final matches = digits.isEmpty
        ? suggestions
        : suggestions.where((item) => item.certificationId.startsWith(digits));
    return matches.take(8);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '認定ID（10桁）',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
            ),
            if (confidence != null)
              Text(
                '読取 $confidence',
                style: TextStyle(
                  color: needsCheck ? _warning : _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        RawAutocomplete<_CertificateIdSuggestion>(
          textEditingController: controller,
          focusNode: focusNode,
          displayStringForOption: (option) => option.certificationId,
          optionsBuilder: (textEditingValue) =>
              _optionsFor(textEditingValue.text),
          onSelected: onSelected,
          fieldViewBuilder:
              (context, textEditingController, fieldFocusNode, onSubmitted) {
                return TextField(
                  key: const ValueKey('certificate-field-認定ID（10桁）'),
                  controller: textEditingController,
                  focusNode: fieldFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '例：2608180042',
                    helperText: '参加証の10桁ID。入力やフォーカスで候補を表示します',
                    counterText: '',
                    suffixIcon: const Icon(Icons.badge_outlined, size: 20),
                    enabledBorder: needsCheck
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _warning,
                              width: 1.5,
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: (_) => onSubmitted(),
                );
              },
          optionsViewBuilder: (context, onSelectedOption, options) {
            final entries = options.toList(growable: false);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 280,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return InkWell(
                        onTap: () => onSelectedOption(entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.certificationId,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.title,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  entry.date,
                                  entry.organizer,
                                  if (entry.credits != null)
                                    '${_formatNumber(entry.credits!)}単位',
                                ].where((item) => item.isNotEmpty).join(' ・ '),
                                style: const TextStyle(
                                  color: _inkSoft,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.qualification,
    required this.category,
    required this.credits,
    required this.selected,
    required this.reason,
    required this.onChanged,
  });

  final String qualification;
  final String category;
  final String credits;
  final bool selected;
  final String reason;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? _primary : _line,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (value) => onChanged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.fromLTRB(10, 7, 14, 4),
            title: Text(
              qualification,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Wrap(
                spacing: 7,
                runSpacing: 6,
                children: [
                  _MiniPill(label: category),
                  _MiniPill(label: credits, emphasized: true),
                ],
              ),
            ),
          ),
          if (selected)
            ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: const Text(
                'この候補になった理由',
                style: TextStyle(
                  color: _primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    reason,
                    style: const TextStyle(
                      color: _inkSoft,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class RegistrationResultScreen extends StatelessWidget {
  const RegistrationResultScreen({
    super.key,
    required this.qualificationCount,
    this.showSampleProgress = false,
    this.isPlanned = false,
  });

  final int qualificationCount;
  final bool showSampleProgress;
  final bool isPlanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
              children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: _primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _primary,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPlanned ? '参加予定を登録しました' : '登録しました',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isPlanned
                      ? '$qualificationCount件の資格に予定ポイントを反映しました'
                      : '$qualificationCount件の資格に単位を反映しました',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _inkSoft, fontSize: 16),
                ),
                const SizedBox(height: 28),
                const _StepIndicator(currentStep: 3),
                const SizedBox(height: 28),
                if (showSampleProgress && !isPlanned)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '更新後の進捗',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (qualificationCount >= 1)
                            const _ResultProgressRow(
                              name: '内科専門医',
                              before: '42',
                              after: '44',
                              requiredValue: '50',
                            ),
                          if (qualificationCount >= 2) ...[
                            const Divider(height: 26),
                            const _ResultProgressRow(
                              name: '循環器専門医',
                              before: '28',
                              after: '29',
                              requiredValue: '40',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const _OfficialInfoNote(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('ホームに戻る'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      _showPrototypeMessage(context, '登録した実績の詳細を表示します'),
                  child: const Text('登録内容を見る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultProgressRow extends StatelessWidget {
  const _ResultProgressRow({
    required this.name,
    required this.before,
    required this.after,
    required this.requiredValue,
  });

  final String name;
  final String before;
  final String after;
  final String requiredValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        Text('$before → ', style: const TextStyle(color: _inkSoft)),
        Text(
          '$after / $requiredValue 単位',
          style: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

enum ActivityFilter { all, planned, needsReview, confirmed }

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  ActivityFilter _filter = ActivityFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sampleActivities = <_ActivityData>[
      const _ActivityData(
        id: 'sample-1',
        title: '第42回 地域医療研修会',
        date: '2026/08/18',
        organizer: '地域医療研修センター',
        status: '要確認',
        credits: '2資格へ候補',
        needsReview: true,
      ),
      const _ActivityData(
        id: 'sample-2',
        title: '医療安全講習会',
        date: '2026/07/12',
        organizer: '県医師会',
        status: '確定',
        credits: '1単位',
      ),
      const _ActivityData(
        id: 'sample-3',
        title: '循環器カンファレンス',
        date: '2026/06/28',
        organizer: '循環器学会',
        status: '確定',
        credits: '3単位',
      ),
      const _ActivityData(
        id: 'sample-4',
        title: '感染対策eラーニング',
        date: '2026/05/09',
        organizer: '研修センター',
        status: '下書き',
        credits: '単位未確認',
        needsReview: true,
      ),
      const _ActivityData(
        id: 'sample-5',
        title: '日本内科学会 総会・講演会',
        date: '2027/04/09',
        organizer: '日本内科学会',
        status: '参加予定',
        credits: '5単位',
        eventUrl: 'https://www.naika.or.jp/',
        qualificationNames: '内科専門医',
      ),
    ];
    final activities = widget.controller.demoMode
        ? sampleActivities
        : widget.controller.snapshot.activities
              .map(
                (item) => _ActivityData(
                  id: item.id,
                  title: item.title,
                  date: item.date.isEmpty ? '日付未入力' : item.date,
                  organizer: item.organizer.isEmpty ? '主催者未入力' : item.organizer,
                  status: item.status,
                  credits: item.credits > 0
                      ? '${_formatNumber(item.credits)}単位'
                      : '単位未確認',
                  needsReview: item.status == '下書き' || item.status == '要確認',
                  eventUrl: item.eventUrl,
                  certificationId: item.certificationId,
                  notes: item.notes,
                  qualificationNames:
                      item.allocations.isEmpty &&
                          widget.controller.snapshot.qualifications.length == 1
                      ? widget.controller.snapshot.qualifications.single.name
                      : item.allocations
                            .map(
                              (allocation) => widget
                                  .controller
                                  .snapshot
                                  .qualifications
                                  .where(
                                    (qualification) =>
                                        qualification.id ==
                                        allocation.qualificationId,
                                  )
                                  .firstOrNull
                                  ?.name,
                            )
                            .whereType<String>()
                            .toSet()
                            .join('、'),
                ),
              )
              .toList();
    final filtered = activities.where((item) {
      final matchesFilter = switch (_filter) {
        ActivityFilter.all => true,
        ActivityFilter.planned => item.status == '参加予定',
        ActivityFilter.needsReview => item.needsReview,
        ActivityFilter.confirmed => item.status == '確定',
      };
      if (!matchesFilter) return false;
      final query = _normalizeSearchText(_query);
      if (query.isEmpty) return true;
      return _normalizeSearchText(
        '${item.title} ${item.organizer} ${item.certificationId} ${item.notes}',
      ).contains(query);
    }).toList();
    if (_filter == ActivityFilter.planned) {
      filtered.sort((a, b) {
        final aDate = _parseFlexibleDate(a.date);
        final bDate = _parseFlexibleDate(b.date);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    }

    return ListView(
      key: const PageStorageKey('activities-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('実績', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text('登録した参加証と単位を確認できます', style: TextStyle(color: _inkSoft)),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: '研修会名・主催者で検索',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('すべて'),
                selected: _filter == ActivityFilter.all,
                onSelected: (_) => setState(() => _filter = ActivityFilter.all),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('参加予定'),
                selected: _filter == ActivityFilter.planned,
                onSelected: (_) =>
                    setState(() => _filter = ActivityFilter.planned),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('要確認・下書き'),
                selected: _filter == ActivityFilter.needsReview,
                onSelected: (_) =>
                    setState(() => _filter = ActivityFilter.needsReview),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('確定済み'),
                selected: _filter == ActivityFilter.confirmed,
                onSelected: (_) =>
                    setState(() => _filter = ActivityFilter.confirmed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              '${filtered.length}件',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            const Icon(Icons.sort_rounded, size: 19, color: _inkSoft),
            const SizedBox(width: 4),
            Text(
              _filter == ActivityFilter.planned ? '開催日順' : '新しい順',
              style: const TextStyle(color: _inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...filtered.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityCard(
              activity: activity,
              controller: widget.controller,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityData {
  const _ActivityData({
    required this.id,
    required this.title,
    required this.date,
    required this.organizer,
    required this.status,
    required this.credits,
    this.needsReview = false,
    this.eventUrl = '',
    this.certificationId = '',
    this.notes = '',
    this.qualificationNames = '',
  });

  final String id;
  final String title;
  final String date;
  final String organizer;
  final String status;
  final String credits;
  final bool needsReview;
  final String eventUrl;
  final String certificationId;
  final String notes;
  final String qualificationNames;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.controller});

  final _ActivityData activity;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = activity.status == '確定';
    final isPlanned = activity.status == '参加予定';
    final foreground = isConfirmed
        ? _primary
        : isPlanned
        ? _ink
        : _warning;
    final background = isConfirmed
        ? _primarySoft
        : isPlanned
        ? _neutralSoft
        : _warningSoft;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (activity.needsReview) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CertificateReviewScreen(
                  source: '保存済みの写真',
                  controller: controller,
                ),
              ),
            );
          } else {
            _showActivitySheet(context, activity, controller);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                icon: isConfirmed
                    ? Icons.description_outlined
                    : isPlanned
                    ? Icons.event_available_outlined
                    : Icons.pending_actions_outlined,
                color: foreground,
                background: background,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: activity.status,
                          foreground: foreground,
                          background: background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${activity.date} ・ ${activity.organizer}',
                      style: const TextStyle(color: _inkSoft, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.credits,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(Icons.chevron_right_rounded, color: _inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.authService,
    this.authUser,
  });

  final AppController controller;
  final AuthService? authService;
  final AuthUser? authUser;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _deadlineNotifications;
  late bool _missingNotifications;
  late bool _deviceLock;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.snapshot.settings;
    _deadlineNotifications = settings.deadlineNotifications;
    _missingNotifications = settings.missingNotifications;
    _deviceLock = settings.deviceLock;
  }

  void _saveSettings() {
    widget.controller.updateSettingsUnawaited(
      AppSettingsData(
        deadlineNotifications: _deadlineNotifications,
        missingNotifications: _missingNotifications,
        deviceLock: _deviceLock,
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runCloudAction(
    String action,
    Future<String> Function() operation,
  ) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      _showMessage(await operation());
    } on CloudApiException catch (error) {
      _showMessage(error.message);
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage('処理を完了できませんでした。通信環境を確認してもう一度お試しください。');
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _syncNow() => _runCloudAction('sync', () async {
    await widget.controller.syncNow();
    final error = widget.controller.syncError;
    if (error != null) throw CloudApiException('sync_failed', error);
    return 'クラウドと同期しました。';
  });

  Future<void> _createBackup() => _runCloudAction('backup', () async {
    final backup = await widget.controller.createCloudBackup();
    return '${_formatDateTime(backup.createdAt)} のバックアップを作成しました。';
  });

  Future<void> _restoreBackup() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最新のバックアップを復元しますか？'),
        content: const Text('現在の資格・実績は、バックアップ作成時点の内容に置き換わります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('復元する'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await _runCloudAction('restore', () async {
      final backup = await widget.controller.restoreLatestCloudBackup();
      return '${_formatDateTime(backup.createdAt)} のバックアップを復元しました。';
    });
  }

  Future<void> _enableWebPush() => _runCloudAction('push', () async {
    await widget.controller.enableWebPush();
    return 'この端末で更新期限のWeb通知を受け取れます。';
  });

  Future<void> _deleteAccount() async {
    final authService = widget.authService;
    if (authService == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウントとデータを削除しますか？'),
        content: const Text('資格・実績・参加証・バックアップをクラウドから完全に削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('完全に削除'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await _runCloudAction('delete', () async {
      await widget.controller.deleteAccountAndData(authService);
      return 'アカウントと保存データを削除しました。';
    });
  }

  String get _syncSubtitle {
    if (widget.controller.isSyncing) return '同期しています…';
    final error = widget.controller.syncError;
    if (error != null) return '未同期：$error';
    final lastSynced = widget.controller.lastSyncedAt;
    if (lastSynced != null) return '最終同期：${_formatDateTime(lastSynced)}';
    return widget.controller.cloudConnected ? '同期の準備ができています' : 'クラウド未接続';
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text('クラウド上の資格・実績データは削除されません。次回ログイン時に再同期できます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;
    try {
      await widget.authService?.signOut();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログアウトできませんでした。もう一度お試しください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text('設定', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text('通知・資格情報・バックアップを管理します', style: TextStyle(color: _inkSoft)),
        const SizedBox(height: 22),
        if (widget.authUser != null) ...[
          const _SettingsHeading('アカウント'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: _AccountAvatar(user: widget.authUser!),
                  title: Text(
                    widget.authUser!.displayName?.trim().isNotEmpty == true
                        ? widget.authUser!.displayName!
                        : 'ログイン中',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: widget.authUser!.email == null
                      ? null
                      : Text(widget.authUser!.email!),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  key: const ValueKey('cloud-sync'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    widget.controller.syncError == null
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: widget.controller.syncError == null
                        ? _primary
                        : _warning,
                  ),
                  title: const Text(
                    'クラウド同期',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_syncSubtitle),
                  trailing: _busyAction == 'sync'
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  onTap: _busyAction == null ? _syncNow : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  key: const ValueKey('sign-out'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(Icons.logout_rounded, color: _danger),
                  title: const Text(
                    'ログアウト',
                    style: TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
        ],
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const _IconTile(
              icon: Icons.person_outline_rounded,
              color: _primary,
              background: _primarySoft,
            ),
            title: const Text(
              '本人専用プロフィール',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.controller.cloudConnected
                    ? '${widget.controller.snapshot.qualifications.length}件の資格を暗号化通信で同期'
                    : '${widget.controller.snapshot.qualifications.length}件の資格をこの端末に保存',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () =>
                _showPrototypeMessage(context, '資格の追加・並べ替え・アーカイブを行います'),
          ),
        ),
        const SizedBox(height: 26),
        const _SettingsHeading('通知'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _deadlineNotifications,
                onChanged: (value) {
                  setState(() => _deadlineNotifications = value);
                  _saveSettings();
                },
                title: const Text(
                  '更新期限のお知らせ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('180・90・30・7日前'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: _missingNotifications,
                onChanged: (value) {
                  setState(() => _missingNotifications = value);
                  _saveSettings();
                },
                title: const Text(
                  '不足・要確認のお知らせ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('確認待ちが続いたときに通知'),
              ),
              if (widget.controller.webPushSupported) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: _primary,
                  ),
                  title: const Text(
                    'この端末でWeb通知を有効化',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('ブラウザの許可画面が表示されます'),
                  trailing: _busyAction == 'push'
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _busyAction == null ? _enableWebPush : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SettingsHeading('データ管理'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'バックアップを作成',
                subtitle: '現在の資格・実績・設定をクラウドに保管',
                onTap: _createBackup,
              ),
              const Divider(height: 1, indent: 72),
              _SettingsTile(
                icon: Icons.restore_rounded,
                title: 'バックアップから復元',
                subtitle: '最新のバックアップを使用',
                onTap: _restoreBackup,
              ),
              const Divider(height: 1, indent: 72),
              _SettingsTile(
                icon: Icons.table_view_outlined,
                title: 'CSVを書き出す',
                onTap: () =>
                    _showPrototypeMessage(context, '資格・条件・実績・割当をCSVにします'),
              ),
              if (widget.authService != null &&
                  widget.controller.cloudConnected) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  key: const ValueKey('delete-account'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: _danger,
                  ),
                  title: const Text(
                    'アカウントと全データを削除',
                    style: TextStyle(
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('参加証とバックアップも完全に削除'),
                  trailing: _busyAction == 'delete'
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _busyAction == null ? _deleteAccount : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SettingsHeading('プライバシー'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _deviceLock,
                onChanged: (value) {
                  setState(() => _deviceLock = value);
                  _saveSettings();
                },
                title: const Text(
                  '端末認証でロック',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('アプリを開くときに本人確認'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '画像の外部送信について',
                subtitle: '送信先と利用目的を確認',
                onTap: () =>
                    _showPrototypeMessage(context, 'OCR利用時の同意内容を表示します'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Center(
          child: Text(
            '資格更新ノート  PWA v1.0',
            style: TextStyle(color: _inkSoft, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.trim();
    final email = user.email?.trim();
    final initialSource = displayName?.isNotEmpty == true
        ? displayName!
        : email;
    final initial = initialSource?.isNotEmpty == true
        ? initialSource!.substring(0, 1).toUpperCase()
        : 'U';
    return CircleAvatar(
      radius: 23,
      backgroundColor: _primarySoft,
      foregroundColor: _primary,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: _primary, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded, color: _inkSoft),
      onTap: onTap,
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: foreground.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? _primarySoft : _neutralSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? _primaryDark : _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.foreground, this.background);

  final String label;
  final Color foreground;
  final Color background;
}

_StatusStyle _statusStyle(QualificationState state) {
  // 状態ごとに色相を変えて、文字を読まなくても一目で区別できるようにする。
  return switch (state) {
    QualificationState.needsAttention => const _StatusStyle(
      '要確認',
      _warning,
      _warningSoft,
    ),
    QualificationState.onTrack => const _StatusStyle(
      '順調',
      _success,
      _successSoft,
    ),
    QualificationState.almostDue => const _StatusStyle(
      '期限注意',
      _danger,
      _dangerSoft,
    ),
  };
}

String _formatNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

void _showPrototypeMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _showEvidenceSheet(BuildContext context, Qualification qualification) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('規定・根拠資料', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const _IconTile(
              icon: Icons.picture_as_pdf_outlined,
              color: _danger,
              background: _dangerSoft,
            ),
            title: Text(
              qualification.sourceTitle ?? '認定団体の公式資料',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              qualification.sourceCheckedAt == null
                  ? '確認日：未取得'
                  : '確認日：${_formatJapaneseDate(qualification.sourceCheckedAt!)}',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '管理画面で内容を確認・承認した条件だけを表示しています。更新申請前には必ず最新の公式資料もご確認ください。',
            style: TextStyle(color: _inkSoft, height: 1.5),
          ),
          if (qualification.sourceUrl != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => unawaited(
                  _openOfficialSource(context, qualification.sourceUrl!),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('公式資料を開く'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<void> _openOfficialSource(BuildContext context, String sourceUrl) async {
  final opened = await launchUrl(
    Uri.parse(sourceUrl),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    _showPrototypeMessage(context, '公式資料を開けませんでした');
  }
}

void _showActivitySheet(
  BuildContext context,
  _ActivityData activity,
  AppController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            '${activity.date} ・ ${activity.organizer}',
            style: const TextStyle(color: _inkSoft),
          ),
          const SizedBox(height: 8),
          Text(
            '${activity.status} ・ ${activity.credits}',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (activity.certificationId.isNotEmpty)
            _SettingsTile(
              icon: Icons.badge_outlined,
              title: '認定ID（10桁）',
              subtitle: activity.certificationId,
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: activity.certificationId),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('認定IDをコピーしました')));
              },
            ),
          if (activity.notes.isNotEmpty)
            _SettingsTile(
              icon: Icons.notes_outlined,
              title: 'その他',
              subtitle: activity.notes,
              onTap: _noop,
            ),
          if (activity.eventUrl.isNotEmpty)
            _SettingsTile(
              icon: Icons.open_in_new_rounded,
              title: '学会・イベントサイトを開く',
              subtitle: activity.eventUrl,
              onTap: () =>
                  unawaited(_openActivityEvent(context, activity.eventUrl)),
            ),
          if (activity.status != '参加予定')
            const _SettingsTile(
              icon: Icons.image_outlined,
              title: '証明書画像を見る',
              onTap: _noop,
            ),
          _SettingsTile(
            icon: Icons.account_tree_outlined,
            title: '資格への割当を見る',
            subtitle: activity.qualificationNames.isEmpty
                ? '割当なし'
                : activity.qualificationNames,
            onTap: _noop,
          ),
          const _SettingsTile(
            icon: Icons.history_rounded,
            title: '変更履歴を見る',
            onTap: _noop,
          ),
          if (activity.status == '参加予定') ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => unawaited(
                _confirmPlannedActivity(context, activity.id, controller),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('参加済みにしてポイントを確定'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<void> _confirmPlannedActivity(
  BuildContext context,
  String activityId,
  AppController controller,
) async {
  final activity = controller.snapshot.activities
      .where((item) => item.id == activityId)
      .firstOrNull;
  if (activity == null) return;
  await controller.updateActivity(activity.copyWith(status: '確定'));
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  Navigator.pop(context);
  messenger.showSnackBar(const SnackBar(content: Text('予定ポイントを現在ポイントへ移しました')));
}

Future<void> _openActivityEvent(BuildContext context, String value) async {
  final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
  final opened =
      uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('学会・イベントサイトを開けませんでした')));
  }
}

void _showCreditBreakdownDetail(
  BuildContext context,
  Qualification qualification,
  CreditBreakdownEntry entry,
) {
  final isConference = entry.eventType == '学会';
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(
                  label: entry.eventType,
                  foreground: isConference ? _ink : _primary,
                  background: isConference ? _neutralSoft : _primarySoft,
                ),
                const Spacer(),
                Text(
                  '${_formatNumber(entry.credits)}単位',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(entry.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(
              '${entry.date} ・ ${entry.organizer}',
              style: const TextStyle(color: _inkSoft),
            ),
            const SizedBox(height: 22),
            if (entry.certificationId.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, color: _onInkMuted),
                        SizedBox(width: 8),
                        Text(
                          '認定ID（10桁）',
                          style: TextStyle(
                            color: _onInkMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      entry.certificationId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      '参加証・会員マイページとの照合に使用します',
                      style: TextStyle(color: _onInkSoft, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            Card(
              child: Column(
                children: [
                  _BreakdownDetailRow(label: '単位区分', value: entry.category),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const _BreakdownDetailRow(label: '証明書', value: '登録済み'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _BreakdownDetailRow(label: '反映先', value: qualification.name),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('確認しました'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BreakdownDetailRow extends StatelessWidget {
  const _BreakdownDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: _inkSoft, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
