import 'dart:async';

import 'package:flutter/material.dart';

import 'data/app_controller.dart';
import 'data/app_state.dart';
import 'services/attachment_service.dart';

const _ink = Color(0xFF18324A);
const _primary = Color(0xFF2D6A63);
const _canvas = Color(0xFFF4F6F2);
const _line = Color(0xFFDCE3DE);
const _warning = Color(0xFFE88C32);
const _danger = Color(0xFFB85042);

class MedLicenseApp extends StatefulWidget {
  const MedLicenseApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<MedLicenseApp> createState() => _MedLicenseAppState();
}

class _MedLicenseAppState extends State<MedLicenseApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController.memory();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      surface: Colors.white,
      error: _danger,
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
        home: _controller.isSetupComplete || _controller.demoMode
            ? AppShell(controller: _controller)
            : InitialSetupScreen(controller: _controller),
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
    required this.name,
    required this.organization,
    required this.deadline,
    required this.remainingDays,
    required this.state,
    required this.total,
    required this.requiredTotal,
    required this.headline,
    required this.requirements,
    this.hasVerifiedRequirements = true,
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
  final bool hasVerifiedRequirements;

  double get progress =>
      requiredTotal <= 0 ? 0 : (total / requiredTotal).clamp(0, 1);
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

Qualification qualificationFromStored(StoredQualification stored) {
  final deadline = _parseFlexibleDate(stored.deadline);
  final remainingDays = deadline == null
      ? 0
      : DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
        ).difference(DateTime.now()).inDays;
  return Qualification(
    name: stored.name,
    organization: stored.organization,
    deadline: deadline == null
        ? '未登録'
        : '${deadline.year}年${deadline.month}月${deadline.day}日',
    remainingDays: remainingDays,
    state: QualificationState.needsAttention,
    total: 0,
    requiredTotal: 0,
    headline: '公式の更新条件を取得・確認中です',
    requirements: const [],
    hasVerifiedRequirements: false,
  );
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
  }) : subspecialtyNames = {};

  final int id;
  String name;
  String organization;
  String licenseNumber;
  String deadline;
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
          style: TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'お名前・呼び名',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
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
          '外科・内科は下のボタンからすぐ選べます。それ以外は「その他」から診療分野で検索できます。',
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
                  '資格を選ぶと、総単位・区分別単位・必須講習などの更新条件を自動設定します。登録後に内容を確認・修正できます。',
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
            const Text(
              'よく使う基本領域',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '当てはまる方を1つ選んでください',
              style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
                            '候補を選ぶと認定団体と更新条件を自動設定します',
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
                          '認定団体と更新条件を自動設定しました',
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
        color: selected ? const Color(0xFFE1F2ED) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
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
                    color: selected ? _primary : const Color(0xFFEAF0ED),
                    borderRadius: BorderRadius.circular(11),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 11,
                        ),
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
        color: const Color(0xFFF2F7F5),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFBED8D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _IconTile(
                icon: Icons.account_tree_outlined,
                color: _primary,
                background: Color(0xFFDDEFE9),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '保有している資格を複数選択できます',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.blueGrey,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '日本専門医機構の領域一覧に基づく6領域です。更新方法は各団体の公式情報で確認してください。',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
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
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              entry.organization,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
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
  const AppShell({super.key, required this.controller});

  final AppController controller;

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
    if (widget.controller.demoMode && source != '手入力') {
      attachment = const PickedAttachment(displayName: '受講証明書_0818.jpg');
    } else if (source != '手入力') {
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
      3 => SettingsScreen(controller: widget.controller),
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
              .map(qualificationFromStored)
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey.shade600,
                ),
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
        builder: (_) => QualificationDetailScreen(qualification: qualification),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '資格更新ノート',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (displayName.trim().isNotEmpty)
                Text(
                  '${displayName.trim()}さんの資格管理',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              const SizedBox(height: 2),
              const Text(
                '本人専用',
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
        ),
        if (isDemo)
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
  const _NextDeadlineCard({required this.qualification, required this.onTap});

  final Qualification qualification;
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
                    child: Text(
                      qualification.remainingDays >= 0
                          ? 'あと${qualification.remainingDays}日'
                          : '${-qualification.remainingDays}日超過',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                qualification.deadline,
                style: const TextStyle(color: Color(0xFFD8E2E9), fontSize: 15),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFFC36E),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qualification.headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
              if (qualification.hasVerifiedRequirements)
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
                )
              else
                const Text(
                  '更新条件：公式情報を確認中',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
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
                                qualification.hasVerifiedRequirements
                                    ? '${(qualification.progress * 100).round()}%'
                                    : '確認中',
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
                                qualification.hasVerifiedRequirements
                                    ? '${qualification.total.toInt()} / ${qualification.requiredTotal.toInt()} 単位'
                                    : '条件を取得しています',
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
                if (!qualification.hasVerifiedRequirements)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '認定団体の公式ページ・PDFを確認し、制度区分と取得年度に合う条件を出典付きで表示します。確認が終わるまでは自動計算しません。',
                        style: TextStyle(color: Colors.blueGrey, height: 1.5),
                      ),
                    ),
                  ),
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
          if (qualification.deadline != '未登録')
            Text(
              qualification.remainingDays >= 0
                  ? 'あと${qualification.remainingDays}日'
                  : '${-qualification.remainingDays}日超過',
              style: const TextStyle(
                color: _danger,
                fontWeight: FontWeight.w800,
              ),
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
  const CertificateReviewScreen({
    super.key,
    required this.source,
    required this.controller,
    this.attachment,
  });

  final String source;
  final AppController controller;
  final PickedAttachment? attachment;

  @override
  State<CertificateReviewScreen> createState() =>
      _CertificateReviewScreenState();
}

class _CertificateReviewScreenState extends State<CertificateReviewScreen> {
  late final TextEditingController _eventController;
  late final TextEditingController _dateController;
  late final TextEditingController _organizerController;
  late final TextEditingController _creditsController;
  final Set<String> _selectedQualificationIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
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
    _selectedQualificationIds.addAll(
      widget.controller.snapshot.qualifications.map((item) => item.id),
    );
  }

  @override
  void dispose() {
    _eventController.dispose();
    _dateController.dispose();
    _organizerController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool draft}) async {
    if (_saving) return;
    if (_eventController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('研修会・イベント名を入力してください')));
      return;
    }
    setState(() => _saving = true);
    final activity = StoredActivity(
      id: 'activity-${DateTime.now().microsecondsSinceEpoch}',
      title: _eventController.text.trim(),
      date: _dateController.text.trim(),
      organizer: _organizerController.text.trim(),
      status: draft ? '下書き' : '確定',
      credits: double.tryParse(_creditsController.text.trim()) ?? 0,
      source: widget.source,
      createdAt: DateTime.now().toIso8601String(),
      attachmentPath: widget.attachment?.path,
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
        ),
      ),
    );
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
                  _CertificatePreview(
                    source: widget.source,
                    fileName: widget.attachment?.displayName,
                  ),
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
                const SizedBox(height: 14),
                _LabeledField(
                  label: '取得単位（不明な場合は空欄）',
                  controller: _creditsController,
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
                ...widget.controller.snapshot.qualifications.map(
                  (qualification) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AllocationCard(
                      qualification: qualification.name,
                      category: '区分は公式条件と照合',
                      credits: _creditsController.text.trim().isEmpty
                          ? '単位未確認'
                          : '${_creditsController.text.trim()}単位',
                      selected: _selectedQualificationIds.contains(
                        qualification.id,
                      ),
                      reason: '登録資格と認定団体の公式更新条件を照合して確定します',
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
  const _CertificatePreview({required this.source, this.fileName});

  final String source;
  final String? fileName;

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
                Text(
                  fileName?.trim().isNotEmpty == true
                      ? fileName!
                      : '受講証明書_0818.jpg',
                  style: const TextStyle(
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
  const RegistrationResultScreen({
    super.key,
    required this.qualificationCount,
    this.showSampleProgress = false,
  });

  final int qualificationCount;
  final bool showSampleProgress;

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
                if (showSampleProgress)
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
  const ActivityListScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final sampleActivities = <_ActivityData>[
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
    final activities = widget.controller.demoMode
        ? sampleActivities
        : widget.controller.snapshot.activities
              .map(
                (item) => _ActivityData(
                  title: item.title,
                  date: item.date.isEmpty ? '日付未入力' : item.date,
                  organizer: item.organizer.isEmpty ? '主催者未入力' : item.organizer,
                  status: item.status,
                  credits: item.credits > 0
                      ? '${_formatNumber(item.credits)}単位'
                      : '単位未確認',
                  needsReview: item.status != '確定',
                ),
              )
              .toList();
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
  const _ActivityCard({required this.activity, required this.controller});

  final _ActivityData activity;
  final AppController controller;

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
                builder: (_) => CertificateReviewScreen(
                  source: '保存済みの写真',
                  controller: controller,
                ),
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
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _deadlineNotifications;
  late bool _missingNotifications;
  late bool _deviceLock;

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
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${widget.controller.snapshot.qualifications.length}件の資格を端末内に保存',
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
            '資格更新ノート  iPhone MVP v1.0',
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
