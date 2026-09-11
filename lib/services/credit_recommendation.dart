class CreditRequirementTarget {
  const CreditRequirementTarget({
    required this.label,
    this.unit = '単位',
    this.evidence,
    this.mandatory = false,
  });

  final String label;
  final String unit;
  final String? evidence;
  final bool mandatory;
}

class QualificationRequirementSource {
  const QualificationRequirementSource({
    required this.id,
    required this.name,
    required this.organization,
    required this.requirements,
  });

  final String id;
  final String name;
  final String organization;
  final List<CreditRequirementTarget> requirements;
}

class CreditRecommendation {
  const CreditRecommendation({
    required this.qualificationId,
    required this.qualificationName,
    required this.category,
    required this.reason,
    required this.score,
    this.suggestedCredits,
    this.unit = '単位',
  });

  final String qualificationId;
  final String qualificationName;
  final String category;
  final String reason;
  final int score;
  final double? suggestedCredits;
  final String unit;
}

final _skipLabels = RegExp(r'総単位|更新単位|手術経験|診療経験|症例|論文|著書|研究業績');

final _attendanceHints = RegExp(
  r'講習|研修|学術|集会|総会|大会|地方会|セミナー|フォーラム|eラーニング|e-learning|講座',
);

final _keywordGroups = <List<String>>[
  ['医療安全', '安全講習'],
  ['感染対策', '感染防止', '感染症'],
  ['医療倫理', '倫理講習'],
  ['共通講習'],
  ['領域講習', '専門講習', '外科領域'],
  ['指導医'],
  ['教育講座', 'eラーニング', 'elearning'],
  ['学術集会', '定期学術集会', '総会', '大会'],
  ['地方会'],
  ['セミナー', 'postgraduate'],
];

String normalizeCreditText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s　・･（）()/／ー_-]'), '');
}

List<CreditRecommendation> recommendCreditAllocations({
  required String title,
  required String organizer,
  String extractedCategory = '',
  double? extractedCredits,
  required List<QualificationRequirementSource> sources,
  int limit = 4,
}) {
  final eventText = normalizeCreditText('$title $organizer $extractedCategory');
  if (eventText.isEmpty || sources.isEmpty) return const [];

  final recommendations = <CreditRecommendation>[];
  for (final source in sources) {
    for (final requirement in source.requirements) {
      final scored = _scoreRequirement(
        source: source,
        requirement: requirement,
        title: title,
        organizer: organizer,
        extractedCategory: extractedCategory,
        extractedCredits: extractedCredits,
        eventText: eventText,
      );
      if (scored != null) recommendations.add(scored);
    }
  }
  recommendations.sort((a, b) => b.score.compareTo(a.score));
  final unique = <String, CreditRecommendation>{};
  for (final item in recommendations) {
    unique.putIfAbsent(
      '${item.qualificationId}:${normalizeCreditText(item.category)}',
      () => item,
    );
  }
  return unique.values.take(limit).toList(growable: false);
}

CreditRecommendation? _scoreRequirement({
  required QualificationRequirementSource source,
  required CreditRequirementTarget requirement,
  required String title,
  required String organizer,
  required String extractedCategory,
  required double? extractedCredits,
  required String eventText,
}) {
  final label = requirement.label.trim();
  if (label.isEmpty || _skipLabels.hasMatch(label)) return null;

  final normalizedLabel = normalizeCreditText(label);
  final normalizedTitle = normalizeCreditText(title);
  final normalizedOrganizer = normalizeCreditText(organizer);
  final normalizedCategory = normalizeCreditText(extractedCategory);
  final normalizedOrg = normalizeCreditText(source.organization);
  if (normalizedLabel.isEmpty) return null;

  var score = 0;
  final reasons = <String>[];

  if (normalizedTitle.contains(normalizedLabel) ||
      normalizedLabel.contains(normalizedTitle) &&
          normalizedTitle.length >= 6) {
    score += 55;
    reasons.add('イベント名が要項の「$label」と一致');
  } else if (_sharesKeywordGroup(normalizedTitle, normalizedLabel) ||
      _sharesKeywordGroup(eventText, normalizedLabel)) {
    score += 38;
    reasons.add('イベント内容が要項の「$label」に該当');
  } else if (normalizedLabel.length >= 6 &&
      eventText.contains(normalizedLabel.substring(0, 6))) {
    score += 24;
    reasons.add('イベント名が要項区分と部分一致');
  }

  if (normalizedCategory.isNotEmpty &&
      (normalizedCategory == normalizedLabel ||
          normalizedLabel.contains(normalizedCategory) ||
          normalizedCategory.contains(normalizedLabel))) {
    score += 28;
    reasons.add('参加証の単位区分が要項と一致');
  }

  final society = _societyName(label) ?? _societyName(source.organization);
  if (society != null &&
      (normalizedTitle.contains(society) ||
          normalizedOrganizer.contains(society))) {
    score += 22;
    reasons.add('${source.name}の公式行事として照合');
  } else if (normalizedOrg.isNotEmpty &&
      (normalizedTitle.contains(normalizedOrg) ||
          normalizedOrganizer.contains(normalizedOrg))) {
    score += 12;
    reasons.add('主催者が${source.name}の認定団体と一致');
  }

  if (requirement.mandatory) score += 4;

  if (score < 24) return null;
  if (!_attendanceHints.hasMatch(title) &&
      !_attendanceHints.hasMatch(extractedCategory) &&
      score < 50) {
    return null;
  }

  return CreditRecommendation(
    qualificationId: source.id,
    qualificationName: source.name,
    category: label,
    reason: reasons.isEmpty ? '公式要項の区分候補です' : reasons.join(' / '),
    score: score,
    suggestedCredits: extractedCredits ?? _creditsFromEvidence(requirement),
    unit: requirement.unit,
  );
}

bool _sharesKeywordGroup(String left, String right) {
  for (final group in _keywordGroups) {
    final normalized = group.map(normalizeCreditText).toList(growable: false);
    final leftHit = normalized.any(left.contains);
    final rightHit = normalized.any(right.contains);
    if (leftHit && rightHit) return true;
  }
  return false;
}

String? _societyName(String value) {
  final match = RegExp(r'日本.{2,16}学会').firstMatch(value);
  return match == null ? null : normalizeCreditText(match.group(0)!);
}

double? _creditsFromEvidence(CreditRequirementTarget requirement) {
  final evidence = requirement.evidence ?? '';
  final match = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*単位').firstMatch(evidence);
  if (match != null) return double.tryParse(match.group(1)!);
  if (requirement.unit == '回') return 1;
  return null;
}
