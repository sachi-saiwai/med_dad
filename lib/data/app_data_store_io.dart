import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'app_data_store.dart';
import 'app_state.dart';

AppDataStore createPlatformAppDataStore() => SqliteAppDataStore();

const _accountScopedTables = [
  'profile',
  'settings',
  'qualifications',
  'activities',
];

class SqliteAppDataStore implements AppDataStore {
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final databasePath = path.join(
      await getDatabasesPath(),
      'qualification_renewal_note.db',
    );
    final opened = await openDatabase(
      databasePath,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profile (
            account_key TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            setup_complete INTEGER NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE qualifications (
            account_key TEXT NOT NULL,
            id TEXT NOT NULL,
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
            membership_fee_status TEXT NOT NULL DEFAULT '未確認',
            PRIMARY KEY (account_key, id)
          )
        ''');
        await db.execute('''
          CREATE TABLE activities (
            account_key TEXT NOT NULL,
            id TEXT NOT NULL,
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
            allocations_json TEXT NOT NULL DEFAULT '[]',
            PRIMARY KEY (account_key, id)
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            account_key TEXT PRIMARY KEY,
            deadline_notifications INTEGER NOT NULL,
            missing_notifications INTEGER NOT NULL,
            device_lock INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE profile ADD COLUMN account_id TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE profile ADD COLUMN updated_at TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN member_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN member_portal_url TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE activities ADD COLUMN event_url TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE activities ADD COLUMN allocations_json TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE activities ADD COLUMN certification_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE activities ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN credit_deadline TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN application_start_date TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN application_deadline TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE qualifications ADD COLUMN membership_fee_status TEXT NOT NULL DEFAULT '未確認'",
          );
        }
        if (oldVersion < 7) {
          await _migrateToPerAccountTables(db);
        }
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<AppSnapshot> load({String? accountId}) async {
    final db = await _db;
    final key = accountStorageKey(accountId);
    final profileRows = await db.query(
      'profile',
      where: 'account_key = ?',
      whereArgs: [key],
    );
    final qualificationRows = await db.query(
      'qualifications',
      where: 'account_key = ?',
      whereArgs: [key],
    );
    final activityRows = await db.query(
      'activities',
      where: 'account_key = ?',
      whereArgs: [key],
      orderBy: 'created_at DESC',
    );
    final settingRows = await db.query(
      'settings',
      where: 'account_key = ?',
      whereArgs: [key],
    );

    final profile = profileRows.firstOrNull;
    final settings = settingRows.firstOrNull;
    return AppSnapshot(
      accountId: accountId,
      setupComplete: (profile?['setup_complete'] as int? ?? 0) == 1,
      displayName: profile?['display_name'] as String? ?? '',
      qualifications: qualificationRows
          .map(
            (row) => StoredQualification(
              id: row['id']! as String,
              name: row['name']! as String,
              organization: row['organization']! as String,
              licenseNumber: row['license_number']! as String,
              deadline: row['deadline']! as String,
              parentQualification: row['parent_qualification'] as String?,
              memberId: row['member_id'] as String? ?? '',
              memberPortalUrl: row['member_portal_url'] as String? ?? '',
              creditDeadline: row['credit_deadline'] as String? ?? '',
              applicationStartDate:
                  row['application_start_date'] as String? ?? '',
              applicationDeadline: row['application_deadline'] as String? ?? '',
              membershipFeeStatus:
                  row['membership_fee_status'] as String? ??
                  membershipFeeUnconfirmed,
            ),
          )
          .toList(),
      activities: activityRows
          .map(
            (row) => StoredActivity(
              id: row['id']! as String,
              title: row['title']! as String,
              date: row['event_date']! as String,
              organizer: row['organizer']! as String,
              status: row['status']! as String,
              credits: (row['credits']! as num).toDouble(),
              source: row['source']! as String,
              createdAt: row['created_at']! as String,
              attachmentPath: row['attachment_path'] as String?,
              eventUrl: row['event_url'] as String? ?? '',
              certificationId: row['certification_id'] as String? ?? '',
              notes: row['notes'] as String? ?? '',
              allocations: _decodeAllocations(
                row['allocations_json'] as String? ?? '[]',
              ),
            ),
          )
          .toList(),
      settings: AppSettingsData(
        deadlineNotifications:
            (settings?['deadline_notifications'] as int? ?? 1) == 1,
        missingNotifications:
            (settings?['missing_notifications'] as int? ?? 1) == 1,
        deviceLock: (settings?['device_lock'] as int? ?? 0) == 1,
      ),
      updatedAt: profile?['updated_at'] as String?,
    );
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    final db = await _db;
    final key = accountStorageKey(snapshot.accountId);
    await db.transaction((transaction) async {
      await transaction.insert('profile', {
        'account_key': key,
        'display_name': snapshot.displayName,
        'setup_complete': snapshot.setupComplete ? 1 : 0,
        'updated_at': snapshot.updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await transaction.delete(
        'qualifications',
        where: 'account_key = ?',
        whereArgs: [key],
      );
      for (final qualification in snapshot.qualifications) {
        await transaction.insert('qualifications', {
          'id': qualification.id,
          'account_key': key,
          'name': qualification.name,
          'organization': qualification.organization,
          'license_number': qualification.licenseNumber,
          'deadline': qualification.deadline,
          'parent_qualification': qualification.parentQualification,
          'member_id': qualification.memberId,
          'member_portal_url': qualification.memberPortalUrl,
          'credit_deadline': qualification.creditDeadline,
          'application_start_date': qualification.applicationStartDate,
          'application_deadline': qualification.applicationDeadline,
          'membership_fee_status': qualification.membershipFeeStatus,
        });
      }

      await transaction.delete(
        'activities',
        where: 'account_key = ?',
        whereArgs: [key],
      );
      for (final activity in snapshot.activities) {
        await transaction.insert('activities', {
          'id': activity.id,
          'account_key': key,
          'title': activity.title,
          'event_date': activity.date,
          'organizer': activity.organizer,
          'status': activity.status,
          'credits': activity.credits,
          'source': activity.source,
          'created_at': activity.createdAt,
          'attachment_path': activity.attachmentPath,
          'event_url': activity.eventUrl,
          'certification_id': activity.certificationId,
          'notes': activity.notes,
          'allocations_json': jsonEncode(
            activity.allocations.map((item) => item.toJson()).toList(),
          ),
        });
      }

      await transaction.insert('settings', {
        'account_key': key,
        'deadline_notifications': snapshot.settings.deadlineNotifications
            ? 1
            : 0,
        'missing_notifications': snapshot.settings.missingNotifications ? 1 : 0,
        'device_lock': snapshot.settings.deviceLock ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> remove({String? accountId}) async {
    final db = await _db;
    final key = accountStorageKey(accountId);
    await db.transaction((transaction) async {
      for (final table in _accountScopedTables) {
        await transaction.delete(
          table,
          where: 'account_key = ?',
          whereArgs: [key],
        );
      }
    });
  }
}

/// Moves the single device-wide dataset into the slot of the account it was
/// bound to, so other accounts can keep their own data on the same device.
/// Record ids such as `qualification-1` repeat across accounts, so the tables
/// are rebuilt with `(account_key, id)` as the primary key.
Future<void> _migrateToPerAccountTables(Database db) async {
  final legacyProfile = (await db.query(
    'profile',
    where: 'id = 1',
  )).firstOrNull;
  final legacySettings = (await db.query(
    'settings',
    where: 'id = 1',
  )).firstOrNull;
  final key = (legacyProfile?['account_id'] as String?) ?? '';

  await db.execute('''
    CREATE TABLE profile_per_account (
      account_key TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      setup_complete INTEGER NOT NULL,
      updated_at TEXT
    )
  ''');
  if (legacyProfile != null) {
    await db.insert('profile_per_account', {
      'account_key': key,
      'display_name': legacyProfile['display_name'],
      'setup_complete': legacyProfile['setup_complete'],
      'updated_at': legacyProfile['updated_at'],
    });
  }

  await db.execute('''
    CREATE TABLE settings_per_account (
      account_key TEXT PRIMARY KEY,
      deadline_notifications INTEGER NOT NULL,
      missing_notifications INTEGER NOT NULL,
      device_lock INTEGER NOT NULL
    )
  ''');
  if (legacySettings != null) {
    await db.insert('settings_per_account', {
      'account_key': key,
      'deadline_notifications': legacySettings['deadline_notifications'],
      'missing_notifications': legacySettings['missing_notifications'],
      'device_lock': legacySettings['device_lock'],
    });
  }

  await db.execute('''
    CREATE TABLE qualifications_per_account (
      account_key TEXT NOT NULL,
      id TEXT NOT NULL,
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
      membership_fee_status TEXT NOT NULL DEFAULT '未確認',
      PRIMARY KEY (account_key, id)
    )
  ''');
  await db.execute(
    '''
    INSERT INTO qualifications_per_account (
      account_key, id, name, organization, license_number, deadline,
      parent_qualification, member_id, member_portal_url, credit_deadline,
      application_start_date, application_deadline, membership_fee_status
    )
    SELECT ?, id, name, organization, license_number, deadline,
      parent_qualification, member_id, member_portal_url, credit_deadline,
      application_start_date, application_deadline, membership_fee_status
    FROM qualifications
  ''',
    [key],
  );

  await db.execute('''
    CREATE TABLE activities_per_account (
      account_key TEXT NOT NULL,
      id TEXT NOT NULL,
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
      allocations_json TEXT NOT NULL DEFAULT '[]',
      PRIMARY KEY (account_key, id)
    )
  ''');
  await db.execute(
    '''
    INSERT INTO activities_per_account (
      account_key, id, title, event_date, organizer, status, credits, source,
      created_at, attachment_path, event_url, certification_id, notes,
      allocations_json
    )
    SELECT ?, id, title, event_date, organizer, status, credits, source,
      created_at, attachment_path, event_url, certification_id, notes,
      allocations_json
    FROM activities
  ''',
    [key],
  );

  for (final table in _accountScopedTables) {
    await db.execute('DROP TABLE $table');
    await db.execute('ALTER TABLE ${table}_per_account RENAME TO $table');
  }
}

List<StoredActivityAllocation> _decodeAllocations(String value) {
  try {
    return (jsonDecode(value) as List<Object?>)
        .whereType<Map>()
        .map(
          (item) => StoredActivityAllocation.fromJson(
            Map<String, Object?>.from(item),
          ),
        )
        .where((item) => item.qualificationId.isNotEmpty)
        .toList(growable: false);
  } on Object {
    return const [];
  }
}
