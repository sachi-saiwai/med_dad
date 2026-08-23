class StoredQualification {
  const StoredQualification({
    required this.id,
    required this.name,
    required this.organization,
    required this.licenseNumber,
    required this.deadline,
    this.parentQualification,
  });

  final String id;
  final String name;
  final String organization;
  final String licenseNumber;
  final String deadline;
  final String? parentQualification;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'organization': organization,
    'licenseNumber': licenseNumber,
    'deadline': deadline,
    'parentQualification': parentQualification,
  };

  factory StoredQualification.fromJson(Map<String, Object?> json) {
    return StoredQualification(
      id: json['id']! as String,
      name: json['name']! as String,
      organization: json['organization']! as String,
      licenseNumber: (json['licenseNumber'] as String?) ?? '',
      deadline: (json['deadline'] as String?) ?? '',
      parentQualification: json['parentQualification'] as String?,
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
    this.setupComplete = false,
    this.displayName = '',
    this.qualifications = const [],
    this.activities = const [],
    this.settings = const AppSettingsData(),
  });

  final bool setupComplete;
  final String displayName;
  final List<StoredQualification> qualifications;
  final List<StoredActivity> activities;
  final AppSettingsData settings;

  AppSnapshot copyWith({
    bool? setupComplete,
    String? displayName,
    List<StoredQualification>? qualifications,
    List<StoredActivity>? activities,
    AppSettingsData? settings,
  }) {
    return AppSnapshot(
      setupComplete: setupComplete ?? this.setupComplete,
      displayName: displayName ?? this.displayName,
      qualifications: qualifications ?? this.qualifications,
      activities: activities ?? this.activities,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() => {
    'setupComplete': setupComplete,
    'displayName': displayName,
    'qualifications': qualifications.map((item) => item.toJson()).toList(),
    'activities': activities.map((item) => item.toJson()).toList(),
    'settings': settings.toJson(),
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
      setupComplete: (json['setupComplete'] as bool?) ?? false,
      displayName: (json['displayName'] as String?) ?? '',
      qualifications: qualifications,
      activities: activities,
      settings: AppSettingsData.fromJson(settingsJson),
    );
  }
}
