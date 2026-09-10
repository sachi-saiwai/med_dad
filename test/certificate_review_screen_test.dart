import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/data/app_controller.dart';
import 'package:medlicense/data/app_state.dart';
import 'package:medlicense/med_license_app.dart';
import 'package:medlicense/services/attachment_service.dart';
import 'package:medlicense/services/certificate_ocr_service.dart';

class _FakeCertificateOcrService implements CertificateOcrService {
  @override
  bool get isSupported => true;

  @override
  Future<CertificateOcrResult> recognize(PickedAttachment attachment) async {
    return const CertificateOcrResult(
      engine: 'test-device-ocr',
      blockCount: 6,
      text: '''
受講証明書
第12回 医療安全研修会
開催日：2026年8月18日
主催：一般社団法人 日本医療安全学会
認定ID：2608180042
医療安全講習 2単位
''',
    );
  }
}

void main() {
  testWidgets('端末OCR結果を参加証確認フォームへ自動入力する', (tester) async {
    final controller = AppController.memory();
    await controller.completeSetup(
      displayName: 'テスト利用者',
      qualifications: const [
        StoredQualification(
          id: 'qualification-1',
          name: '外科専門医',
          organization: '日本外科学会',
          licenseNumber: '',
          deadline: '2029/03/31',
        ),
      ],
      notificationsEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CertificateReviewScreen(
          source: 'ファイル選択',
          controller: controller,
          attachment: const PickedAttachment(
            displayName: 'certificate.jpg',
            path: '/tmp/certificate.jpg',
            contentType: 'image/jpeg',
          ),
          ocrService: _FakeCertificateOcrService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<String?> fieldValue(String label) async {
      final finder = find.byKey(ValueKey('certificate-field-$label'));
      for (
        var attempt = 0;
        attempt < 15 && finder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(ListView), const Offset(0, -180));
        await tester.pump();
      }
      expect(finder, findsOneWidget);
      return tester.widget<TextField>(finder).controller?.text;
    }

    expect(await fieldValue('認定ID（10桁）'), '2608180042');
    expect(await fieldValue('研修会・イベント名'), '第12回 医療安全研修会');
    expect(await fieldValue('開催日'), '2026/08/18');
    expect(await fieldValue('主催者'), '一般社団法人 日本医療安全学会');
    expect(await fieldValue('取得単位（不明な場合は空欄）'), '2');
    expect(await fieldValue('単位区分（任意）'), '医療安全講習');
    expect(await fieldValue('その他（任意）'), '');
    final status = find.textContaining('自動入力しました');
    for (
      var attempt = 0;
      attempt < 15 && status.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView), const Offset(0, 180));
      await tester.pump();
    }
    expect(find.textContaining('自動入力しました'), findsOneWidget);
    expect(find.textContaining('test-device-ocr'), findsOneWidget);
  });

  testWidgets('認定IDの候補を選ぶと他の項目を自動入力する', (tester) async {
    final controller = AppController.memory();
    await controller.completeSetup(
      displayName: 'テスト利用者',
      qualifications: const [
        StoredQualification(
          id: 'qualification-1',
          name: '外科専門医',
          organization: '日本外科学会',
          licenseNumber: '',
          deadline: '2029/03/31',
        ),
      ],
      notificationsEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CertificateReviewScreen(source: '手入力', controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final idField = find.byKey(const ValueKey('certificate-field-認定ID（10桁）'));
    expect(idField, findsOneWidget);
    await tester.tap(idField);
    await tester.enterText(idField, '2608');
    await tester.pumpAndSettle();

    expect(find.text('2608180042'), findsWidgets);
    await tester.tap(find.text('第42回 地域医療研修会').last);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(idField).controller?.text, '2608180042');
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('certificate-field-研修会・イベント名')),
          )
          .controller
          ?.text,
      '第42回 地域医療研修会',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('certificate-field-開催日')),
          )
          .controller
          ?.text,
      '2026/08/18',
    );
  });
}
