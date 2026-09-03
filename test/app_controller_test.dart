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
      memberId: 'JSS-24680',
      memberPortalUrl: 'https://example.jp/member',
    );

    expect(await controller.bindToAccount('firebase-user-1'), isTrue);
    expect(controller.snapshot.accountId, 'firebase-user-1');
    expect(await controller.bindToAccount('firebase-user-2'), isFalse);

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
      allocations: [
        StoredActivityAllocation(
          qualificationId: 'qualification-1',
          credits: 1,
          category: '医療安全講習',
        ),
      ],
    );
    await controller.addActivity(activity);

    const plannedActivity = StoredActivity(
      id: 'activity-2',
      title: '日本外科学会定期学術集会',
      date: '2027/04/08',
      organizer: '日本外科学会',
      status: '参加予定',
      credits: 5,
      source: '参加予定',
      createdAt: '2026-09-02T12:00:00.000',
      eventUrl: 'https://example.jp/congress',
      allocations: [
        StoredActivityAllocation(
          qualificationId: 'qualification-1',
          credits: 5,
          category: '学術集会参加',
        ),
      ],
    );
    await controller.addActivity(plannedActivity);

    expect(controller.snapshot.activities, hasLength(2));
    expect(controller.snapshot.activities.last.attachmentPath, isNotNull);
    final points = controller.snapshot.pointsForQualification(
      'qualification-1',
    );
    expect(points.current, 1);
    expect(points.planned, 5);
    expect(points.projected, 6);
    expect(points.currentByCategory['医療安全講習'], 1);
    expect(points.plannedByCategory['学術集会参加'], 5);

    await controller.updateActivity(plannedActivity.copyWith(status: '確定'));
    final confirmedPoints = controller.snapshot.pointsForQualification(
      'qualification-1',
    );
    expect(confirmedPoints.current, 6);
    expect(confirmedPoints.planned, 0);

    final restored = AppSnapshot.fromJson(controller.snapshot.toJson());
    expect(restored.qualifications.single.memberId, 'JSS-24680');
    expect(
      restored.qualifications.single.memberPortalUrl,
      'https://example.jp/member',
    );
    expect(restored.activities.first.allocations.single.credits, 5);

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

  test('old activities are attributed only when one qualification exists', () {
    const activity = StoredActivity(
      id: 'old-activity',
      title: '旧形式の講習',
      date: '2025/01/01',
      organizer: '学会',
      status: '確定',
      credits: 3,
      source: '手入力',
      createdAt: '2025-01-01T00:00:00.000',
    );
    const qualification = StoredQualification(
      id: 'qualification-1',
      name: '外科専門医',
      organization: '日本外科学会',
      licenseNumber: '',
      deadline: '',
    );

    const single = AppSnapshot(
      qualifications: [qualification],
      activities: [activity],
    );
    expect(single.pointsForQualification('qualification-1').current, 3);

    const multiple = AppSnapshot(
      qualifications: [
        qualification,
        StoredQualification(
          id: 'qualification-2',
          name: '消化器外科専門医',
          organization: '日本消化器外科学会',
          licenseNumber: '',
          deadline: '',
        ),
      ],
      activities: [activity],
    );
    expect(multiple.pointsForQualification('qualification-1').current, 0);
  });
}
