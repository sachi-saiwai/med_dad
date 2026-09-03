import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'attachment_service.dart';

AttachmentService createPlatformAttachmentService() => WebAttachmentService();

class WebAttachmentService implements AttachmentService {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<PickedAttachment?> pick(String source) async {
    if (source == '手入力') return const PickedAttachment(displayName: '');
    if (source == 'PDFファイル') {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (selected == null) return null;
      return PickedAttachment(
        displayName: selected.name,
        bytes: await selected.readAsBytes(),
        contentType: 'application/pdf',
      );
    }
    final image = await _imagePicker.pickImage(
      source: source == 'カメラ撮影' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
      requestFullMetadata: false,
    );
    if (image == null) return null;
    return PickedAttachment(
      displayName: image.name,
      bytes: await image.readAsBytes(),
      contentType: image.mimeType ?? _imageContentType(image.name),
    );
  }
}

String _imageContentType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  return 'image/jpeg';
}
