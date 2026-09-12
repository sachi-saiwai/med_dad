import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/data/app_state.dart';
import 'package:medlicense/med_license_app.dart';
import 'package:medlicense/services/official_rule_service.dart';

void main() {
  test('証憑・会費・申請期間を含めて申請準備を判定する', () {
    const qualification = Qualification(
      name: '外科専門医',
      organization: '日本外科学会',
      deadline: '2027年12月31日',
      creditDeadline: '2027年11月30日',
      applicationStartDate: '2027年10月1日',
      applicationDeadline: '2027年12月15日',
      remainingDays: 100,
      state: QualificationState.onTrack,
      total: 50,
      requiredTotal: 50,
      headline: '必要単位に到達しています',
      requirements: [
        RequirementProgress(
          label: '総単位',
          current: 50,
          requiredValue: 50,
          unit: '単位',
        ),
      ],
      membershipFeeStatus: membershipFeePaid,
      evidenceSummary: QualificationEvidenceSummary(
        confirmedActivities: 4,
        attachedEvidence: 4,
      ),
    );

    final readiness = qualification.readinessAt(DateTime(2027, 11, 1));
    expect(readiness.isReady, isTrue);
    expect(readiness.completedCount, readiness.checks.length);
  });

  test('公式要件の新旧版から本人への影響を作る', () {
    final rule = OfficialRenewalRule(
      id: 2,
      systemType: '日本専門医機構認定',
      requiredTotalCredits: 50,
      requirements: const [
        OfficialRequirement(
          label: '医療倫理',
          unit: '単位',
          mandatory: true,
          minimum: 1,
        ),
      ],
      mandatoryNotes: const ['勤務実態の自己申告が必要'],
      otherConditions: const [],
      source: OfficialRuleSource(
        title: '更新基準',
        url: 'https://example.com/rule.pdf',
        checkedAt: DateTime.utc(2026, 9, 1),
      ),
      previousRevision: const OfficialRuleRevision(
        id: 1,
        requiredTotalCredits: 40,
        requirements: [],
        mandatoryNotes: [],
        otherConditions: [],
      ),
    );

    expect(rule.changeImpactMessages, contains('必要総単位が40単位から50単位へ変更されました。'));
    expect(rule.changeImpactMessages, contains('「医療倫理」が新たな必須条件として追加されました。'));
  });

  testWidgets('資格詳細に競合差別化情報を表示する', (tester) async {
    const qualification = Qualification(
      name: '外科専門医',
      organization: '日本外科学会',
      deadline: '2027年12月31日',
      creditDeadline: '2027年11月30日',
      applicationStartDate: '2027年10月1日',
      applicationDeadline: '2027年12月15日',
      nextDeadlineLabel: '単位算入期限',
      nextDeadlineDate: '2027年11月30日',
      remainingDays: 100,
      state: QualificationState.needsAttention,
      total: 40,
      requiredTotal: 50,
      headline: 'あと10単位必要です',
      requirements: [
        RequirementProgress(
          label: '総単位',
          current: 40,
          requiredValue: 50,
          unit: '単位',
        ),
      ],
      memberPortalUrl: 'https://example.com/member',
      evidenceSummary: QualificationEvidenceSummary(
        confirmedActivities: 4,
        attachedEvidence: 2,
      ),
      ruleChangeMessages: ['必要総単位が40単位から50単位へ変更されました。'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: QualificationDetailScreen(qualification: qualification),
      ),
    );

    await tester.tap(find.byTooltip('更新申請パケット'));
    await tester.pumpAndSettle();
    expect(find.text('更新申請パケット'), findsOneWidget);
    expect(find.text('PDFを保存'), findsOneWidget);
    expect(find.text('ZIPを保存'), findsOneWidget);
    Navigator.of(tester.element(find.text('更新申請パケット'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('更新に関わる3つの期限'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('証憑充足率'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('2件の証憑が未添付'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('パスワードは保存しません'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('公式サイトで直接入力'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('更新要件の変更・あなたへの影響'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(const ValueKey('rule-change-impact-card')),
      findsOneWidget,
    );
  });
}
