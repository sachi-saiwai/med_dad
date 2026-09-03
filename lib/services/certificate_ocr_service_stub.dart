import 'attachment_service.dart';
import 'certificate_ocr_service.dart';

CertificateOcrService createPlatformCertificateOcrService() =>
    const UnsupportedCertificateOcrService();

class UnsupportedCertificateOcrService implements CertificateOcrService {
  const UnsupportedCertificateOcrService();

  @override
  bool get isSupported => false;

  @override
  Future<CertificateOcrResult> recognize(PickedAttachment attachment) {
    throw const CertificateOcrException('この端末では端末内OCRを利用できません。');
  }
}
