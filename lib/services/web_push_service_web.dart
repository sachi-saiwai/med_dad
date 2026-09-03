import 'dart:convert';
import 'dart:js_interop';

import 'web_push_service.dart';

@JS('medlicensePush.isSupported')
external JSBoolean _isPushSupported();

@JS('medlicensePush.subscribe')
external JSPromise<JSString> _subscribeToPush(JSString applicationServerKey);

@JS('medlicensePwa.requestPersistentStorage')
external JSPromise<JSBoolean> _requestPersistentStorage();

WebPushService createPlatformWebPushService() => WebBrowserPushService();

class WebBrowserPushService implements WebPushService {
  @override
  bool get isSupported {
    try {
      return _isPushSupported().toDart;
    } on Object {
      return false;
    }
  }

  @override
  Future<Map<String, Object?>> subscribe(String applicationServerKey) async {
    final value = await _subscribeToPush(applicationServerKey.toJS).toDart;
    return Map<String, Object?>.from(jsonDecode(value.toDart) as Map);
  }

  @override
  Future<bool> requestPersistentStorage() async {
    try {
      return (await _requestPersistentStorage().toDart).toDart;
    } on Object {
      return false;
    }
  }
}
