import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medlicense/data/app_state.dart';
import 'package:medlicense/med_license_app.dart';
import 'package:medlicense/services/official_rule_service.dart';

void main() {
  Future<void> openSampleHome(WidgetTester tester) async {
    await tester.tap(find.text('サンプルデータで見る'));
    await tester.pumpAndSettle();
  }

  test('stored qualification uses only allocated real activities', () {
    const qualification = StoredQualification(
      id: 'qualification-1',
      name: '内科専門医',
      organization: '日本内科学会',
      licenseNumber: 'CERT-1',
      memberId: 'MEMBER-1',
      deadline: '2028/03/31',
    );
    const snapshot = AppSnapshot(
      qualifications: [qualification],
      activities: [
        StoredActivity(
          id: 'real-activity',
          title: '実際に登録した講習',
          date: '2026/09/01',
          organizer: '日本内科学会',
          status: '確定',
          credits: 2,
          source: '手入力',
          createdAt: '2026-09-01T00:00:00.000',
          allocations: [
            StoredActivityAllocation(
              qualificationId: 'qualification-1',
              credits: 2,
              category: '共通講習',
            ),
          ],
        ),
      ],
    );

    final result = qualificationFromStored(qualification, snapshot);
    expect(result.total, 2);
    expect(result.creditEntries, hasLength(1));
    expect(result.creditEntries.single.title, '実際に登録した講習');
    expect(result.creditEntries.single.certificationId, isEmpty);
    expect(result.creditEntries.single.hasEvidence, isFalse);
    expect(result.evidenceSummary.confirmedActivities, 1);
    expect(result.evidenceSummary.missingEvidence, 1);
  });

  test('stored activity keeps a ten digit certification ID', () {
    const qualification = StoredQualification(
      id: 'qualification-1',
      name: '内科専門医',
      organization: '日本内科学会',
      licenseNumber: 'CERT-1',
      memberId: 'MEMBER-1',
      deadline: '2028/03/31',
    );
    const snapshot = AppSnapshot(
      qualifications: [qualification],
      activities: [
        StoredActivity(
          id: 'real-activity',
          title: '実際に登録した講習',
          date: '2026/09/01',
          organizer: '日本内科学会',
          status: '確定',
          credits: 2,
          source: '手入力',
          createdAt: '2026-09-01T00:00:00.000',
          certificationId: '2609010042',
          notes: 'オンライン受講',
          allocations: [
            StoredActivityAllocation(
              qualificationId: 'qualification-1',
              credits: 2,
              category: '共通講習',
            ),
          ],
        ),
      ],
    );

    final result = qualificationFromStored(qualification, snapshot);
    expect(result.creditEntries.single.certificationId, '2609010042');
    expect(
      AppSnapshot.fromJson(snapshot.toJson()).activities.single.notes,
      'オンライン受講',
    );
  });

  test('surgical qualification catalog contains verified specialties', () {
    final organizationsByName = {
      for (final entry in qualificationCatalog) entry.name: entry.organization,
    };
    const expectedOrganizations = {
      '消化器外科専門医': '日本専門医機構／日本消化器外科学会',
      '呼吸器外科専門医': '日本専門医機構／呼吸器外科専門医合同委員会',
      '心臓血管外科専門医': '日本専門医機構／心臓血管外科専門医認定機構',
      '小児外科専門医': '日本専門医機構／日本小児外科学会',
      '乳腺外科専門医': '日本専門医機構／日本乳癌学会',
      '内分泌外科専門医': '日本専門医機構／日本内分泌外科学会',
      '乳腺専門医': '日本乳癌学会',
      '大腸肛門病専門医': '日本大腸肛門病学会',
      '肝胆膵外科高度技能専門医': '日本肝胆膵外科学会',
      '内視鏡外科技術認定医': '日本内視鏡外科学会',
      '脈管専門医': '日本脈管学会',
      '移植認定医': '日本移植学会',
      'がん治療認定医': '日本がん治療認定医機構',
    };

    expect(organizationsByName, containsPair('外科専門医', '日本専門医機構／日本外科学会'));
    for (final expected in expectedOrganizations.entries) {
      expect(
        organizationsByName,
        containsPair(expected.key, expected.value),
        reason: '${expected.key}の認定団体が候補マスターと一致すること',
      );
    }

    expect(
      surgicalSubspecialtyCatalog.map((entry) => entry.name).toSet(),
      {
        '消化器外科専門医',
        '呼吸器外科専門医',
        '心臓血管外科専門医',
        '小児外科専門医',
        '乳腺外科専門医',
        '乳腺専門医',
        '内分泌外科専門医',
      },
      reason: '外科系6領域と併存する学会認定の乳腺専門医を下位表示すること',
    );
  });

  test('pediatric search contains verified related qualifications', () {
    final pediatricNames = qualificationCatalog
        .where((entry) => entry.matches('小児'))
        .map((entry) => entry.name)
        .toSet();

    expect(
      pediatricNames,
      containsAll({
        '小児科専門医',
        '小児外科専門医',
        '小児神経専門医',
        '小児循環器専門医',
        '内分泌代謝科（小児科）専門医',
        '小児血液・がん専門医',
        '新生児専門医',
        '小児感染症認定指導医（専門医）',
        'アレルギー専門医',
      }),
    );
    expect(
      qualificationCatalog
          .singleWhere((entry) => entry.name == '内分泌代謝科（小児科）専門医')
          .matches('小児内分泌'),
      isTrue,
    );
  });

  test('catalog covers official specialist fields with prefix matching', () {
    final catalogByName = {
      for (final entry in qualificationCatalog) entry.name: entry,
    };
    const expectedSpecialists = {
      '消化器病専門医',
      '循環器専門医',
      '呼吸器専門医',
      '血液専門医',
      '内分泌代謝科専門医',
      '糖尿病専門医',
      '腎臓専門医',
      '肝臓専門医',
      'アレルギー専門医',
      '感染症専門医',
      '老年科専門医',
      '神経内科専門医',
      'リウマチ専門医',
      '消化器内視鏡専門医',
      'がん薬物療法専門医',
      '放射線診断専門医',
      '放射線治療専門医',
      '放射線カテーテル治療専門医',
      '集中治療科専門医',
      '脊椎脊髄外科専門医',
    };

    expect(catalogByName.keys, containsAll(expectedSpecialists));
    expect(catalogByName['消化器病専門医']!.matchScore('消'), 0);
    expect(catalogByName['呼吸器専門医']!.matchScore('呼吸'), 0);
    expect(catalogByName['放射線診断専門医']!.matchScore('放射'), 0);
    expect(catalogByName['神経内科専門医']!.matches('脳神経'), isTrue);
  });

  test('rehabilitation search contains related medical qualifications', () {
    final rehabilitationNames = qualificationCatalog
        .where((entry) => entry.matches('リハビリ'))
        .map((entry) => entry.name)
        .toSet();

    expect(
      rehabilitationNames,
      containsAll({'リハビリテーション科専門医', '認定臨床医', '運動器リハビリテーション医'}),
    );
  });

  testWidgets('initial setup registers profile and qualification information', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    expect(find.text('設定を始める'), findsOneWidget);

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    expect(find.text('本人情報を登録'), findsOneWidget);
    expect(find.text('例：田中 太郎'), findsOneWidget);
    expect(find.text('利用する端末'), findsNothing);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('保有資格を登録'), findsOneWidget);
    expect(find.text('資格番号（任意）'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('quick-primary-internal-medicine')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録して始める'));
    await tester.pumpAndSettle();
    expect(find.text('資格更新の状況'), findsOneWidget);
  });

  testWidgets('qualification suggestion autofills its organization', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    final qualificationName = find.byKey(
      const ValueKey('qualification-name-1'),
    );
    await tester.ensureVisible(qualificationName);
    await tester.enterText(qualificationName, '循環器');
    await tester.pumpAndSettle();

    expect(find.text('循環器専門医'), findsOneWidget);
    await tester.tap(find.text('循環器専門医'));
    await tester.pumpAndSettle();

    final organization = tester.widget<TextFormField>(
      find.byKey(const ValueKey('qualification-organization-1')),
    );
    expect(organization.controller?.text, '日本循環器学会');
    expect(find.text('認定団体と更新条件を自動設定しました'), findsOneWidget);
  });

  testWidgets('other selection searches many pediatric qualifications', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    final otherButton = find.byKey(const ValueKey('quick-primary-other'));
    await tester.drag(
      find.byKey(const ValueKey('setup-step-2')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.tap(otherButton);
    await tester.pumpAndSettle();

    final qualificationName = find.byKey(
      const ValueKey('qualification-name-1'),
    );
    await tester.enterText(qualificationName, '小児');
    await tester.pumpAndSettle();

    expect(find.text('小児科専門医'), findsOneWidget);
    expect(find.text('小児神経専門医'), findsOneWidget);
    expect(find.text('小児循環器専門医'), findsOneWidget);
  });

  testWidgets('qualification prefix shows multiple specialist candidates', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('setup-step-2')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();

    final qualificationName = find.byKey(
      const ValueKey('qualification-name-1'),
    );
    await tester.enterText(qualificationName, '消化');
    await tester.pumpAndSettle();

    expect(find.text('消化器病専門医'), findsOneWidget);
    expect(find.text('消化器内視鏡専門医'), findsOneWidget);
    expect(find.text('消化器外科専門医'), findsOneWidget);
  });

  testWidgets('surgery quick selection reveals verified subspecialties', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('quick-primary-internal-medicine')),
    );
    await tester.pumpAndSettle();
    var organization = tester.widget<TextFormField>(
      find.byKey(const ValueKey('qualification-organization-1')),
    );
    expect(organization.controller?.text, '日本専門医機構／日本内科学会');
    expect(
      find.byKey(const ValueKey('surgical-subspecialty-section')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('quick-primary-surgery')));
    await tester.pumpAndSettle();
    organization = tester.widget<TextFormField>(
      find.byKey(const ValueKey('qualification-organization-1')),
    );
    expect(organization.controller?.text, '日本専門医機構／日本外科学会');
    expect(find.text('外科のサブスペシャルティ'), findsOneWidget);
    expect(find.text('消化器外科専門医'), findsOneWidget);
    expect(find.text('呼吸器外科専門医'), findsOneWidget);
    expect(find.text('心臓血管外科専門医'), findsOneWidget);
    expect(find.text('小児外科専門医'), findsOneWidget);
    expect(find.text('乳腺外科専門医'), findsOneWidget);
    expect(find.text('内分泌外科専門医'), findsOneWidget);
    expect(find.text('大腸肛門病専門医'), findsNothing);

    final digestiveSurgery = find.byKey(
      const ValueKey('subspecialty-1-消化器外科専門医'),
    );
    await tester.drag(
      find.byKey(const ValueKey('setup-step-2')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await tester.tap(digestiveSurgery);
    await tester.pumpAndSettle();
    expect(find.text('資格番号（任意）'), findsOneWidget);
    expect(find.text('次回更新期限'), findsOneWidget);
  });

  testWidgets('home shows qualification status and opens registration flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await openSampleHome(tester);

    expect(find.text('資格更新の状況'), findsOneWidget);
    expect(find.text('超音波専門医'), findsWidgets);
    expect(find.text('参加証を登録する'), findsOneWidget);

    await tester.tap(find.text('参加証を登録する'));
    await tester.pumpAndSettle();

    expect(find.text('登録方法を選んでください'), findsOneWidget);
    expect(find.text('写真から選ぶ'), findsOneWidget);
    expect(find.text('参加予定を登録'), findsOneWidget);

    await tester.tap(find.text('写真から選ぶ'));
    await tester.pumpAndSettle();

    expect(find.text('読み取り内容の確認'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('認定ID（10桁）'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(find.text('その他（任意）'), findsOneWidget);
    expect(find.text('反映する資格'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '確定して登録'), findsOneWidget);
  });

  testWidgets('credit breakdown shows a ten digit certification ID', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await openSampleHome(tester);

    await tester.tap(find.text('次の更新期限'));
    await tester.pumpAndSettle();

    expect(find.text('資格の詳細'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('単位の内訳'),
      400,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('単位の内訳'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('学会・発表'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('学会・発表'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('日本超音波医学会 第99回学術集会'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('日本超音波医学会 第99回学術集会'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本超音波医学会 第99回学術集会'));
    await tester.pumpAndSettle();

    expect(find.text('認定ID（10桁）'), findsOneWidget);
    expect(find.text('2605290099'), findsOneWidget);
    expect(find.text('反映先'), findsOneWidget);
  });

  testWidgets(
    'activity detail actions open attachment, allocations, and history',
    (tester) async {
      await tester.pumpWidget(const MedLicenseApp());
      await openSampleHome(tester);

      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();
      expect(find.text('登録した参加証と単位を確認できます'), findsOneWidget);

      await tester.tap(find.text('医療安全講習会'));
      await tester.pumpAndSettle();
      expect(find.text('証明書画像を見る'), findsOneWidget);

      await tester.ensureVisible(find.text('資格への割当を見る'));
      await tester.tap(find.text('資格への割当を見る'));
      await tester.pumpAndSettle();
      expect(find.text('資格への割当'), findsOneWidget);
      expect(find.text('医療安全'), findsOneWidget);
      Navigator.of(tester.element(find.text('資格への割当'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('変更履歴を見る'));
      await tester.tap(find.text('変更履歴を見る'));
      await tester.pumpAndSettle();
      expect(find.text('変更履歴'), findsOneWidget);
      expect(find.text('実績を登録'), findsOneWidget);
      expect(find.textContaining('カメラ撮影で登録'), findsOneWidget);
      Navigator.of(tester.element(find.text('変更履歴'))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('証明書画像を見る'));
      await tester.tap(find.text('証明書画像を見る'));
      await tester.pumpAndSettle();
      expect(find.text('証明書画像'), findsOneWidget);
      expect(find.text('医療安全講習会'), findsWidgets);
    },
  );

  testWidgets('qualification detail automatically loads a published rule', (
    tester,
  ) async {
    final completer = Completer<OfficialRuleLookup>();
    const qualification = Qualification(
      name: '外科専門医',
      organization: '日本専門医機構／日本外科学会',
      deadline: '2027年12月31日',
      remainingDays: 400,
      state: QualificationState.needsAttention,
      total: 0,
      requiredTotal: 0,
      headline: '公式の更新条件を取得・確認中です',
      requirements: [],
      hasVerifiedRequirements: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QualificationDetailScreen(
          qualification: qualification,
          officialRuleLoader: (_) => completer.future,
        ),
      ),
    );
    expect(find.text('条件を自動取得しています'), findsOneWidget);

    completer.complete(
      OfficialRuleLookup(
        qualificationFound: true,
        rule: OfficialRenewalRule(
          id: 1,
          systemType: '日本専門医機構認定',
          renewalCycleYears: 5,
          requiredTotalCredits: 50,
          requirements: const [
            OfficialRequirement(
              label: '外科領域講習',
              unit: '単位',
              mandatory: true,
              minimum: 20,
            ),
          ],
          mandatoryNotes: const ['勤務実態の自己申告が必要'],
          otherConditions: const ['診療実績の証明が必要'],
          source: OfficialRuleSource(
            title: '外科領域 専門医更新基準 2024',
            url: 'https://example.com/rule.pdf',
            checkedAt: DateTime.utc(2026, 8, 24),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('承認済みの公式条件'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('承認済みの公式条件'), findsOneWidget);
    expect(find.text('必要総単位 50単位'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('外科領域講習'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('外科領域講習'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('勤務実態の自己申告が必要'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('勤務実態の自己申告が必要'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('公式資料を2026年8月24日に確認'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('公式資料を2026年8月24日に確認'), findsOneWidget);
  });

  testWidgets('qualification detail explains when no rule is published', (
    tester,
  ) async {
    const qualification = Qualification(
      name: '外科専門医',
      organization: '日本専門医機構／日本外科学会',
      deadline: '未登録',
      remainingDays: 0,
      state: QualificationState.needsAttention,
      total: 0,
      requiredTotal: 0,
      headline: '公式の更新条件を取得・確認中です',
      requirements: [],
      hasVerifiedRequirements: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QualificationDetailScreen(
          qualification: qualification,
          officialRuleLoader: (_) async =>
              const OfficialRuleLookup(qualificationFound: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('承認済みの更新条件はまだありません'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('承認済みの更新条件はまだありません'), findsWidgets);
    expect(find.text('再取得する'), findsOneWidget);
  });
}
