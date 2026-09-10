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

/// Caps the long edge using the decoded pixel size.
///
/// Web's image picker ignores `maxWidth` / `maxHeight`, so this runs at pick
/// time to keep later JPEG passes off a 12MP original. Unchanged when the
/// image already fits, is not a still image, or cannot be decoded.
Future<PickedAttachment> constrainAttachmentDimension(
  PickedAttachment attachment, {
  int maxDimension = attachmentMaxDimension,
  int quality = 88,
}) async {
  final bytes = attachment.bytes;
  if (bytes == null || bytes.isEmpty) return attachment;
  final contentType = normalizeContentType(attachment.contentType);
  if (!_shrinkableTypes.contains(contentType)) return attachment;
  Uint8List? constrained;
  try {
    constrained = await _reencodeDecoded(
      bytes,
      maxDimension: maxDimension,
      quality: quality,
      skipIfAlreadyFits: true,
    );
  } on Object {
    return attachment;
  }
  if (constrained == null) return attachment;
  return attachment.copyWith(
    displayName: _jpegName(attachment.displayName),
    bytes: constrained,
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

({int width, int height}) scaledSize({
  required int width,
  required int height,
  required int maxDimension,
}) {
  final longest = math.max(width, height);
  if (longest <= maxDimension) return (width: width, height: height);
  final scale = maxDimension / longest;
  return (
    width: math.max(1, (width * scale).round()),
    height: math.max(1, (height * scale).round()),
  );
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
  final codec = await ui.instantiateImageCodec(bytes);
  ui.Image? source;
  try {
    source = (await codec.getNextFrame()).image;
    Uint8List? smallest;
    for (final step in steps) {
      final encoded = await _encodeImage(
        source,
        maxDimension: step.dimension,
        quality: step.quality,
      );
      if (encoded == null) return smallest;
      if (smallest == null || encoded.length < smallest.length) {
        smallest = encoded;
      }
      if (encoded.length <= targetBytes) return encoded;
    }
    return smallest;
  } finally {
    source?.dispose();
    codec.dispose();
  }
}

Future<Uint8List?> _reencodeDecoded(
  Uint8List bytes, {
  required int maxDimension,
  required int quality,
  required bool skipIfAlreadyFits,
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  ui.Image? source;
  try {
    source = (await codec.getNextFrame()).image;
    if (skipIfAlreadyFits &&
        math.max(source.width, source.height) <= maxDimension) {
      return null;
    }
    return _encodeImage(source, maxDimension: maxDimension, quality: quality);
  } finally {
    source?.dispose();
    codec.dispose();
  }
}

Future<Uint8List?> _encodeImage(
  ui.Image source, {
  required int maxDimension,
  required int quality,
}) async {
  final size = scaledSize(
    width: source.width,
    height: source.height,
    maxDimension: maxDimension,
  );
  ui.Image? scaled;
  final frame = size.width == source.width && size.height == source.height
      ? source
      : scaled = await _scaleImage(source, size.width, size.height);
  try {
    final pixels = await _pixelsFromImage(frame);
    if (pixels == null) return null;
    return _jpegBytes(
      _JpegRequest(
        width: pixels.width,
        height: pixels.height,
        rgba: pixels.rgba,
        quality: quality,
      ),
    );
  } finally {
    scaled?.dispose();
  }
}

Future<ui.Image> _scaleImage(ui.Image source, int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    source,
    ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
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

Future<_Pixels?> _pixelsFromImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  return _Pixels(
    width: image.width,
    height: image.height,
    rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
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

Future<Uint8List> _jpegBytes(_JpegRequest request) {
  // Web workers are unreliable for this payload in Chrome tests; keep encoding
  // on the same isolate there. Native apps still offload JPEG encode.
  if (kIsWeb) return Future<Uint8List>.value(_encodeJpeg(request));
  return compute(_encodeJpeg, request);
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
