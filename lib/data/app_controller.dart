import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import 'app_data_store.dart';
import 'app_state.dart';

class AppController extends ChangeNotifier {
  AppController._(this._store, this._notifications, this._snapshot);

  final AppDataStore _store;
  final NotificationService _notifications;
  AppSnapshot _snapshot;
  bool _demoMode = false;

  AppSnapshot get snapshot => _snapshot;
  bool get isSetupComplete => _snapshot.setupComplete;
  bool get demoMode => _demoMode;

  static Future<AppController> load() async {
    final store = createAppDataStore();
    final notifications = createNotificationService();
    await notifications.initialize();
    final snapshot = await store.load();
    await notifications.rescheduleDeadlineNotifications(
      snapshot.qualifications,
      enabled: snapshot.settings.deadlineNotifications,
    );
    return AppController._(store, notifications, snapshot);
  }

  factory AppController.memory() {
    return AppController._(
      MemoryAppDataStore(),
      NoopNotificationService(),
      const AppSnapshot(),
    );
  }

  Future<void> completeSetup({
    required String displayName,
    required List<StoredQualification> qualifications,
    required bool notificationsEnabled,
  }) async {
    _demoMode = false;
    _snapshot = _snapshot.copyWith(
      setupComplete: true,
      displayName: displayName.trim(),
      qualifications: qualifications,
      settings: _snapshot.settings.copyWith(
        deadlineNotifications: notificationsEnabled,
      ),
    );
    notifyListeners();
    await _store.save(_snapshot);
    if (notificationsEnabled) await _notifications.requestPermission();
    await _notifications.rescheduleDeadlineNotifications(
      qualifications,
      enabled: notificationsEnabled,
    );
  }

  void enterDemoMode() {
    _demoMode = true;
    notifyListeners();
  }

  Future<void> addActivity(StoredActivity activity) async {
    _snapshot = _snapshot.copyWith(
      activities: [activity, ..._snapshot.activities],
    );
    notifyListeners();
    await _store.save(_snapshot);
  }

  Future<void> updateSettings(AppSettingsData settings) async {
    _snapshot = _snapshot.copyWith(settings: settings);
    notifyListeners();
    await _store.save(_snapshot);
    if (settings.deadlineNotifications) {
      await _notifications.requestPermission();
    }
    await _notifications.rescheduleDeadlineNotifications(
      _snapshot.qualifications,
      enabled: settings.deadlineNotifications,
    );
  }

  void updateSettingsUnawaited(AppSettingsData settings) {
    unawaited(updateSettings(settings));
  }
}
