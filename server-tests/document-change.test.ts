import assert from 'node:assert/strict';
import test from 'node:test';

import { deterministicDocumentChange } from '../api/_lib/document-change.js';

test('first official document snapshot is marked as initial', () => {
  const analysis = deterministicDocumentChange({
    currentText: '専門医更新には50単位が必要です。',
  });

  assert.equal(analysis.isInitial, true);
  assert.equal(analysis.significance, 'none');
  assert.equal(analysis.changes.length, 0);
});

test('numeric renewal requirement changes are highlighted as high significance', () => {
  const analysis = deterministicDocumentChange({
    previousSnapshotId: 'snapshot-1',
    previousText: '専門医更新には50単位が必要です。\n更新申請は3月31日までです。',
    currentText: '専門医更新には60単位が必要です。\n更新申請は3月31日までです。',
  });

  assert.equal(analysis.isInitial, false);
  assert.equal(analysis.significance, 'high');
  assert.equal(analysis.previousSnapshotId, 'snapshot-1');
  assert.ok(analysis.changes.some((change) => change.before.includes('50単位')));
  assert.ok(analysis.changes.some((change) => change.after.includes('60単位')));
  assert.ok(analysis.reviewPoints.some((point) => point.includes('必要総単位')));
});

test('format-only identical extracted text is not escalated', () => {
  const analysis = deterministicDocumentChange({
    previousText: '更新には 50単位 が必要です。',
    currentText: '更新には   50単位   が必要です。',
  });

  assert.equal(analysis.significance, 'none');
  assert.equal(analysis.addedLineCount, 0);
  assert.equal(analysis.removedLineCount, 0);
});
