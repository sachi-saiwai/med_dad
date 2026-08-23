import '../data/app_state.dart';
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_io.dart'
    as platform;

abstract interface class NotificationService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> rescheduleDeadlineNotifications(
    List<StoredQualification> qualifications, {
    required bool enabled,
  });
}

NotificationService createNotificationService() =>
    platform.createPlatformNotificationService();

class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> rescheduleDeadlineNotifications(
    List<StoredQualification> qualifications, {
    required bool enabled,
  }) async {}
}
