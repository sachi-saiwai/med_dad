import assert from 'node:assert/strict';
import test from 'node:test';

import { applyOfficialSourceProfile } from '../api/_lib/official-profiles.js';

const fallback = {
  confidence: 0.05,
  rule: {
    schemaVersion: 1 as const,
    requirements: [],
    otherConditions: [],
    mandatoryNotes: [],
    evidence: ['認定臨床医の資格更新は5年毎に行う。'],
    warnings: [],
  },
};

test('JARM V-11 uses the verified recognized clinical physician profile', () => {
  const result = applyOfficialSourceProfile(
    'https://www.jarm.or.jp/jarm/document/rules/05/5-11.pdf',
    fallback,
  );

  assert.equal(result.rule.renewalCycleYears, 5);
  assert.equal(result.rule.requiredTotalCredits, 200);
  assert.equal(result.rule.requirements[0]?.mandatory, true);
  assert.equal(result.confidence, 0.95);
  assert.equal(result.extractionMethod, 'official-profile-jarm-v1');
});

test('unknown sources keep the deterministic extraction result', () => {
  const result = applyOfficialSourceProfile('https://example.com/rule.pdf', fallback);

  assert.equal(result.rule, fallback.rule);
  assert.equal(result.confidence, 0.05);
  assert.equal(result.extractionMethod, 'deterministic-v2');
});
