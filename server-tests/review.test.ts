import assert from 'node:assert/strict';
import test from 'node:test';

import { validateRuleCorrections } from '../api/_lib/review.js';

test('validateRuleCorrections accepts reviewed fields', () => {
  const rule = validateRuleCorrections({
    systemType: '日本専門医機構認定',
    acquiredYearFrom: 2024,
    acquiredYearTo: 2026,
    renewalCycleYears: 5,
    requiredTotalCredits: 50,
    requirements: [
      {
        label: '専門医共通講習',
        minimum: 8,
        maximum: 10,
        unit: '単位',
        mandatory: true,
      },
    ],
    mandatoryNotes: ['勤務実態の自己申告が必要'],
    otherConditions: [],
  });

  assert.equal(rule.requiredTotalCredits, 50);
  assert.equal(rule.requirements[0]?.minimum, 8);
});

test('validateRuleCorrections rejects inverted acquisition years', () => {
  assert.throws(
    () =>
      validateRuleCorrections({
        systemType: '日本専門医機構認定',
        acquiredYearFrom: 2027,
        acquiredYearTo: 2024,
        requirements: [],
        mandatoryNotes: [],
        otherConditions: [],
      }),
    /must not be after/,
  );
});

test('validateRuleCorrections rejects requirements without a numeric condition', () => {
  assert.throws(
    () =>
      validateRuleCorrections({
        systemType: '学会認定',
        requirements: [
          { label: '講習', unit: '単位', mandatory: false },
        ],
        mandatoryNotes: [],
        otherConditions: [],
      }),
    /needs a value/,
  );
});
