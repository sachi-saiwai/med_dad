import 'dart:typed_data';

import 'attachment_compression.dart';
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

  PickedAttachment copyWith({
    String? displayName,
    String? path,
    Uint8List? bytes,
    String? contentType,
  }) => PickedAttachment(
    displayName: displayName ?? this.displayName,
    path: path ?? this.path,
    bytes: bytes ?? this.bytes,
    contentType: contentType ?? this.contentType,
  );
}

abstract interface class AttachmentService {
  Future<PickedAttachment?> pick(String source);
}

/// Keeps [path] pointing at the untouched original for on-device OCR while
/// [bytes] carry a version small enough for the size-limited APIs.
class ShrinkingAttachmentService implements AttachmentService {
  const ShrinkingAttachmentService(this._delegate);

  final AttachmentService _delegate;

  @override
  Future<PickedAttachment?> pick(String source) async {
    final picked = await _delegate.pick(source);
    if (picked == null) return null;
    return shrinkAttachmentForUpload(picked);
  }
}

AttachmentService createAttachmentService() =>
    ShrinkingAttachmentService(platform.createPlatformAttachmentService());

Future<PickedAttachment?> readStoredAttachment(String path) =>
    platform.readStoredAttachment(path);
