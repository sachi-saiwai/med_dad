import 'app_state.dart';
import 'app_data_store_stub.dart'
    if (dart.library.io) 'app_data_store_io.dart'
    if (dart.library.js_interop) 'app_data_store_web.dart'
    as platform;

abstract interface class AppDataStore {
  Future<AppSnapshot> load();

  Future<void> save(AppSnapshot snapshot);
}

AppDataStore createAppDataStore() => platform.createPlatformAppDataStore();

class MemoryAppDataStore implements AppDataStore {
  MemoryAppDataStore([this._snapshot = const AppSnapshot()]);

  AppSnapshot _snapshot;

  @override
  Future<AppSnapshot> load() async => _snapshot;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
