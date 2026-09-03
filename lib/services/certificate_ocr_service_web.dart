import 'attachment_service.dart';
import 'certificate_ocr_service.dart';

CertificateOcrService createPlatformCertificateOcrService() =>
    const WebCertificateOcrService();

class WebCertificateOcrService implements CertificateOcrService {
  const WebCertificateOcrService();

  @override
  bool get isSupported => false;

  @override
  Future<CertificateOcrResult> recognize(PickedAttachment attachment) {
    throw const CertificateOcrException('Web版では認証済みサーバーの構造化読み取りを使用します。');
  }
}
