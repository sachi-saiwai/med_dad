import 'app_state.dart';
import 'app_data_store_stub.dart'
    if (dart.library.io) 'app_data_store_io.dart'
    if (dart.library.js_interop) 'app_data_store_web.dart'
    as platform;

/// Local data is stored per account. The empty key holds data created before
/// any sign-in, so several accounts can share one device.
String accountStorageKey(String? accountId) => accountId ?? '';

abstract interface class AppDataStore {
  Future<AppSnapshot> load({String? accountId});

  Future<void> save(AppSnapshot snapshot);

  Future<void> remove({String? accountId});
}

AppDataStore createAppDataStore() => platform.createPlatformAppDataStore();

class MemoryAppDataStore implements AppDataStore {
  MemoryAppDataStore([AppSnapshot snapshot = const AppSnapshot()])
    : _snapshots = {accountStorageKey(snapshot.accountId): snapshot};

  final Map<String, AppSnapshot> _snapshots;

  @override
  Future<AppSnapshot> load({String? accountId}) async =>
      _snapshots[accountStorageKey(accountId)] ??
      AppSnapshot(accountId: accountId);

  @override
  Future<void> save(AppSnapshot snapshot) async {
    _snapshots[accountStorageKey(snapshot.accountId)] = snapshot;
  }

  @override
  Future<void> remove({String? accountId}) async {
    _snapshots.remove(accountStorageKey(accountId));
  }
}
