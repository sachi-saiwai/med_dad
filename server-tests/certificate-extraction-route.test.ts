import assert from 'node:assert/strict';
import test from 'node:test';

import { prepareCertificateAiInput } from '../api/v1/certificate-extraction.js';

test('text PDFs keep both extracted text and the original PDF for AI vision', async () => {
  const input = await prepareCertificateAiInput({
    ocrText: '',
    contentType: 'application/pdf',
    fileBase64: 'cGRm',
    bytes: Buffer.from('pdf'),
  }, async () => ({ text: '第12回 医療安全研修会' }));

  assert.equal(input.ocrText, '第12回 医療安全研修会');
  assert.deepEqual(input.inlineData, {
    mimeType: 'application/pdf',
    data: 'cGRm',
  });
});

test('scanned PDFs still reach AI when server-side text parsing fails', async () => {
  const input = await prepareCertificateAiInput({
    ocrText: '',
    contentType: 'application/pdf',
    fileBase64: 'c2Nhbm5lZA==',
    bytes: Buffer.from('scanned'),
  }, async () => {
    throw new Error('no text layer');
  });

  assert.equal(input.ocrText, '');
  assert.equal(input.inlineData.mimeType, 'application/pdf');
});
