import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_data_store.dart';
import 'app_state.dart';

AppDataStore createPlatformAppDataStore() => WebAppDataStore();

class WebAppDataStore implements AppDataStore {
  static const _stateKey = 'medlicense.app_state.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<AppSnapshot> load() async {
    final payload = await _preferences.getString(_stateKey);
    if (payload == null || payload.isEmpty) return const AppSnapshot();
    return AppSnapshot.fromJson(
      Map<String, Object?>.from(jsonDecode(payload) as Map),
    );
  }

  @override
  Future<void> save(AppSnapshot snapshot) {
    return _preferences.setString(_stateKey, jsonEncode(snapshot.toJson()));
  }
}
