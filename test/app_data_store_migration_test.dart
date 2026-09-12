import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/data/app_data_store_io.dart';
import 'package:medlicense/data/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('a device-bound database keeps its data under that account', () async {
    await _writeLegacyDatabase(accountId: 'owner-user');
    final store = SqliteAppDataStore();

    final owner = await store.load(accountId: 'owner-user');
    expect(owner.setupComplete, isTrue);
    expect(owner.displayName, '田中 太郎');
    expect(owner.qualifications.single.name, '外科専門医');
    expect(owner.qualifications.single.membershipFeeStatus, membershipFeePaid);
    expect(owner.activities.single.title, '医療安全講習会');
    expect(owner.activities.single.allocations.single.credits, 1);
    expect(owner.settings.deviceLock, isTrue);
    expect(owner.updatedAt, '2026-09-01T00:00:00.000Z');

    final other = await store.load(accountId: 'second-user');
    expect(other.setupComplete, isFalse);
    expect(other.qualifications, isEmpty);
    expect(other.activities, isEmpty);
  });

  test('two accounts can store colliding record ids side by side', () async {
    await _writeLegacyDatabase(accountId: null);
    final store = SqliteAppDataStore();

    for (final account in ['user-a', 'user-b']) {
      await store.save(
        AppSnapshot(
          accountId: account,
          setupComplete: true,
          displayName: account,
          qualifications: const [
            StoredQualification(
              id: 'qualification-1',
              name: '外科専門医',
              organization: '日本外科学会',
              licenseNumber: '',
              deadline: '2027/12/31',
            ),
          ],
        ),
      );
    }

    expect((await store.load(accountId: 'user-a')).displayName, 'user-a');
    expect((await store.load(accountId: 'user-b')).displayName, 'user-b');

    // Data created before any sign-in stays in its own slot until adopted.
    expect((await store.load()).displayName, '田中 太郎');

    await store.remove(accountId: 'user-a');
    expect((await store.load(accountId: 'user-a')).setupComplete, isFalse);
    expect((await store.load(accountId: 'user-b')).setupComplete, isTrue);
  });
}

/// Recreates the version 6 schema, where one dataset was bound to one account.
Future<void> _writeLegacyDatabase({required String? accountId}) async {
  final path = '${await getDatabasesPath()}/qualification_renewal_note.db';
  await databaseFactory.deleteDatabase(path);
  final db = await openDatabase(
    path,
    version: 6,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE profile (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          account_id TEXT,
          display_name TEXT NOT NULL,
          setup_complete INTEGER NOT NULL,
          updated_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE qualifications (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          organization TEXT NOT NULL,
          license_number TEXT NOT NULL,
          deadline TEXT NOT NULL,
          parent_qualification TEXT,
          member_id TEXT NOT NULL DEFAULT '',
          member_portal_url TEXT NOT NULL DEFAULT '',
          credit_deadline TEXT NOT NULL DEFAULT '',
          application_start_date TEXT NOT NULL DEFAULT '',
          application_deadline TEXT NOT NULL DEFAULT '',
          membership_fee_status TEXT NOT NULL DEFAULT '未確認'
        )
      ''');
      await db.execute('''
        CREATE TABLE activities (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          event_date TEXT NOT NULL,
          organizer TEXT NOT NULL,
          status TEXT NOT NULL,
          credits REAL NOT NULL,
          source TEXT NOT NULL,
          created_at TEXT NOT NULL,
          attachment_path TEXT,
          event_url TEXT NOT NULL DEFAULT '',
          certification_id TEXT NOT NULL DEFAULT '',
          notes TEXT NOT NULL DEFAULT '',
          allocations_json TEXT NOT NULL DEFAULT '[]'
        )
      ''');
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          deadline_notifications INTEGER NOT NULL,
          missing_notifications INTEGER NOT NULL,
          device_lock INTEGER NOT NULL
        )
      ''');
    },
  );
  await db.insert('profile', {
    'id': 1,
    'account_id': accountId,
    'display_name': '田中 太郎',
    'setup_complete': 1,
    'updated_at': '2026-09-01T00:00:00.000Z',
  });
  await db.insert('qualifications', {
    'id': 'qualification-1',
    'name': '外科専門医',
    'organization': '日本外科学会',
    'license_number': '1234567890',
    'deadline': '2027/12/31',
    'membership_fee_status': membershipFeePaid,
  });
  await db.insert('activities', {
    'id': 'activity-1',
    'title': '医療安全講習会',
    'event_date': '2026/08/23',
    'organizer': '県医師会',
    'status': '確定',
    'credits': 1.0,
    'source': 'カメラ撮影',
    'created_at': '2026-08-23T21:00:00.000',
    'allocations_json':
        '[{"qualificationId":"qualification-1","credits":1,"category":"医療安全講習"}]',
  });
  await db.insert('settings', {
    'id': 1,
    'deadline_notifications': 1,
    'missing_notifications': 1,
    'device_lock': 1,
  });
  await db.close();
}
