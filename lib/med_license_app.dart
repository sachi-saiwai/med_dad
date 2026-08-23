import 'package:flutter/material.dart';

const _ink = Color(0xFF18324A);
const _primary = Color(0xFF2D6A63);
const _canvas = Color(0xFFF4F6F2);
const _line = Color(0xFFDCE3DE);
const _warning = Color(0xFFE88C32);
const _danger = Color(0xFFB85042);

class MedLicenseApp extends StatelessWidget {
  const MedLicenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      surface: Colors.white,
      error: _danger,
    );

    return MaterialApp(
      title: '資格更新ノート',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _canvas,
        fontFamilyFallback: const ['Hiragino Sans', 'Noto Sans JP'],
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            color: _ink,
            fontSize: 17,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: _ink, fontSize: 16, height: 1.55),
          bodyMedium: TextStyle(color: _ink, fontSize: 14, height: 1.5),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: _line),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: _line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
        ),
      ),
      home: const InitialSetupScreen(),
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
    required this.name,
    required this.organization,
    required this.deadline,
    required this.remainingDays,
    required this.state,
    required this.total,
    required this.requiredTotal,
    required this.headline,
    required this.requirements,
  });

  final String name;
  final String organization;
  final String deadline;
  final int remainingDays;
  final QualificationState state;
  final double total;
  final double requiredTotal;
  final String headline;
  final List<RequirementProgress> requirements;

  double get progress => (total / requiredTotal).clamp(0, 1);
}

class QualificationCatalogEntry {
  const QualificationCatalogEntry({
    required this.name,
    required this.organization,
    required this.category,
    this.keywords = const [],
  });

  final String name;
  final String organization;
  final String category;
  final List<String> keywords;

  bool matches(String query) {
    final searchableText = [
      name,
      organization,
      category,
      ...keywords,
    ].join(' ').toLowerCase();
    return searchableText.contains(query.toLowerCase());
  }
}

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
    keywords: ['小児科', 'しょうにか'],
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
    keywords: ['リハビリ', 'リハビリ科'],
  ),
  QualificationCatalogEntry(
    name: '総合診療専門医',
    organization: '日本専門医機構',
    category: '基本領域',
  ),
  QualificationCatalogEntry(
    name: '消化器外科専門医',
    organization: '日本専門医機構／日本消化器外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '消化器', '胃腸', '腹部'],
  ),
  QualificationCatalogEntry(
    name: '呼吸器外科専門医',
    organization: '日本専門医機構／呼吸器外科専門医合同委員会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '呼吸器', '胸部', '肺'],
  ),
  QualificationCatalogEntry(
    name: '心臓血管外科専門医',
    organization: '日本専門医機構／心臓血管外科専門医認定機構',
    category: 'サブスペシャルティ',
    keywords: ['外科', '心臓', '血管', '循環器'],
  ),
  QualificationCatalogEntry(
    name: '小児外科専門医',
    organization: '日本専門医機構／日本小児外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '小児', 'こども'],
  ),
  QualificationCatalogEntry(
    name: '乳腺外科専門医',
    organization: '日本専門医機構／日本乳癌学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '乳腺', '乳がん', '乳癌'],
  ),
  QualificationCatalogEntry(
    name: '内分泌外科専門医',
    organization: '日本専門医機構／日本内分泌外科学会',
    category: 'サブスペシャルティ',
    keywords: ['外科', '内分泌', '甲状腺', '副甲状腺', '副腎'],
  ),
  QualificationCatalogEntry(
    name: '乳腺専門医',
    organization: '日本乳癌学会',
    category: '学会認定（旧制度）',
    keywords: ['外科', '乳腺', '乳がん', '乳癌'],
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
  ),
];

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
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int _currentStep = 0;
  int _nextQualificationId = 2;
  bool _notificationsEnabled = true;
  final List<_QualificationDraft> _qualifications = [
    const _QualificationDraft(
      id: 1,
      name: '超音波専門医',
      organization: '日本超音波医学会',
      licenseNumber: '1234567890',
      deadline: '2026/12/31',
    ),
  ];

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      return;
    }
    _goToApp();
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
      1 => const _ProfileSetupPage(),
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
                      onPressed: _goToApp,
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
  const _QualificationDraft({
    required this.id,
    required this.name,
    required this.organization,
    required this.licenseNumber,
    required this.deadline,
  });

  final int id;
  final String name;
  final String organization;
  final String licenseNumber;
  final String deadline;
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
            fontWeight: FontWeight.w800,
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
                        color: active ? _primary : const Color(0xFFE1E6E2),
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
                                color: active ? Colors.white : Colors.blueGrey,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: active ? _ink : Colors.blueGrey,
                        fontSize: 12,
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
                  color: step < currentStep
                      ? _primary
                      : const Color(0xFFD8DFDA),
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
              color: Color(0xFFE1F2ED),
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
          style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.55),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          _IconTile(
            icon: icon,
            color: _primary,
            background: const Color(0xFFE5F2EF),
          ),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
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
        color: const Color(0xFFFFF2E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _warning, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '患者情報は登録しません。表示結果は自己管理用のため、最終確認は資格団体の公式情報で行ってください。',
              style: TextStyle(
                color: Color(0xFF77572E),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupPage extends StatelessWidget {
  const _ProfileSetupPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('本人情報を登録', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'アプリ内での表示に使用します。後から設定画面で変更できます。',
          style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'お名前・呼び名',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        const TextField(
          decoration: InputDecoration(
            hintText: '例：お父さん',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '利用する端末',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        const TextField(
          decoration: InputDecoration(
            hintText: '例：iPhone',
            prefixIcon: Icon(Icons.smartphone_outlined),
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
                  background: Color(0xFFE5F2EF),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'このMVPでは複数利用者や病院管理者の設定はありません。',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
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
          '資格名・資格番号・次回更新期限を、公式資料または会員マイページで確認して入力します。',
          style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.5),
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
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('既定：365・180・90・30・7日前'),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF0F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _ink, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '総単位・区分別単位・必須講習などの詳しい条件は、登録後に資格詳細から追加できます。',
                  style: TextStyle(color: _ink, fontSize: 13, height: 1.5),
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
  QualificationCatalogEntry? _selectedEntry;

  @override
  void initState() {
    super.initState();
    _organizationController = TextEditingController(
      text: widget.draft.organization,
    );
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
    if (query.isEmpty) return qualificationCatalog.take(8);
    return qualificationCatalog.where((entry) => entry.matches(query)).take(20);
  }

  void _selectQualification(QualificationCatalogEntry entry) {
    _organizationController.text = entry.organization;
    setState(() => _selectedEntry = entry);
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
                      fontWeight: FontWeight.w800,
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
            Autocomplete<QualificationCatalogEntry>(
              initialValue: TextEditingValue(text: widget.draft.name),
              displayStringForOption: (entry) => entry.name,
              optionsBuilder: _findOptions,
              onSelected: _selectQualification,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      key: ValueKey('qualification-name-${widget.draft.id}'),
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (value) {
                        if (_selectedEntry?.name != value) {
                          setState(() => _selectedEntry = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: '資格名（候補から選択）',
                        hintText: '例：内科、循環器、超音波',
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
                    borderRadius: BorderRadius.circular(16),
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
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5F2EF),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          entry.category,
                                          style: const TextStyle(
                                            color: _primary,
                                            fontSize: 11,
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
                                      color: Colors.blueGrey,
                                      fontSize: 12,
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
                          color: Colors.blueGrey,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '候補を選ぶと認定団体を自動入力します',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
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
                          '認定団体を自動入力しました',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 12,
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
              decoration: const InputDecoration(
                labelText: '認定団体',
                helperText: '必要に応じて修正できます',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.licenseNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '資格番号（任意）',
                hintText: '会員証・認定証を確認',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.draft.deadline,
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
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  Future<void> _openRegistration() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RegistrationChoiceSheet(),
    );
    if (!mounted || source == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CertificateReviewScreen(source: source),
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
      2 => const ActivityListScreen(),
      3 => const SettingsScreen(),
      _ => HomeScreen(onRegister: _openRegistration),
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
        height: 72,
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
  const HomeScreen({super.key, required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList.list(
            children: [
              const _TopBar(),
              const SizedBox(height: 26),
              Text(
                '資格更新の状況',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '2026年8月22日 現在',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _AttentionBanner(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const CertificateReviewScreen(source: '保存済みの写真'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _NextDeadlineCard(
                onTap: () =>
                    _openQualification(context, sampleQualifications.first),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('参加証を登録する'),
              ),
              const SizedBox(height: 30),
              _SectionHeading(title: '保有資格', trailing: '期限が近い順', onTap: () {}),
              const SizedBox(height: 12),
              ...sampleQualifications.map(
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
        builder: (_) => QualificationDetailScreen(qualification: qualification),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.workspace_premium_outlined,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '資格更新ノート',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '本人専用',
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1EF),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'サンプルデータ',
            style: TextStyle(
              color: _primary,
              fontSize: 12,
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
      color: const Color(0xFFFFF2E1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _IconTile(
                icon: Icons.priority_high_rounded,
                color: _warning,
                background: Color(0xFFFFE2BD),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '読み取り内容を確認してください',
                      style: TextStyle(color: Color(0xFF77572E), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF77572E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextDeadlineCard extends StatelessWidget {
  const _NextDeadlineCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
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
                        color: Color(0xFFBFD0DC),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'あと131日',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              const Text(
                '超音波専門医',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '2026年12月31日',
                style: TextStyle(color: Color(0xFFD8E2E9), fontSize: 15),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFC36E),
                    size: 21,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '必須講習が1回不足しています',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
        borderRadius: BorderRadius.circular(20),
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
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    label: style.label,
                    foreground: style.foreground,
                    background: style.background,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${qualification.total.toInt()} / ${qualification.requiredTotal.toInt()} 単位',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(qualification.progress * 100).round()}%',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: qualification.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE7ECE9),
                  color: style.foreground,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    qualification.state == QualificationState.onTrack
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    color: style.foreground,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qualification.headline,
                      style: TextStyle(
                        color: style.foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.blueGrey,
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

class _OfficialInfoNote extends StatelessWidget {
  const _OfficialInfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: _ink, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'このアプリは自己管理を支援するものです。更新申請前に、必ず資格団体の公式情報をご確認ください。',
              style: TextStyle(color: _ink, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class QualificationDetailScreen extends StatelessWidget {
  const QualificationDetailScreen({super.key, required this.qualification});

  final Qualification qualification;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(qualification.state);
    final creditEntries =
        creditBreakdownByQualification[qualification.name] ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('資格の詳細'),
        backgroundColor: _canvas,
        actions: [
          IconButton(
            tooltip: '編集',
            onPressed: () =>
                _showPrototypeMessage(context, '資格・条件の編集画面は次の検討対象です'),
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
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 20),
                Card(
                  color: _ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
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
                                  value: qualification.progress,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .14,
                                  ),
                                  color: const Color(0xFF69C0B4),
                                ),
                              ),
                              Text(
                                '${(qualification.progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
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
                                  color: Color(0xFFBFD0DC),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${qualification.total.toInt()} / ${qualification.requiredTotal.toInt()} 単位',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                qualification.headline,
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
                const SizedBox(height: 28),
                const _SectionHeading(title: '更新条件'),
                const SizedBox(height: 12),
                ...qualification.requirements.map(
                  (requirement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RequirementCard(requirement: requirement),
                  ),
                ),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '講習・学会ごとの取得単位を確認できます',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 12),
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
                          background: Color(0xFFE5F2EF),
                        ),
                        title: const Text(
                          '登録済みの実績',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('12件（証明書あり 10件）'),
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
                          background: Color(0xFFEAF0F4),
                        ),
                        title: const Text(
                          '規定・根拠資料',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('公式資料を2026年8月20日に確認'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showEvidenceSheet(context),
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const _IconTile(
            icon: Icons.event_outlined,
            color: _primary,
            background: Color(0xFFE5F2EF),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '次回の更新期限',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  qualification.deadline,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'あと${qualification.remainingDays}日',
            style: const TextStyle(color: _danger, fontWeight: FontWeight.w800),
          ),
        ],
      ),
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
                      fontWeight: FontWeight.w800,
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE7ECE9),
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
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
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
            background: const Color(0xFFEAF0F4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BreakdownTotalTile(
            icon: Icons.school_outlined,
            label: '講習',
            value: '${_formatNumber(lectureCredits)}単位',
            color: _primary,
            background: const Color(0xFFE5F2EF),
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
        borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
    final background = isConference
        ? const Color(0xFFEAF0F4)
        : const Color(0xFFE5F2EF);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_formatNumber(entry.credits)}単位',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.date} ・ ${entry.organizer}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
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
                    const Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: Colors.blueGrey,
                          size: 17,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'タップして10桁IDを確認',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
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
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blueGrey,
                ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: const Color(0xFFCAD4CE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('参加証を登録', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '登録方法を選んでください',
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 15),
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
              const SizedBox(height: 16),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 19, color: _primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '患者情報が写った画像は登録しないでください。読み取り内容は確定前に必ず確認します。',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconTile(
                icon: icon,
                color: _primary,
                background: const Color(0xFFE5F2EF),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CertificateReviewScreen extends StatefulWidget {
  const CertificateReviewScreen({super.key, required this.source});

  final String source;

  @override
  State<CertificateReviewScreen> createState() =>
      _CertificateReviewScreenState();
}

class _CertificateReviewScreenState extends State<CertificateReviewScreen> {
  late final TextEditingController _eventController;
  late final TextEditingController _dateController;
  late final TextEditingController _organizerController;
  bool _internalMedicine = true;
  bool _cardiology = true;

  @override
  void initState() {
    super.initState();
    _eventController = TextEditingController(text: '第42回 地域医療研修会');
    _dateController = TextEditingController(text: '2026/08/18');
    _organizerController = TextEditingController(text: '地域医療研修センター');
  }

  @override
  void dispose() {
    _eventController.dispose();
    _dateController.dispose();
    _organizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isManual = widget.source == '手入力';
    return Scaffold(
      appBar: AppBar(
        title: Text(isManual ? '実績を手入力' : '読み取り内容の確認'),
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
                if (!isManual) ...[
                  _CertificatePreview(source: widget.source),
                  const SizedBox(height: 14),
                  const _ReviewWarning(),
                  const SizedBox(height: 26),
                ],
                Text('参加情報', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '読み取った内容が正しいか確認してください',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: '研修会・イベント名',
                  controller: _eventController,
                  confidence: isManual ? null : '98%',
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '開催日',
                  controller: _dateController,
                  confidence: isManual ? null : '96%',
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: '主催者',
                  controller: _organizerController,
                  confidence: isManual ? null : '82%',
                  needsCheck: !isManual,
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
                      background: Color(0xFFE5F2EF),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '資格ごとに区分と単位を確認します',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 14),
                _AllocationCard(
                  qualification: '内科専門医',
                  category: '共通講習',
                  credits: '2単位',
                  selected: _internalMedicine,
                  reason: '主催団体と「共通講習」の語句が登録ルールに一致',
                  onChanged: (value) =>
                      setState(() => _internalMedicine = value),
                ),
                const SizedBox(height: 10),
                _AllocationCard(
                  qualification: '循環器専門医',
                  category: '専門単位',
                  credits: '1単位',
                  selected: _cardiology,
                  reason: '認定番号「CM-2026-0818」が登録ルールに一致',
                  onChanged: (value) => setState(() => _cardiology = value),
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
                  onPressed: () => _showPrototypeMessage(
                    context,
                    '下書きとして保存しました（進捗には反映されません）',
                  ),
                  child: const Text('下書き保存', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _internalMedicine || _cardiology
                      ? () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => RegistrationResultScreen(
                              qualificationCount: [
                                _internalMedicine,
                                _cardiology,
                              ].where((value) => value).length,
                            ),
                          ),
                        )
                      : null,
                  child: const Text('確定して登録'),
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
                      color: active ? _primary : const Color(0xFFE1E6E2),
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
                              color: active ? Colors.white : Colors.blueGrey,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? _ink : Colors.blueGrey,
                      fontSize: 12,
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
                    color: step < currentStep
                        ? _primary
                        : const Color(0xFFD8DFDA),
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
  const _CertificatePreview({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7ECE9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 116,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCAD3CE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  '受講証明書_0818.jpg',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: _primary, size: 19),
                    SizedBox(width: 6),
                    Text(
                      '読み取り完了',
                      style: TextStyle(
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
        color: const Color(0xFFD9E1DC),
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
        color: const Color(0xFFFFF2E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '主催者名の読み取り精度が低いため、確認してください',
              style: TextStyle(
                color: Color(0xFF77572E),
                fontWeight: FontWeight.w700,
              ),
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
  });

  final String label;
  final TextEditingController controller;
  final String? confidence;
  final bool needsCheck;

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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (confidence != null)
              Text(
                '読取 $confidence',
                style: TextStyle(
                  color: needsCheck ? _warning : _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          style: const TextStyle(color: _ink, fontSize: 16),
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.edit_outlined, size: 20),
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
        borderRadius: BorderRadius.circular(18),
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
                fontWeight: FontWeight.w800,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
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
  const RegistrationResultScreen({super.key, required this.qualificationCount});

  final int qualificationCount;

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
                      color: Color(0xFFE1F2ED),
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
                  '登録しました',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$qualificationCount件の資格に単位を反映しました',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                const _StepIndicator(currentStep: 3),
                const SizedBox(height: 28),
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
                            fontWeight: FontWeight.w800,
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
        Text('$before → ', style: const TextStyle(color: Colors.blueGrey)),
        Text(
          '$after / $requiredValue 単位',
          style: const TextStyle(color: _primary, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

enum ActivityFilter { all, needsReview, confirmed }

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final activities = <_ActivityData>[
      const _ActivityData(
        title: '第42回 地域医療研修会',
        date: '2026/08/18',
        organizer: '地域医療研修センター',
        status: '要確認',
        credits: '2資格へ候補',
        needsReview: true,
      ),
      const _ActivityData(
        title: '医療安全講習会',
        date: '2026/07/12',
        organizer: '県医師会',
        status: '確定',
        credits: '1単位',
      ),
      const _ActivityData(
        title: '循環器カンファレンス',
        date: '2026/06/28',
        organizer: '循環器学会',
        status: '確定',
        credits: '3単位',
      ),
      const _ActivityData(
        title: '感染対策eラーニング',
        date: '2026/05/09',
        organizer: '研修センター',
        status: '下書き',
        credits: '単位未確認',
        needsReview: true,
      ),
    ];
    final filtered = activities.where((item) {
      return switch (_filter) {
        ActivityFilter.all => true,
        ActivityFilter.needsReview => item.needsReview,
        ActivityFilter.confirmed => item.status == '確定',
      };
    }).toList();

    return ListView(
      key: const PageStorageKey('activities-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('実績', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(
          '登録した参加証と単位を確認できます',
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
        const SizedBox(height: 20),
        const TextField(
          decoration: InputDecoration(
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
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            const Icon(Icons.sort_rounded, size: 19, color: Colors.blueGrey),
            const SizedBox(width: 4),
            const Text('新しい順', style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 10),
        ...filtered.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ActivityCard(activity: activity),
          ),
        ),
      ],
    );
  }
}

class _ActivityData {
  const _ActivityData({
    required this.title,
    required this.date,
    required this.organizer,
    required this.status,
    required this.credits,
    this.needsReview = false,
  });

  final String title;
  final String date;
  final String organizer;
  final String status;
  final String credits;
  final bool needsReview;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final _ActivityData activity;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = activity.status == '確定';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (activity.needsReview) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const CertificateReviewScreen(source: '保存済みの写真'),
              ),
            );
          } else {
            _showActivitySheet(context, activity);
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
                    : Icons.pending_actions_outlined,
                color: isConfirmed ? _primary : _warning,
                background: isConfirmed
                    ? const Color(0xFFE5F2EF)
                    : const Color(0xFFFFF0DC),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: activity.status,
                          foreground: isConfirmed ? _primary : _warning,
                          background: isConfirmed
                              ? const Color(0xFFE5F2EF)
                              : const Color(0xFFFFF0DC),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${activity.date} ・ ${activity.organizer}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.credits,
                      style: TextStyle(
                        color: isConfirmed ? _primary : _warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deadlineNotifications = true;
  bool _missingNotifications = true;
  bool _deviceLock = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text('設定', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Text(
          '通知・資格情報・バックアップを管理します',
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const _IconTile(
              icon: Icons.person_outline_rounded,
              color: _primary,
              background: Color(0xFFE5F2EF),
            ),
            title: const Text(
              '本人専用プロフィール',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('資格3件・次回更新まで131日'),
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
                onChanged: (value) =>
                    setState(() => _deadlineNotifications = value),
                title: const Text(
                  '更新期限のお知らせ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('180・90・30・7日前'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: _missingNotifications,
                onChanged: (value) =>
                    setState(() => _missingNotifications = value),
                title: const Text(
                  '不足・要確認のお知らせ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('確認待ちが続いたときに通知'),
              ),
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
                subtitle: '前回：2026年8月20日',
                onTap: () =>
                    _showPrototypeMessage(context, 'バックアップ作成前の確認画面を表示します'),
              ),
              const Divider(height: 1, indent: 72),
              _SettingsTile(
                icon: Icons.restore_rounded,
                title: 'バックアップから復元',
                onTap: () =>
                    _showPrototypeMessage(context, '現在のデータを退避してから復元します'),
              ),
              const Divider(height: 1, indent: 72),
              _SettingsTile(
                icon: Icons.table_view_outlined,
                title: 'CSVを書き出す',
                onTap: () =>
                    _showPrototypeMessage(context, '資格・条件・実績・割当をCSVにします'),
              ),
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
                onChanged: (value) => setState(() => _deviceLock = value),
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
            '資格更新ノート  UIプロトタイプ v0.1',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
        fontWeight: FontWeight.w800,
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: _primary),
      title: Text(
        title,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFE5F2EF) : const Color(0xFFF0F3F1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? _primary : _ink,
          fontSize: 12,
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
  return switch (state) {
    QualificationState.needsAttention => const _StatusStyle(
      '要確認',
      _warning,
      Color(0xFFFFF0DC),
    ),
    QualificationState.onTrack => const _StatusStyle(
      '順調',
      _primary,
      Color(0xFFE5F2EF),
    ),
    QualificationState.almostDue => const _StatusStyle(
      '期限注意',
      _danger,
      Color(0xFFF8E8E5),
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

void _showEvidenceSheet(BuildContext context) {
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
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _IconTile(
              icon: Icons.picture_as_pdf_outlined,
              color: _danger,
              background: Color(0xFFF8E8E5),
            ),
            title: Text(
              '専門医更新規定 2026年度版',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('確認日：2026年8月20日'),
          ),
          const SizedBox(height: 8),
          const Text(
            '条件はAIの推測ではなく、登録した公式資料に基づいています。',
            style: TextStyle(color: Colors.blueGrey, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

void _showActivitySheet(BuildContext context, _ActivityData activity) {
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
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 18),
          const _SettingsTile(
            icon: Icons.image_outlined,
            title: '証明書画像を見る',
            onTap: _noop,
          ),
          const _SettingsTile(
            icon: Icons.account_tree_outlined,
            title: '資格への割当を見る',
            onTap: _noop,
          ),
          const _SettingsTile(
            icon: Icons.history_rounded,
            title: '変更履歴を見る',
            onTap: _noop,
          ),
        ],
      ),
    ),
  );
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
                  background: isConference
                      ? const Color(0xFFEAF0F4)
                      : const Color(0xFFE5F2EF),
                ),
                const Spacer(),
                Text(
                  '${_formatNumber(entry.credits)}単位',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(entry.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(
              '${entry.date} ・ ${entry.organizer}',
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: Color(0xFFBFD0DC)),
                      SizedBox(width: 8),
                      Text(
                        '認定ID（10桁）',
                        style: TextStyle(
                          color: Color(0xFFBFD0DC),
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
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '参加証・会員マイページとの照合に使用します',
                    style: TextStyle(color: Color(0xFFD8E2E9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
