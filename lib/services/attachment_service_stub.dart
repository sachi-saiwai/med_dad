import 'attachment_service.dart';

AttachmentService createPlatformAttachmentService() =>
    UnsupportedAttachmentService();

class UnsupportedAttachmentService implements AttachmentService {
  @override
  Future<PickedAttachment?> pick(String source) async => null;
}
