import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'attachment_service.dart';

/// Vercel caps serverless request bodies at 4.5MB and base64 inflates the
/// payload by a third, so the API refuses inline files above this size.
const int maxAttachmentBytes = 3 * 1024 * 1024;

/// Leaves headroom under [maxAttachmentBytes] for the surrounding JSON.
const int defaultAttachmentTargetBytes = 2 * 1024 * 1024;

/// Long-edge cap for photos. Certificate text stays legible for OCR well below
/// the 12MP a phone camera produces.
const int attachmentMaxDimension = 2600;

const Set<String> _shrinkableTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
};

/// Re-encodes oversized photos as JPEG so a phone camera shot still fits the
/// inline size the extraction and upload APIs accept.
///
/// Returns [attachment] unchanged when it is already small enough, is not a
/// still image, or cannot be decoded; the caller keeps reporting the size error
/// in that case.
Future<PickedAttachment> shrinkAttachmentForUpload(
  PickedAttachment attachment, {
  int targetBytes = defaultAttachmentTargetBytes,
  int maxDimension = attachmentMaxDimension,
}) async {
  final bytes = attachment.bytes;
  if (bytes == null || bytes.length <= targetBytes) return attachment;
  final contentType = normalizeContentType(attachment.contentType);
  if (!_shrinkableTypes.contains(contentType)) return attachment;
  Uint8List? shrunk;
  try {
    shrunk = await _shrink(
      bytes,
      targetBytes: targetBytes,
      maxDimension: maxDimension,
    );
  } on Object {
    return attachment;
  }
  if (shrunk == null || shrunk.length >= bytes.length) return attachment;
  return attachment.copyWith(
    displayName: _jpegName(attachment.displayName),
    bytes: shrunk,
    contentType: 'image/jpeg',
  );
}

String normalizeContentType(String? value) =>
    (value ?? '').toLowerCase().split(';').first.trim();

String attachmentTooLargeMessage(String? contentType) {
  final limit = '${maxAttachmentBytes ~/ (1024 * 1024)}MB';
  return switch (normalizeContentType(contentType)) {
    'application/pdf' => 'PDFは$limitまでです。ページ数を減らすか、写真で撮り直してお試しください。',
    _ => '画像を$limit以下に圧縮できませんでした。トリミングするか、撮り直してお試しください。',
  };
}

Future<Uint8List?> _shrink(
  Uint8List bytes, {
  required int targetBytes,
  required int maxDimension,
}) async {
  final steps = <({int dimension, int quality})>[
    (dimension: maxDimension, quality: 82),
    (dimension: (maxDimension * 3) ~/ 4, quality: 70),
    (dimension: maxDimension ~/ 2, quality: 58),
  ];
  Uint8List? smallest;
  for (final step in steps) {
    final pixels = await _decodeScaled(bytes, step.dimension);
    if (pixels == null) return smallest;
    final encoded = await compute(
      _encodeJpeg,
      _JpegRequest(
        width: pixels.width,
        height: pixels.height,
        rgba: pixels.rgba,
        quality: step.quality,
      ),
    );
    if (smallest == null || encoded.length < smallest.length) {
      smallest = encoded;
    }
    if (encoded.length <= targetBytes) return encoded;
  }
  return smallest;
}

class _Pixels {
  const _Pixels({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}

Future<_Pixels?> _decodeScaled(Uint8List bytes, int maxDimension) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longestSide = math.max(descriptor.width, descriptor.height);
    final scale = longestSide > maxDimension ? maxDimension / longestSide : 1.0;
    final codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data == null) return null;
        return _Pixels(
          width: image.width,
          height: image.height,
          rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

class _JpegRequest {
  const _JpegRequest({
    required this.width,
    required this.height,
    required this.rgba,
    required this.quality,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final int quality;
}

Uint8List _encodeJpeg(_JpegRequest request) {
  final image = img.Image.fromBytes(
    width: request.width,
    height: request.height,
    bytes: request.rgba.buffer,
    bytesOffset: request.rgba.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodeJpg(image, quality: request.quality);
}

String _jpegName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'certificate.jpg';
  final dot = trimmed.lastIndexOf('.');
  final base = dot > 0 ? trimmed.substring(0, dot) : trimmed;
  return '$base.jpg';
}
