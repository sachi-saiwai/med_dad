import 'web_push_service_stub.dart'
    if (dart.library.js_interop) 'web_push_service_web.dart'
    as platform;

abstract interface class WebPushService {
  bool get isSupported;

  Future<Map<String, Object?>> subscribe(String applicationServerKey);

  Future<bool> requestPersistentStorage();
}

WebPushService createWebPushService() =>
    platform.createPlatformWebPushService();

class UnsupportedWebPushService implements WebPushService {
  const UnsupportedWebPushService();

  @override
  bool get isSupported => false;

  @override
  Future<Map<String, Object?>> subscribe(String applicationServerKey) =>
      Future.error(UnsupportedError('Web Push is not supported'));

  @override
  Future<bool> requestPersistentStorage() async => false;
}
