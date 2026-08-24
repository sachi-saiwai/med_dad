import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OfficialRequirement {
  const OfficialRequirement({
    required this.label,
    required this.unit,
    required this.mandatory,
    this.minimum,
    this.maximum,
    this.requiredValue,
    this.evidence,
  });

  final String label;
  final String unit;
  final bool mandatory;
  final double? minimum;
  final double? maximum;
  final double? requiredValue;
  final String? evidence;

  double? get trackingTarget => minimum ?? requiredValue;

  factory OfficialRequirement.fromJson(Map<String, Object?> json) {
    return OfficialRequirement(
      label: (json['label'] as String?)?.trim() ?? '更新条件',
      unit: (json['unit'] as String?)?.trim() ?? '単位',
      mandatory: json['mandatory'] == true,
      minimum: (json['minimum'] as num?)?.toDouble(),
      maximum: (json['maximum'] as num?)?.toDouble(),
      requiredValue: (json['requiredValue'] as num?)?.toDouble(),
      evidence: json['evidence'] as String?,
    );
  }
}

class OfficialRuleSource {
  const OfficialRuleSource({
    required this.title,
    required this.url,
    required this.checkedAt,
  });

  final String title;
  final String url;
  final DateTime? checkedAt;
}

class OfficialRenewalRule {
  const OfficialRenewalRule({
    required this.id,
    required this.systemType,
    required this.requirements,
    required this.mandatoryNotes,
    required this.otherConditions,
    required this.source,
    this.acquiredYearFrom,
    this.acquiredYearTo,
    this.renewalYearFrom,
    this.renewalYearTo,
    this.renewalCycleYears,
    this.requiredTotalCredits,
  });

  final int id;
  final String systemType;
  final int? acquiredYearFrom;
  final int? acquiredYearTo;
  final int? renewalYearFrom;
  final int? renewalYearTo;
  final double? renewalCycleYears;
  final double? requiredTotalCredits;
  final List<OfficialRequirement> requirements;
  final List<String> mandatoryNotes;
  final List<String> otherConditions;
  final OfficialRuleSource source;
}

class OfficialRuleLookup {
  const OfficialRuleLookup({required this.qualificationFound, this.rule});

  final bool qualificationFound;
  final OfficialRenewalRule? rule;
}

typedef OfficialRuleLoader =
    Future<OfficialRuleLookup> Function(String qualificationName);

class OfficialRuleService {
  const OfficialRuleService();

  static const productionOrigin = 'https://med-dad.vercel.app';

  Uri _endpoint(String qualificationName, {int? renewalYear}) {
    final sameOrigin =
        kIsWeb &&
        (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') &&
        Uri.base.host.isNotEmpty &&
        Uri.base.host != 'localhost' &&
        Uri.base.host != '127.0.0.1';
    final base = sameOrigin ? Uri.base : Uri.parse(productionOrigin);
    return base
        .resolve('/api/v1/qualifications')
        .replace(
          queryParameters: {
            'q': qualificationName,
            'limit': '20',
            if (renewalYear != null) 'renewalYear': '$renewalYear',
          },
        );
  }

  Future<OfficialRuleLookup> fetchForQualification(
    String qualificationName, {
    int? renewalYear,
  }) async {
    final response = await http
        .get(
          _endpoint(qualificationName, renewalYear: renewalYear),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('更新条件APIから応答を取得できませんでした（${response.statusCode}）');
    }
    final payload = jsonDecode(response.body) as Map<String, Object?>;
    final entries = (payload['data'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
    final exact = entries
        .where((entry) => entry['name'] == qualificationName)
        .firstOrNull;
    if (exact == null) {
      return const OfficialRuleLookup(qualificationFound: false);
    }
    final rawRule = exact['renewalRule'];
    if (rawRule is! Map) {
      return const OfficialRuleLookup(qualificationFound: true);
    }
    return OfficialRuleLookup(
      qualificationFound: true,
      rule: _parseRule(Map<String, Object?>.from(rawRule)),
    );
  }

  OfficialRenewalRule _parseRule(Map<String, Object?> json) {
    final details = Map<String, Object?>.from(
      (json['details'] as Map?) ?? const <String, Object?>{},
    );
    final source = Map<String, Object?>.from(
      (json['source'] as Map?) ?? const <String, Object?>{},
    );
    final sourceUrl = (source['url'] as String?)?.trim() ?? '';
    if (!sourceUrl.startsWith('https://') && !sourceUrl.startsWith('http://')) {
      throw const FormatException('公式資料のURLが不正です');
    }
    return OfficialRenewalRule(
      id: (json['id'] as num).toInt(),
      systemType: (json['systemType'] as String?)?.trim() ?? '制度区分未指定',
      acquiredYearFrom: (json['acquiredYearFrom'] as num?)?.toInt(),
      acquiredYearTo: (json['acquiredYearTo'] as num?)?.toInt(),
      renewalYearFrom: (json['renewalYearFrom'] as num?)?.toInt(),
      renewalYearTo: (json['renewalYearTo'] as num?)?.toInt(),
      renewalCycleYears: (json['renewalCycleYears'] as num?)?.toDouble(),
      requiredTotalCredits: (json['requiredTotalCredits'] as num?)?.toDouble(),
      requirements: (details['requirements'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                OfficialRequirement.fromJson(Map<String, Object?>.from(item)),
          )
          .toList(growable: false),
      mandatoryNotes: _stringList(details['mandatoryNotes']),
      otherConditions: _stringList(details['otherConditions']),
      source: OfficialRuleSource(
        title: (source['title'] as String?)?.trim() ?? '認定団体の公式資料',
        url: sourceUrl,
        checkedAt: DateTime.tryParse((source['checkedAt'] as String?) ?? ''),
      ),
    );
  }

  List<String> _stringList(Object? value) {
    return (value as List<Object?>? ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
