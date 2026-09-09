import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'attachment_compression.dart';
import 'attachment_service.dart';

AttachmentService createPlatformAttachmentService() => IoAttachmentService();

class IoAttachmentService implements AttachmentService {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<PickedAttachment?> pick(String source) async {
    if (source == '手入力') return const PickedAttachment(displayName: '');

    if (source == 'PDFファイル') {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final selectedPath = selected?.path;
      if (selected == null || selectedPath == null) return null;
      return _persistFile(File(selectedPath), selected.name);
    }

    final image = await _imagePicker.pickImage(
      source: source == 'カメラ撮影' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: attachmentMaxDimension.toDouble(),
      maxHeight: attachmentMaxDimension.toDouble(),
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (image == null) return null;
    return _persistFile(File(image.path), image.name);
  }

  Future<PickedAttachment> _persistFile(
    File source,
    String originalName,
  ) async {
    final documents = await getApplicationDocumentsDirectory();
    final attachmentDirectory = Directory(
      path.join(documents.path, 'certificates'),
    );
    await attachmentDirectory.create(recursive: true);
    final extension = path.extension(originalName).toLowerCase();
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    final saved = await source.copy(
      path.join(attachmentDirectory.path, fileName),
    );
    return PickedAttachment(
      displayName: originalName,
      path: saved.path,
      bytes: await saved.readAsBytes(),
      contentType: _contentTypeFor(originalName),
    );
  }
}

String _contentTypeFor(String fileName) {
  final extension = path.extension(fileName).toLowerCase();
  return switch (extension) {
    '.pdf' => 'application/pdf',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.heic' => 'image/heic',
    '.heif' => 'image/heif',
    _ => 'image/jpeg',
  };
}
