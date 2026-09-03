import 'dart:io';

import 'package:flutter/services.dart';

import 'attachment_service.dart';
import 'certificate_ocr_service.dart';

CertificateOcrService createPlatformCertificateOcrService() =>
    const NativeCertificateOcrService();

class NativeCertificateOcrService implements CertificateOcrService {
  const NativeCertificateOcrService();

  static const _channel = MethodChannel('jp.sachikosaga.medlicense/ocr');

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<CertificateOcrResult> recognize(PickedAttachment attachment) async {
    if (!isSupported) {
      throw const CertificateOcrException('この端末では端末内OCRを利用できません。');
    }
    final path = attachment.path;
    if (path == null || path.isEmpty) {
      throw const CertificateOcrException('読み取り対象のファイルを端末上で開けません。');
    }
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'recognize',
        {'path': path, 'contentType': attachment.contentType ?? ''},
      );
      final text = (result?['text'] as String? ?? '').trim();
      if (text.isEmpty) {
        throw const CertificateOcrException('参加証から文字を読み取れませんでした。');
      }
      return CertificateOcrResult(
        text: text,
        engine: result?['engine'] as String? ?? 'native-ocr',
        blockCount: (result?['blockCount'] as num?)?.toInt() ?? 0,
      );
    } on CertificateOcrException {
      rethrow;
    } on PlatformException catch (error) {
      throw CertificateOcrException(
        error.message?.trim().isNotEmpty == true
            ? error.message!
            : '端末内OCRを実行できませんでした。',
      );
    }
  }
}
