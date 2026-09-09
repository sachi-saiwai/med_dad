import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medlicense/services/attachment_compression.dart';
import 'package:medlicense/services/attachment_service.dart';

Uint8List _noisyJpeg({int width = 1200, int height = 900}) {
  final random = Random(7);
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, random.nextInt(256), random.nextInt(256), 255);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

class _FixedAttachmentService implements AttachmentService {
  const _FixedAttachmentService(this.attachment);

  final PickedAttachment? attachment;

  @override
  Future<PickedAttachment?> pick(String source) async => attachment;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const targetBytes = 200 * 1024;

  test('re-encodes an oversized photo below the target size', () async {
    final original = _noisyJpeg();
    expect(original.length, greaterThan(targetBytes));

    final shrunk = await shrinkAttachmentForUpload(
      PickedAttachment(
        displayName: 'IMG_0042.HEIC',
        path: '/tmp/IMG_0042.HEIC',
        bytes: original,
        contentType: 'image/jpeg',
      ),
      targetBytes: targetBytes,
      maxDimension: 600,
    );

    expect(shrunk.bytes!.length, lessThanOrEqualTo(targetBytes));
    expect(shrunk.contentType, 'image/jpeg');
    expect(shrunk.displayName, 'IMG_0042.jpg');
    expect(shrunk.path, '/tmp/IMG_0042.HEIC');
  });

  test('keeps an attachment that already fits', () async {
    final attachment = PickedAttachment(
      displayName: 'small.jpg',
      bytes: Uint8List(1024),
      contentType: 'image/jpeg',
    );

    expect(
      await shrinkAttachmentForUpload(attachment, targetBytes: targetBytes),
      same(attachment),
    );
  });

  test('leaves PDFs and undecodable bytes alone', () async {
    final pdf = PickedAttachment(
      displayName: 'certificate.pdf',
      bytes: Uint8List(targetBytes + 1),
      contentType: 'application/pdf',
    );
    final broken = PickedAttachment(
      displayName: 'broken.jpg',
      bytes: Uint8List(targetBytes + 1),
      contentType: 'image/jpeg',
    );

    expect(
      await shrinkAttachmentForUpload(pdf, targetBytes: targetBytes),
      same(pdf),
    );
    expect(
      await shrinkAttachmentForUpload(broken, targetBytes: targetBytes),
      same(broken),
    );
  });

  test('the picker decorator shrinks what the platform returns', () async {
    final service = ShrinkingAttachmentService(
      _FixedAttachmentService(
        PickedAttachment(
          displayName: 'photo.jpg',
          bytes: _noisyJpeg(width: 3200, height: 2400),
          contentType: 'image/jpeg',
        ),
      ),
    );

    final picked = await service.pick('カメラ撮影');

    expect(picked!.bytes!.length, lessThanOrEqualTo(maxAttachmentBytes));
  });

  test('explains why an oversized file was rejected', () {
    expect(attachmentTooLargeMessage('application/pdf'), contains('PDF'));
    expect(attachmentTooLargeMessage('image/jpeg'), contains('撮り直して'));
  });
}
