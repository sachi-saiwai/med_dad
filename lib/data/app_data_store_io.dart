import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'app_data_store.dart';
import 'app_state.dart';

AppDataStore createPlatformAppDataStore() => SqliteAppDataStore();

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
      version: 4,
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
            member_portal_url TEXT NOT NULL DEFAULT ''
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
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<AppSnapshot> load() async {
    final db = await _db;
    final profileRows = await db.query('profile', where: 'id = 1');
    final qualificationRows = await db.query('qualifications');
    final activityRows = await db.query(
      'activities',
      orderBy: 'created_at DESC',
    );
    final settingRows = await db.query('settings', where: 'id = 1');

    final profile = profileRows.firstOrNull;
    final settings = settingRows.firstOrNull;
    return AppSnapshot(
      accountId: profile?['account_id'] as String?,
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
    await db.transaction((transaction) async {
      await transaction.insert('profile', {
        'id': 1,
        'account_id': snapshot.accountId,
        'display_name': snapshot.displayName,
        'setup_complete': snapshot.setupComplete ? 1 : 0,
        'updated_at': snapshot.updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await transaction.delete('qualifications');
      for (final qualification in snapshot.qualifications) {
        await transaction.insert('qualifications', {
          'id': qualification.id,
          'name': qualification.name,
          'organization': qualification.organization,
          'license_number': qualification.licenseNumber,
          'deadline': qualification.deadline,
          'parent_qualification': qualification.parentQualification,
          'member_id': qualification.memberId,
          'member_portal_url': qualification.memberPortalUrl,
        });
      }

      await transaction.delete('activities');
      for (final activity in snapshot.activities) {
        await transaction.insert('activities', {
          'id': activity.id,
          'title': activity.title,
          'event_date': activity.date,
          'organizer': activity.organizer,
          'status': activity.status,
          'credits': activity.credits,
          'source': activity.source,
          'created_at': activity.createdAt,
          'attachment_path': activity.attachmentPath,
          'event_url': activity.eventUrl,
          'allocations_json': jsonEncode(
            activity.allocations.map((item) => item.toJson()).toList(),
          ),
        });
      }

      await transaction.insert('settings', {
        'id': 1,
        'deadline_notifications': snapshot.settings.deadlineNotifications
            ? 1
            : 0,
        'missing_notifications': snapshot.settings.missingNotifications ? 1 : 0,
        'device_lock': snapshot.settings.deviceLock ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
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
