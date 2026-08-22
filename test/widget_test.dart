import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medlicense/med_license_app.dart';

void main() {
  testWidgets('home shows qualification status and opens registration flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MedLicenseApp());

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
}
