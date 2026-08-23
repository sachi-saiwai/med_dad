import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medlicense/med_license_app.dart';

void main() {
  Future<void> openSampleHome(WidgetTester tester) async {
    await tester.tap(find.text('サンプルデータで見る'));
    await tester.pumpAndSettle();
  }

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
      {'消化器外科専門医', '呼吸器外科専門医', '心臓血管外科専門医', '小児外科専門医', '乳腺外科専門医', '内分泌外科専門医'},
      reason: '日本専門医機構が掲載する外科系6領域だけを下位表示すること',
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
    expect(find.text('認定団体を自動入力しました'), findsOneWidget);
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
      const Offset(0, -240),
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
      const Offset(0, -240),
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

    await tester.tap(find.text('写真から選ぶ'));
    await tester.pumpAndSettle();

    expect(find.text('読み取り内容の確認'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
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
    expect(find.text('学会・発表'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('日本超音波医学会 第99回学術集会'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('日本超音波医学会 第99回学術集会'));
    await tester.pumpAndSettle();

    expect(find.text('認定ID（10桁）'), findsOneWidget);
    expect(find.text('2605290099'), findsOneWidget);
    expect(find.text('反映先'), findsOneWidget);
  });
}
