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
      return PickedAttachment(displayName: selected.name);
    }
    final image = await _imagePicker.pickImage(
      source: source == 'カメラ撮影' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
      requestFullMetadata: false,
    );
    if (image == null) return null;
    return PickedAttachment(displayName: image.name);
  }
}
