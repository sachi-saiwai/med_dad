class StoredQualification {
  const StoredQualification({
    required this.id,
    required this.name,
    required this.organization,
    required this.licenseNumber,
    required this.deadline,
    this.parentQualification,
    this.memberId = '',
    this.memberPortalUrl = '',
  });

  final String id;
  final String name;
  final String organization;
  final String licenseNumber;
  final String deadline;
  final String? parentQualification;
  final String memberId;
  final String memberPortalUrl;

  StoredQualification copyWith({
    String? name,
    String? organization,
    String? licenseNumber,
    String? deadline,
    String? parentQualification,
    String? memberId,
    String? memberPortalUrl,
  }) {
    return StoredQualification(
      id: id,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      deadline: deadline ?? this.deadline,
      parentQualification: parentQualification ?? this.parentQualification,
      memberId: memberId ?? this.memberId,
      memberPortalUrl: memberPortalUrl ?? this.memberPortalUrl,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'organization': organization,
    'licenseNumber': licenseNumber,
    'deadline': deadline,
    'parentQualification': parentQualification,
    'memberId': memberId,
    'memberPortalUrl': memberPortalUrl,
  };

  factory StoredQualification.fromJson(Map<String, Object?> json) {
    return StoredQualification(
      id: json['id']! as String,
      name: json['name']! as String,
      organization: json['organization']! as String,
      licenseNumber: (json['licenseNumber'] as String?) ?? '',
      deadline: (json['deadline'] as String?) ?? '',
      parentQualification: json['parentQualification'] as String?,
      memberId: (json['memberId'] as String?) ?? '',
      memberPortalUrl: (json['memberPortalUrl'] as String?) ?? '',
    );
  }
}

class StoredActivityAllocation {
  const StoredActivityAllocation({
    required this.qualificationId,
    required this.credits,
    this.category = '未分類',
  });

  final String qualificationId;
  final double credits;
  final String category;

  Map<String, Object?> toJson() => {
    'qualificationId': qualificationId,
    'credits': credits,
    'category': category,
  };

  factory StoredActivityAllocation.fromJson(Map<String, Object?> json) {
    return StoredActivityAllocation(
      qualificationId: (json['qualificationId'] as String?) ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? 0,
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : '未分類',
    );
  }
}

class StoredActivity {
  const StoredActivity({
    required this.id,
    required this.title,
    required this.date,
    required this.organizer,
    required this.status,
    required this.credits,
    required this.source,
    required this.createdAt,
    this.attachmentPath,
    this.eventUrl = '',
    this.allocations = const [],
  });

  final String id;
  final String title;
  final String date;
  final String organizer;
  final String status;
  final double credits;
  final String source;
  final String createdAt;
  final String? attachmentPath;
  final String eventUrl;
  final List<StoredActivityAllocation> allocations;

  StoredActivity copyWith({
    String? title,
    String? date,
    String? organizer,
    String? status,
    double? credits,
    String? source,
    String? createdAt,
    String? attachmentPath,
    String? eventUrl,
    List<StoredActivityAllocation>? allocations,
  }) {
    return StoredActivity(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      organizer: organizer ?? this.organizer,
      status: status ?? this.status,
      credits: credits ?? this.credits,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      eventUrl: eventUrl ?? this.eventUrl,
      allocations: allocations ?? this.allocations,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'organizer': organizer,
    'status': status,
    'credits': credits,
    'source': source,
    'createdAt': createdAt,
    'attachmentPath': attachmentPath,
    'eventUrl': eventUrl,
    'allocations': allocations.map((item) => item.toJson()).toList(),
  };

  factory StoredActivity.fromJson(Map<String, Object?> json) {
    return StoredActivity(
      id: json['id']! as String,
      title: json['title']! as String,
      date: json['date']! as String,
      organizer: json['organizer']! as String,
      status: json['status']! as String,
      credits: (json['credits'] as num?)?.toDouble() ?? 0,
      source: (json['source'] as String?) ?? '手入力',
      createdAt:
          (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      attachmentPath: json['attachmentPath'] as String?,
      eventUrl: (json['eventUrl'] as String?) ?? '',
      allocations: (json['allocations'] as List<Object?>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => StoredActivityAllocation.fromJson(
              Map<String, Object?>.from(item),
            ),
          )
          .where((item) => item.qualificationId.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class AppSettingsData {
  const AppSettingsData({
    this.deadlineNotifications = true,
    this.missingNotifications = true,
    this.deviceLock = false,
  });

  final bool deadlineNotifications;
  final bool missingNotifications;
  final bool deviceLock;

  AppSettingsData copyWith({
    bool? deadlineNotifications,
    bool? missingNotifications,
    bool? deviceLock,
  }) {
    return AppSettingsData(
      deadlineNotifications:
          deadlineNotifications ?? this.deadlineNotifications,
      missingNotifications: missingNotifications ?? this.missingNotifications,
      deviceLock: deviceLock ?? this.deviceLock,
    );
  }

  Map<String, Object?> toJson() => {
    'deadlineNotifications': deadlineNotifications,
    'missingNotifications': missingNotifications,
    'deviceLock': deviceLock,
  };

  factory AppSettingsData.fromJson(Map<String, Object?> json) {
    return AppSettingsData(
      deadlineNotifications: (json['deadlineNotifications'] as bool?) ?? true,
      missingNotifications: (json['missingNotifications'] as bool?) ?? true,
      deviceLock: (json['deviceLock'] as bool?) ?? false,
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    this.accountId,
    this.setupComplete = false,
    this.displayName = '',
    this.qualifications = const [],
    this.activities = const [],
    this.settings = const AppSettingsData(),
    this.updatedAt,
  });

  final String? accountId;
  final bool setupComplete;
  final String displayName;
  final List<StoredQualification> qualifications;
  final List<StoredActivity> activities;
  final AppSettingsData settings;
  final String? updatedAt;

  AppSnapshot copyWith({
    String? accountId,
    bool? setupComplete,
    String? displayName,
    List<StoredQualification>? qualifications,
    List<StoredActivity>? activities,
    AppSettingsData? settings,
    String? updatedAt,
  }) {
    return AppSnapshot(
      accountId: accountId ?? this.accountId,
      setupComplete: setupComplete ?? this.setupComplete,
      displayName: displayName ?? this.displayName,
      qualifications: qualifications ?? this.qualifications,
      activities: activities ?? this.activities,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'accountId': accountId,
    'setupComplete': setupComplete,
    'displayName': displayName,
    'qualifications': qualifications.map((item) => item.toJson()).toList(),
    'activities': activities.map((item) => item.toJson()).toList(),
    'settings': settings.toJson(),
    'updatedAt': updatedAt,
  };

  factory AppSnapshot.fromJson(Map<String, Object?> json) {
    final qualifications =
        (json['qualifications'] as List<Object?>? ?? const [])
            .map(
              (item) => StoredQualification.fromJson(
                Map<String, Object?>.from(item! as Map),
              ),
            )
            .toList();
    final activities = (json['activities'] as List<Object?>? ?? const [])
        .map(
          (item) =>
              StoredActivity.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList();
    final settingsJson = Map<String, Object?>.from(
      (json['settings'] as Map?) ?? const <String, Object?>{},
    );
    return AppSnapshot(
      accountId: json['accountId'] as String?,
      setupComplete: (json['setupComplete'] as bool?) ?? false,
      displayName: (json['displayName'] as String?) ?? '',
      qualifications: qualifications,
      activities: activities,
      settings: AppSettingsData.fromJson(settingsJson),
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class QualificationPointSummary {
  const QualificationPointSummary({
    required this.current,
    required this.planned,
    required this.currentByCategory,
    required this.plannedByCategory,
  });

  final double current;
  final double planned;
  final Map<String, double> currentByCategory;
  final Map<String, double> plannedByCategory;

  double get projected => current + planned;
}

extension AppSnapshotPointSummaries on AppSnapshot {
  QualificationPointSummary pointsForQualification(String qualificationId) {
    var current = 0.0;
    var planned = 0.0;
    final currentByCategory = <String, double>{};
    final plannedByCategory = <String, double>{};

    for (final activity in activities) {
      final isConfirmed = activity.status == '確定';
      final isPlanned = activity.status == '参加予定';
      if (!isConfirmed && !isPlanned) continue;

      var allocations = activity.allocations;
      if (allocations.isEmpty && qualifications.length == 1) {
        allocations = [
          StoredActivityAllocation(
            qualificationId: qualifications.single.id,
            credits: activity.credits,
          ),
        ];
      }

      for (final allocation in allocations) {
        if (allocation.qualificationId != qualificationId ||
            allocation.credits <= 0) {
          continue;
        }
        final category = allocation.category.trim().isEmpty
            ? '未分類'
            : allocation.category.trim();
        if (isPlanned) {
          planned += allocation.credits;
          plannedByCategory.update(
            category,
            (value) => value + allocation.credits,
            ifAbsent: () => allocation.credits,
          );
        } else {
          current += allocation.credits;
          currentByCategory.update(
            category,
            (value) => value + allocation.credits,
            ifAbsent: () => allocation.credits,
          );
        }
      }
    }

    return QualificationPointSummary(
      current: current,
      planned: planned,
      currentByCategory: Map.unmodifiable(currentByCategory),
      plannedByCategory: Map.unmodifiable(plannedByCategory),
    );
  }
}
