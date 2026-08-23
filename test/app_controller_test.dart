import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/data/app_controller.dart';
import 'package:medlicense/data/app_state.dart';

void main() {
  test('setup, activities, and settings update the app state', () async {
    final controller = AppController.memory();
    const qualification = StoredQualification(
      id: 'qualification-1',
      name: '外科専門医',
      organization: '日本専門医機構／日本外科学会',
      licenseNumber: '1234567890',
      deadline: '2027/12/31',
    );

    await controller.completeSetup(
      displayName: '田中 太郎',
      qualifications: const [qualification],
      notificationsEnabled: true,
    );

    expect(controller.isSetupComplete, isTrue);
    expect(controller.snapshot.displayName, '田中 太郎');
    expect(controller.snapshot.qualifications.single.name, '外科専門医');

    const activity = StoredActivity(
      id: 'activity-1',
      title: '医療安全講習会',
      date: '2026/08/23',
      organizer: '県医師会',
      status: '確定',
      credits: 1,
      source: 'カメラ撮影',
      createdAt: '2026-08-23T21:00:00.000',
      attachmentPath: '/documents/certificates/example.jpg',
    );
    await controller.addActivity(activity);

    expect(controller.snapshot.activities.single.title, '医療安全講習会');
    expect(controller.snapshot.activities.single.attachmentPath, isNotNull);

    await controller.updateSettings(
      const AppSettingsData(
        deadlineNotifications: false,
        missingNotifications: false,
        deviceLock: true,
      ),
    );

    expect(controller.snapshot.settings.deadlineNotifications, isFalse);
    expect(controller.snapshot.settings.deviceLock, isTrue);
  });
}
