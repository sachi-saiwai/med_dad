import 'attachment_service.dart';
import 'certificate_ocr_service_stub.dart'
    if (dart.library.io) 'certificate_ocr_service_io.dart'
    if (dart.library.js_interop) 'certificate_ocr_service_web.dart'
    as platform;

class CertificateOcrResult {
  const CertificateOcrResult({
    required this.text,
    required this.engine,
    this.blockCount = 0,
  });

  final String text;
  final String engine;
  final int blockCount;
}

class CertificateOcrException implements Exception {
  const CertificateOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class CertificateOcrService {
  bool get isSupported;

  Future<CertificateOcrResult> recognize(PickedAttachment attachment);
}

CertificateOcrService createCertificateOcrService() =>
    platform.createPlatformCertificateOcrService();
