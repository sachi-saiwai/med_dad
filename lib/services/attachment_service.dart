import 'dart:typed_data';

import 'attachment_service_stub.dart'
    if (dart.library.io) 'attachment_service_io.dart'
    if (dart.library.js_interop) 'attachment_service_web.dart'
    as platform;

class PickedAttachment {
  const PickedAttachment({
    required this.displayName,
    this.path,
    this.bytes,
    this.contentType,
  });

  final String displayName;
  final String? path;
  final Uint8List? bytes;
  final String? contentType;
}

abstract interface class AttachmentService {
  Future<PickedAttachment?> pick(String source);
}

AttachmentService createAttachmentService() =>
    platform.createPlatformAttachmentService();
