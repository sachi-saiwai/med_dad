import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_data_store.dart';
import 'app_state.dart';

AppDataStore createPlatformAppDataStore() => WebAppDataStore();

class WebAppDataStore implements AppDataStore {
  static const _legacyStateKey = 'medlicense.app_state.v1';
  static const _stateKeyPrefix = 'medlicense.app_state.v2.';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  Future<void>? _legacyMigration;

  @override
  Future<AppSnapshot> load({String? accountId}) async {
    await _migrateLegacyState();
    final payload = await _preferences.getString(_keyFor(accountId));
    if (payload == null || payload.isEmpty) {
      return AppSnapshot(accountId: accountId);
    }
    return AppSnapshot.fromJson(
      Map<String, Object?>.from(jsonDecode(payload) as Map),
    ).copyWith(accountId: accountId);
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    await _migrateLegacyState();
    await _preferences.setString(
      _keyFor(snapshot.accountId),
      jsonEncode(snapshot.toJson()),
    );
  }

  @override
  Future<void> remove({String? accountId}) async {
    await _migrateLegacyState();
    await _preferences.remove(_keyFor(accountId));
  }

  String _keyFor(String? accountId) =>
      '$_stateKeyPrefix${accountStorageKey(accountId)}';

  /// Moves the single device-wide dataset into the slot of the account it was
  /// bound to, so other accounts can keep their own data in this browser.
  Future<void> _migrateLegacyState() {
    return _legacyMigration ??= Future(() async {
      final payload = await _preferences.getString(_legacyStateKey);
      if (payload == null || payload.isEmpty) return;
      try {
        final snapshot = AppSnapshot.fromJson(
          Map<String, Object?>.from(jsonDecode(payload) as Map),
        );
        await _preferences.setString(
          _keyFor(snapshot.accountId),
          jsonEncode(snapshot.toJson()),
        );
      } on Object {
        // Unreadable legacy payload: drop it instead of blocking every read.
      }
      await _preferences.remove(_legacyStateKey);
    });
  }
}
