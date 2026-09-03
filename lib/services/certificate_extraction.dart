class CertificateExtraction {
  const CertificateExtraction({
    this.title = '',
    this.date = '',
    this.organizer = '',
    this.credits,
    this.category = '',
    this.qualificationNames = const [],
    this.fieldConfidence = const {},
    this.evidence = const {},
    this.warnings = const [],
    this.extractionMethod = 'deterministic-v1',
  });

  final String title;
  final String date;
  final String organizer;
  final double? credits;
  final String category;
  final List<String> qualificationNames;
  final Map<String, double> fieldConfidence;
  final Map<String, String> evidence;
  final List<String> warnings;
  final String extractionMethod;

  bool get hasUsefulValues =>
      title.isNotEmpty ||
      date.isNotEmpty ||
      organizer.isNotEmpty ||
      credits != null ||
      category.isNotEmpty;

  double? confidenceFor(String field) => fieldConfidence[field];

  CertificateExtraction withWarning(String warning) => CertificateExtraction(
    title: title,
    date: date,
    organizer: organizer,
    credits: credits,
    category: category,
    qualificationNames: qualificationNames,
    fieldConfidence: fieldConfidence,
    evidence: evidence,
    warnings: [...warnings, warning],
    extractionMethod: extractionMethod,
  );

  factory CertificateExtraction.fromJson(Map<String, Object?> json) {
    final confidence = <String, double>{};
    for (final entry
        in ((json['fieldConfidence'] as Map?) ?? const {}).entries) {
      final value = entry.value;
      if (value is num) {
        confidence[entry.key.toString()] = value.toDouble().clamp(0.0, 1.0);
      }
    }
    final evidence = <String, String>{};
    for (final entry in ((json['evidence'] as Map?) ?? const {}).entries) {
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        evidence[entry.key.toString()] = value.trim();
      }
    }
    return CertificateExtraction(
      title: _string(json['title']),
      date: _string(json['date']),
      organizer: _string(json['organizer']),
      credits: (json['credits'] as num?)?.toDouble(),
      category: _string(json['category']),
      qualificationNames: (json['qualificationNames'] as List? ?? const [])
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      fieldConfidence: confidence,
      evidence: evidence,
      warnings: (json['warnings'] as List? ?? const [])
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      extractionMethod: _string(json['extractionMethod']).isEmpty
          ? 'deterministic-v1'
          : _string(json['extractionMethod']),
    );
  }
}

String _string(Object? value) => value is String ? value.trim() : '';

CertificateExtraction extractCertificateFields(String sourceText) {
  final text = sourceText
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'[\t\f\v\u3000]+'), ' ')
      .trim();
  final lines = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.length >= 2)
      .toList(growable: false);
  if (lines.isEmpty) {
    return const CertificateExtraction(warnings: ['文字を読み取れませんでした']);
  }

  final dateCandidate = _firstMatch(
    lines,
    RegExp(r'((?:19|20)\d{2})\s*[年/.-]\s*(\d{1,2})\s*[月/.-]\s*(\d{1,2})\s*日?'),
  );
  final date = dateCandidate == null
      ? ''
      : '${dateCandidate.match.group(1)}/${dateCandidate.match.group(2)!.padLeft(2, '0')}/${dateCandidate.match.group(3)!.padLeft(2, '0')}';

  final creditCandidate = _firstMatch(
    lines,
    RegExp(r'(\d{1,3}(?:\.\d+)?)\s*(?:単位|点|ポイント)'),
  );
  final credits = creditCandidate == null
      ? null
      : double.tryParse(creditCandidate.match.group(1)!);

  final organizerLine = lines.cast<String?>().firstWhere(
    (line) => line != null && RegExp(r'(?:主催|発行|認定)[：:]').hasMatch(line),
    orElse: () => null,
  );
  final societyLine = lines.cast<String?>().firstWhere(
    (line) =>
        line != null &&
        RegExp(
          r'(?:日本|一般社団法人|公益社団法人).{0,30}(?:学会|医師会|機構|協会|センター)',
        ).hasMatch(line),
    orElse: () => null,
  );
  final organizerSource = organizerLine ?? societyLine ?? '';
  final organizer = organizerSource
      .replaceFirst(RegExp(r'^.*?(?:主催|発行|認定)[：:]\s*'), '')
      .trim();

  final categorySource =
      lines.cast<String?>().firstWhere(
        (line) =>
            line != null &&
            RegExp(
              r'共通講習|領域講習|医療安全講習|感染対策講習|医療倫理講習|学術集会参加|研修単位',
            ).hasMatch(line),
        orElse: () => null,
      ) ??
      lines.cast<String?>().firstWhere(
        (line) =>
            line != null && RegExp(r'医療安全|感染対策|医療倫理').hasMatch(line),
        orElse: () => null,
      );
  final category = categorySource == null
      ? ''
      : RegExp(
              r'共通講習|領域講習|医療安全講習|医療安全|感染対策講習|感染対策|医療倫理講習|医療倫理|学術集会参加|研修単位',
            ).firstMatch(categorySource)?.group(0) ??
            '';

  final excludedTitle = RegExp(r'受講証明書|参加証|修了証|認定証|氏名|所属|開催日|主催|発行|取得単位');
  final title =
      lines.cast<String?>().firstWhere(
        (line) =>
            line != null &&
            line.length <= 100 &&
            !excludedTitle.hasMatch(line) &&
            RegExp(r'研修|講習|学術|セミナー|フォーラム|大会|カンファレンス').hasMatch(line),
        orElse: () => null,
      ) ??
      '';

  final confidence = <String, double>{};
  final evidence = <String, String>{};
  void record(String field, String value, String source, double score) {
    if (value.isEmpty) return;
    confidence[field] = score;
    evidence[field] = source;
  }

  record('title', title, title, 0.68);
  record('date', date, dateCandidate?.line ?? '', 0.88);
  record(
    'organizer',
    organizer,
    organizerSource,
    organizerLine == null ? 0.65 : 0.82,
  );
  if (credits != null) {
    confidence['credits'] = 0.82;
    evidence['credits'] = creditCandidate!.line;
  }
  record('category', category, categorySource ?? '', 0.68);

  final warnings = <String>[
    if (title.isEmpty) '研修会・イベント名を自動判定できませんでした',
    if (date.isEmpty) '開催日を自動判定できませんでした',
    if (credits == null) '取得単位を自動判定できませんでした',
  ];
  return CertificateExtraction(
    title: title,
    date: date,
    organizer: organizer,
    credits: credits,
    category: category,
    fieldConfidence: confidence,
    evidence: evidence,
    warnings: warnings,
  );
}

({String line, RegExpMatch match})? _firstMatch(
  List<String> lines,
  RegExp expression,
) {
  for (final line in lines) {
    final match = expression.firstMatch(line);
    if (match != null) return (line: line, match: match);
  }
  return null;
}
