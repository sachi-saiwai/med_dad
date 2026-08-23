import 'attachment_service_stub.dart'
    if (dart.library.io) 'attachment_service_io.dart'
    if (dart.library.js_interop) 'attachment_service_web.dart'
    as platform;

class PickedAttachment {
  const PickedAttachment({required this.displayName, this.path});

  final String displayName;
  final String? path;
}

abstract interface class AttachmentService {
  Future<PickedAttachment?> pick(String source);
}

AttachmentService createAttachmentService() =>
    platform.createPlatformAttachmentService();
