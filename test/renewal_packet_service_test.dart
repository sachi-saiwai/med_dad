import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/services/renewal_packet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('更新申請パケットのPDFを生成する', () async {
    const service = RenewalPacketService();

    final bundle = await service.buildPdf(_sampleData());

    expect(bundle.fileName, '外科専門医_更新申請パケット_20260912.pdf');
    expect(String.fromCharCodes(bundle.bytes.take(4)), '%PDF');
    expect(bundle.bytes.length, greaterThan(1000));
  });

  test('ZIPに申請準備PDFと安全な名前の証憑原本を格納する', () async {
    const service = RenewalPacketService();

    final bundle = await service.buildZip(
      _sampleData(),
      evidenceFiles: [
        RenewalPacketEvidenceFile(
          activityId: 'activity-1',
          fileName: '../参加証.pdf',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );
    final archive = ZipDecoder().decodeBytes(bundle.bytes);
    final files = archive.files.where((file) => file.isFile).toList();

    expect(bundle.fileName, '外科専門医_更新申請パケット_20260912.zip');
    expect(bundle.includedEvidenceCount, 1);
    expect(files, hasLength(2));
    expect(files.any((file) => file.name.endsWith('_申請準備資料.pdf')), isTrue);
    final evidence = files.singleWhere((file) => file.name.startsWith('証憑/'));
    expect(evidence.name, isNot(contains('..')));
    expect(evidence.content, [1, 2, 3, 4]);
  });
}

RenewalPacketData _sampleData() {
  return RenewalPacketData(
    qualificationName: '外科専門医',
    organization: '日本外科学会',
    licenseNumber: 'S-12345',
    memberId: 'M-67890',
    credentialDeadline: '2027年12月31日',
    creditDeadline: '2027年11月30日',
    applicationStartDate: '2027年10月1日',
    applicationDeadline: '2027年12月15日',
    membershipFeeStatus: '支払済み',
    currentCredits: 40,
    plannedCredits: 5,
    requiredCredits: 50,
    confirmedActivityCount: 1,
    attachedEvidenceCount: 1,
    requirements: const [
      RenewalPacketRequirement(
        label: '総単位',
        current: 40,
        requiredValue: 50,
        unit: '単位',
        complete: false,
      ),
      RenewalPacketRequirement(
        label: '医療安全',
        current: 2,
        requiredValue: 2,
        unit: '単位',
        complete: true,
      ),
    ],
    readinessChecks: const [
      RenewalPacketReadinessCheck(
        label: '単位',
        detail: 'あと10単位必要です',
        status: '要対応',
      ),
      RenewalPacketReadinessCheck(
        label: '証憑',
        detail: 'すべて添付済みです',
        status: '確認済み',
      ),
    ],
    activities: const [
      RenewalPacketActivity(
        id: 'activity-1',
        title: '医療安全講習会',
        date: '2026年9月1日',
        organizer: '日本外科学会',
        category: '必須講習',
        credits: 2,
        certificationId: 'CERT-001',
        hasEvidence: true,
      ),
    ],
    sourceTitle: '専門医制度規則',
    sourceUrl: 'https://example.com/rule.pdf',
    sourceCheckedAt: '2026年9月12日',
    generatedAt: DateTime(2026, 9, 12, 10, 30),
  );
}
