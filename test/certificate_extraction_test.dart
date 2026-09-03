import 'package:flutter_test/flutter_test.dart';
import 'package:medlicense/services/certificate_extraction.dart';

void main() {
  test('参加証テキストから登録項目を抽出する', () {
    final result = extractCertificateFields('''
受講証明書
第12回 医療安全研修会
氏名：資格 花子
開催日：2026年8月18日
主催：一般社団法人 日本医療安全学会
医療安全講習 2単位
''');

    expect(result.title, '第12回 医療安全研修会');
    expect(result.date, '2026/08/18');
    expect(result.organizer, '一般社団法人 日本医療安全学会');
    expect(result.credits, 2);
    expect(result.category, '医療安全講習');
    expect(result.confidenceFor('credits'), greaterThan(0.8));
  });

  test('AIレスポンスの信頼度を0から1へ制限する', () {
    final result = CertificateExtraction.fromJson({
      'title': '研修会',
      'fieldConfidence': {'title': 2, 'date': -1},
    });

    expect(result.confidenceFor('title'), 1);
    expect(result.confidenceFor('date'), 0);
  });
}
