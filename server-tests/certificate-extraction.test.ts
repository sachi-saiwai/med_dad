import assert from 'node:assert/strict';
import test from 'node:test';

import {
  deterministicCertificateExtraction,
  redactCertificatePersonalData,
} from '../api/_lib/certificate-extraction.js';

test('certificate text is structured without exposing attendee identity', () => {
  const result = deterministicCertificateExtraction(`
    受講証明書
    第12回 医療安全研修会
    氏名：資格 花子
    会員番号：12345678
    開催日：2026年8月18日
    主催：一般社団法人 日本医療安全学会
    認定ID：2608180042
    医療安全講習 2単位
  `);

  assert.equal(result.title, '第12回 医療安全研修会');
  assert.equal(result.date, '2026/08/18');
  assert.equal(result.organizer, '一般社団法人 日本医療安全学会');
  assert.equal(result.credits, 2);
  assert.equal(result.category, '医療安全講習');
  assert.equal(result.certificationId, '2608180042');
  assert.doesNotMatch(JSON.stringify(result), /資格 花子|12345678/u);
  assert.ok((result.fieldConfidence.credits || 0) > 0.8);
});

test('missing certificate values remain empty and produce warnings', () => {
  const result = deterministicCertificateExtraction('参加証\nご参加ありがとうございました');

  assert.equal(result.date, '');
  assert.equal(result.credits, null);
  assert.ok(result.warnings.some((warning) => warning.includes('開催日')));
  assert.ok(result.warnings.some((warning) => warning.includes('単位')));
});

test('labeled personal data is redacted before structured AI processing', () => {
  const redacted = redactCertificatePersonalData(
    '氏名：資格 花子\n会員番号: 12345678\n第12回 医療安全研修会',
  );

  assert.doesNotMatch(redacted, /資格 花子|12345678/u);
  assert.match(redacted, /第12回 医療安全研修会/u);
});
