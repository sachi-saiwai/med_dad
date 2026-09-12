import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum RenewalPacketFormat { pdf, zip }

class RenewalPacketRequirement {
  const RenewalPacketRequirement({
    required this.label,
    required this.current,
    required this.requiredValue,
    required this.unit,
    required this.complete,
  });

  final String label;
  final double current;
  final double requiredValue;
  final String unit;
  final bool complete;
}

class RenewalPacketReadinessCheck {
  const RenewalPacketReadinessCheck({
    required this.label,
    required this.detail,
    required this.status,
  });

  final String label;
  final String detail;
  final String status;
}

class RenewalPacketActivity {
  const RenewalPacketActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.organizer,
    required this.category,
    required this.credits,
    required this.certificationId,
    required this.hasEvidence,
  });

  final String id;
  final String title;
  final String date;
  final String organizer;
  final String category;
  final double credits;
  final String certificationId;
  final bool hasEvidence;
}

class RenewalPacketEvidenceFile {
  const RenewalPacketEvidenceFile({
    required this.activityId,
    required this.fileName,
    required this.bytes,
  });

  final String activityId;
  final String fileName;
  final Uint8List bytes;
}

class RenewalPacketData {
  const RenewalPacketData({
    required this.qualificationName,
    required this.organization,
    required this.licenseNumber,
    required this.memberId,
    required this.credentialDeadline,
    required this.creditDeadline,
    required this.applicationStartDate,
    required this.applicationDeadline,
    required this.membershipFeeStatus,
    required this.currentCredits,
    required this.plannedCredits,
    required this.requiredCredits,
    required this.confirmedActivityCount,
    required this.attachedEvidenceCount,
    required this.requirements,
    required this.readinessChecks,
    required this.activities,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.sourceCheckedAt,
    required this.generatedAt,
  });

  final String qualificationName;
  final String organization;
  final String licenseNumber;
  final String memberId;
  final String credentialDeadline;
  final String creditDeadline;
  final String applicationStartDate;
  final String applicationDeadline;
  final String membershipFeeStatus;
  final double currentCredits;
  final double plannedCredits;
  final double requiredCredits;
  final int confirmedActivityCount;
  final int attachedEvidenceCount;
  final List<RenewalPacketRequirement> requirements;
  final List<RenewalPacketReadinessCheck> readinessChecks;
  final List<RenewalPacketActivity> activities;
  final String sourceTitle;
  final String sourceUrl;
  final String sourceCheckedAt;
  final DateTime generatedAt;
}

class RenewalPacketBundle {
  const RenewalPacketBundle({
    required this.bytes,
    required this.fileName,
    required this.includedEvidenceCount,
    required this.unavailableEvidenceCount,
  });

  final Uint8List bytes;
  final String fileName;
  final int includedEvidenceCount;
  final int unavailableEvidenceCount;
}

class RenewalPacketService {
  const RenewalPacketService();

  static const _fontAsset = 'assets/fonts/NotoSansJP-Variable.ttf';
  static const maxEvidenceBytes = 50 * 1024 * 1024;

  Future<RenewalPacketBundle> buildPdf(RenewalPacketData data) async {
    final bytes = await _buildPdfBytes(data, const [], const {});
    return RenewalPacketBundle(
      bytes: bytes,
      fileName: '${renewalPacketBaseName(data)}.pdf',
      includedEvidenceCount: 0,
      unavailableEvidenceCount: 0,
    );
  }

  Future<RenewalPacketBundle> buildZip(
    RenewalPacketData data, {
    required List<RenewalPacketEvidenceFile> evidenceFiles,
    Set<String> unavailableEvidenceIds = const {},
  }) async {
    final uniqueEvidence = <String, RenewalPacketEvidenceFile>{};
    var totalBytes = 0;
    for (final evidence in evidenceFiles) {
      if (uniqueEvidence.containsKey(evidence.activityId)) continue;
      if (totalBytes + evidence.bytes.length > maxEvidenceBytes) {
        continue;
      }
      uniqueEvidence[evidence.activityId] = evidence;
      totalBytes += evidence.bytes.length;
    }

    final unavailable = {
      ...unavailableEvidenceIds,
      ...evidenceFiles
          .where((item) => !uniqueEvidence.containsKey(item.activityId))
          .map((item) => item.activityId),
    };
    final included = uniqueEvidence.values.toList(growable: false);
    final pdfBytes = await _buildPdfBytes(data, included, unavailable);
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          '01_${_safeFileName(data.qualificationName)}_申請準備資料.pdf',
          pdfBytes,
        ),
      );
    final usedNames = <String>{};
    for (var index = 0; index < included.length; index += 1) {
      final evidence = included[index];
      final name = _uniqueEvidenceName(evidence.fileName, index + 1, usedNames);
      archive.addFile(ArchiveFile.bytes('証憑/$name', evidence.bytes));
    }
    final zipBytes = ZipEncoder().encodeBytes(archive);
    return RenewalPacketBundle(
      bytes: zipBytes,
      fileName: '${renewalPacketBaseName(data)}.zip',
      includedEvidenceCount: included.length,
      unavailableEvidenceCount: unavailable.length,
    );
  }

  Future<bool> save(RenewalPacketBundle bundle) async {
    final extension = bundle.fileName.toLowerCase().endsWith('.zip')
        ? 'zip'
        : 'pdf';
    final saved = await FilePicker.saveFile(
      dialogTitle: '更新申請パケットの保存先を選択',
      fileName: bundle.fileName,
      bytes: bundle.bytes,
      mimeType: extension == 'zip' ? 'application/zip' : 'application/pdf',
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    return saved != null;
  }

  Future<Uint8List> _buildPdfBytes(
    RenewalPacketData data,
    List<RenewalPacketEvidenceFile> evidenceFiles,
    Set<String> unavailableEvidenceIds,
  ) async {
    final fontData = await rootBundle.load(_fontAsset);
    final font = pw.Font.ttf(fontData);
    final document = pw.Document(
      title: '${data.qualificationName} 更新申請準備資料',
      author: '資格更新ノート',
      subject: '専門医資格の更新申請準備用資料',
    );
    final evidenceByActivity = {
      for (final file in evidenceFiles) file.activityId: file,
    };
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 38),
        theme: pw.ThemeData.withFont(base: font, bold: font),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${data.qualificationName} 更新申請準備資料',
                      style: const pw.TextStyle(
                        color: PdfColors.blueGrey700,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      '${context.pageNumber} / ${context.pagesCount}',
                      style: const pw.TextStyle(
                        color: PdfColors.blueGrey700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            '資格更新ノートで${_formatDateTime(data.generatedAt)}に生成。申請前に必ず認定団体の公式情報を確認してください。',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              color: PdfColors.blueGrey700,
              fontSize: 8,
            ),
          ),
        ),
        build: (context) => [
          _titleBlock(data),
          pw.SizedBox(height: 18),
          _sectionTitle('資格・申請情報'),
          _keyValueTable([
            ['認定団体', _orUnregistered(data.organization)],
            ['資格番号', _orUnregistered(data.licenseNumber)],
            ['学会会員ID', _orUnregistered(data.memberId)],
            ['資格有効期限', _orUnregistered(data.credentialDeadline)],
            ['単位算入期限', _orUnregistered(data.creditDeadline)],
            [
              '申請受付期間',
              '${_orUnregistered(data.applicationStartDate)} 〜 ${_orUnregistered(data.applicationDeadline)}',
            ],
            ['年会費', _orUnregistered(data.membershipFeeStatus)],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('進捗サマリー'),
          _summaryCards(data),
          pw.SizedBox(height: 12),
          _sectionTitle('申請準備チェック'),
          _readinessTable(data.readinessChecks),
          pw.SizedBox(height: 18),
          _sectionTitle('単位の区分別集計'),
          _categoryTable(data.activities),
          pw.SizedBox(height: 18),
          pw.NewPage(freeSpace: 150),
          _sectionTitle('更新条件の達成状況'),
          _requirementsTable(data.requirements),
          pw.SizedBox(height: 18),
          pw.NewPage(freeSpace: 150),
          _sectionTitle('実績・証憑索引'),
          _activitiesTable(
            data.activities,
            evidenceByActivity,
            unavailableEvidenceIds,
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('公式根拠'),
          _keyValueTable([
            ['資料名', _orUnregistered(data.sourceTitle)],
            ['確認日', _orUnregistered(data.sourceCheckedAt)],
            ['URL', _orUnregistered(data.sourceUrl)],
          ]),
          pw.SizedBox(height: 14),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber600, width: .7),
            ),
            child: pw.Text(
              'この資料は登録内容を申請準備用に整理したもので、認定団体が発行する申請書ではありません。単位の認定可否、必要書類、最新の申請期間は公式サイトで最終確認してください。',
              style: const pw.TextStyle(fontSize: 9, height: 1.5),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }
}

String renewalPacketBaseName(RenewalPacketData data) {
  final date = data.generatedAt;
  final stamp =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  return '${_safeFileName(data.qualificationName)}_更新申請パケット_$stamp';
}

pw.Widget _titleBlock(RenewalPacketData data) => pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(18),
  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xff152538)),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        '専門医更新・申請準備資料',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        data.qualificationName,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        data.organization,
        style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 10),
      ),
    ],
  ),
);

pw.Widget _sectionTitle(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 7),
  child: pw.Text(
    title,
    style: pw.TextStyle(
      color: PdfColors.blue900,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
);

pw.Widget _keyValueTable(List<List<String>> rows) =>
    pw.TableHelper.fromTextArray(
      headers: const ['項目', '登録内容'],
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(3.8),
      },
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: .5),
    );

pw.Widget _summaryCards(RenewalPacketData data) {
  final rawMissingEvidence =
      data.confirmedActivityCount - data.attachedEvidenceCount;
  final missingEvidence = rawMissingEvidence < 0 ? 0 : rawMissingEvidence;
  final evidenceRate = data.confirmedActivityCount == 0
      ? 0
      : (data.attachedEvidenceCount / data.confirmedActivityCount * 100)
            .round()
            .clamp(0, 100);
  final values = [
    ['確定単位', '${_number(data.currentCredits)}単位'],
    ['参加予定', '+${_number(data.plannedCredits)}単位'],
    [
      '必要総単位',
      data.requiredCredits > 0 ? '${_number(data.requiredCredits)}単位' : '未確認',
    ],
    [
      '証憑充足率',
      data.confirmedActivityCount == 0
          ? '未算定'
          : '$evidenceRate%（未添付$missingEvidence件）',
    ],
  ];
  return pw.Row(
    children: values
        .map(
          (item) => pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 5),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue100, width: .5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item[0],
                    style: const pw.TextStyle(
                      color: PdfColors.blueGrey700,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    item[1],
                    style: pw.TextStyle(
                      color: PdfColors.blue900,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

pw.Widget _readinessTable(List<RenewalPacketReadinessCheck> checks) =>
    pw.TableHelper.fromTextArray(
      headers: const ['確認項目', '状態', '内容'],
      data: checks
          .map((item) => [item.label, item.status, item.detail])
          .toList(growable: false),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(.8),
        2: pw.FlexColumnWidth(3.1),
      },
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: .5),
    );

pw.Widget _categoryTable(List<RenewalPacketActivity> activities) {
  if (activities.isEmpty) {
    return pw.Text(
      'この資格に割り当てられた確定実績はありません。',
      style: const pw.TextStyle(fontSize: 9),
    );
  }
  final totals = <String, double>{};
  for (final activity in activities) {
    totals.update(
      activity.category,
      (value) => value + activity.credits,
      ifAbsent: () => activity.credits,
    );
  }
  final rows = totals.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return pw.TableHelper.fromTextArray(
    headers: const ['単位区分', '実績数', '確定単位'],
    data: rows
        .map(
          (entry) => [
            entry.key,
            '${activities.where((item) => item.category == entry.key).length}件',
            '${_number(entry.value)}単位',
          ],
        )
        .toList(growable: false),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: .5),
  );
}

pw.Widget _requirementsTable(List<RenewalPacketRequirement> requirements) {
  if (requirements.isEmpty) {
    return pw.Text(
      '数値で追跡できる更新条件は未取得です。',
      style: const pw.TextStyle(fontSize: 9),
    );
  }
  return pw.TableHelper.fromTextArray(
    headers: const ['条件', '現在', '必要', '状態'],
    data: requirements
        .map(
          (item) => [
            item.label,
            '${_number(item.current)}${item.unit}',
            '${_number(item.requiredValue)}${item.unit}',
            item.complete ? '達成' : '未達成',
          ],
        )
        .toList(growable: false),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: .5),
  );
}

pw.Widget _activitiesTable(
  List<RenewalPacketActivity> activities,
  Map<String, RenewalPacketEvidenceFile> evidenceByActivity,
  Set<String> unavailableEvidenceIds,
) {
  if (activities.isEmpty) {
    return pw.Text(
      'この資格に割り当てられた確定実績はありません。',
      style: const pw.TextStyle(fontSize: 9),
    );
  }
  return pw.TableHelper.fromTextArray(
    headers: const ['No.', '開催日', '実績名', '区分', '単位', '認定ID', '証憑'],
    data: List.generate(activities.length, (index) {
      final item = activities[index];
      final included = evidenceByActivity[item.id];
      final evidenceStatus = included != null
          ? '同梱：${_safeFileName(included.fileName)}'
          : unavailableEvidenceIds.contains(item.id)
          ? '未同梱'
          : item.hasEvidence
          ? '添付登録済み'
          : '未添付';
      return [
        '${index + 1}',
        item.date,
        '${item.title}\n${item.organizer}',
        item.category,
        _number(item.credits),
        item.certificationId.isEmpty ? '—' : item.certificationId,
        evidenceStatus,
      ];
    }),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5),
    cellStyle: const pw.TextStyle(fontSize: 7),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    columnWidths: const {
      0: pw.FixedColumnWidth(22),
      1: pw.FlexColumnWidth(.8),
      2: pw.FlexColumnWidth(2.2),
      3: pw.FlexColumnWidth(1.1),
      4: pw.FlexColumnWidth(.55),
      5: pw.FlexColumnWidth(.9),
      6: pw.FlexColumnWidth(1.25),
    },
    border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: .5),
  );
}

String _uniqueEvidenceName(String original, int index, Set<String> usedNames) {
  final safe = _safeFileName(original);
  final numbered = '${index.toString().padLeft(3, '0')}_$safe';
  var candidate = numbered;
  var suffix = 2;
  while (!usedNames.add(candidate)) {
    candidate = '${index.toString().padLeft(3, '0')}_${suffix++}_$safe';
  }
  return candidate;
}

String _safeFileName(String value) {
  final basename = value.split(RegExp(r'[/\\]')).last.trim();
  final cleaned = basename
      .replaceAll(RegExp(r'[\x00-\x1f<>:"|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
  if (cleaned.isEmpty) return '未命名';
  return cleaned.length <= 80 ? cleaned : cleaned.substring(0, 80);
}

String _orUnregistered(String value) =>
    value.trim().isEmpty || value == '未登録' ? '未登録' : value.trim();

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _formatDateTime(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日 '
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
