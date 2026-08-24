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

const surgicalProfiles = [
  {
    url: 'https://www.jsgs.or.jp/senmon/others/senmon_shidoi_koshin/',
    cycle: 5,
    requirement: '消化器外科手術経験',
  },
  {
    url: 'https://chest.umin.jp/std/std_apl_kou.html',
    cycle: 5,
    total: 20,
    requirement: '呼吸器外科手術経験',
  },
  {
    url: 'https://jcvs.jp/senmoni/shinsei/koushin/',
    cycle: 5,
    requirement: '構成3学会の学術集会',
  },
  {
    url: 'https://jcvs.jp/newseido/',
    cycle: 5,
    requirement: '専門医共通講習',
  },
  {
    url: 'https://jmsb.or.jp/wp-content/uploads/2026/03/gaiho_2025.pdf',
    cycle: 5,
    requirement: '所定の学術集会・研究会',
  },
  {
    url: 'https://www.jbcs.gr.jp/modules/elearning/index.php?content_id=13',
    cycle: 5,
    requirement: '乳癌症例の診療経験',
  },
  {
    url: 'https://jaes.umin.jp/nintei/specialist/specialist_bylaws.pdf',
    cycle: 5,
    requirement: '研究業績',
  },
];

for (const profile of surgicalProfiles) {
  test(`verified surgical profile is structured for ${profile.url}`, () => {
    const result = applyOfficialSourceProfile(profile.url, fallback);

    assert.equal(result.rule.renewalCycleYears, profile.cycle);
    assert.equal(result.rule.requiredTotalCredits, profile.total);
    assert.ok(result.rule.requirements.some((item) => item.label === profile.requirement));
    assert.ok(result.confidence >= 0.9);
    assert.notEqual(result.extractionMethod, 'deterministic-v2');
  });
}
