import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_state.dart';
import 'notification_service.dart';

NotificationService createPlatformNotificationService() =>
    LocalNotificationService();

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } on Object {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
  }

  @override
  Future<bool> requestPermission() async {
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
  }

  @override
  Future<void> rescheduleDeadlineNotifications(
    List<StoredQualification> qualifications, {
    required bool enabled,
  }) async {
    await _plugin.cancelAll();
    if (!enabled) return;

    const reminderDays = [365, 180, 90, 30, 7];
    final now = tz.TZDateTime.now(tz.local);
    for (final qualification in qualifications) {
      final deadline = _parseDeadline(qualification.deadline);
      if (deadline == null) continue;
      for (final days in reminderDays) {
        final scheduled = tz.TZDateTime(
          tz.local,
          deadline.year,
          deadline.month,
          deadline.day,
          9,
        ).subtract(Duration(days: days));
        if (!scheduled.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: _notificationId(qualification.id, days),
          title: '${qualification.name}の更新期限',
          body: '更新期限まであと$days日です。必要な単位と講習を確認してください。',
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'qualification_deadlines',
              '資格の更新期限',
              channelDescription: '専門医資格の更新期限をお知らせします',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              threadIdentifier: 'qualification_deadlines',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: qualification.id,
        );
      }
    }
  }

  DateTime? _parseDeadline(String value) {
    final normalized = value
        .trim()
        .replaceAll('年', '/')
        .replaceAll('月', '/')
        .replaceAll('日', '');
    final parts = normalized.split('/');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  int _notificationId(String id, int days) {
    var hash = 0x811c9dc5;
    for (final unit in '$id:$days'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
