import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medlicense/med_license_app.dart';

void main() {
  Future<void> openSampleHome(WidgetTester tester) async {
    await tester.tap(find.text('サンプルデータで見る'));
    await tester.pumpAndSettle();
  }

  testWidgets('initial setup registers profile and qualification information', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());
    await tester.pumpAndSettle();

    expect(find.text('設定を始める'), findsOneWidget);

    await tester.tap(find.text('設定を始める'));
    await tester.pumpAndSettle();
    expect(find.text('本人情報を登録'), findsOneWidget);

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('保有資格を登録'), findsOneWidget);
    expect(find.text('資格番号（任意）'), findsOneWidget);

    await tester.tap(find.text('登録して始める'));
    await tester.pumpAndSettle();
    expect(find.text('資格更新の状況'), findsOneWidget);
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
