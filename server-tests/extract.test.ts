import assert from 'node:assert/strict';
import test from 'node:test';

import {
  extractHtml,
  linksForDiscovery,
  structureRenewalRule,
} from '../api/_lib/extract.js';

test('extractHtml removes scripts and resolves source links', () => {
  const document = extractHtml(
    Buffer.from(`
      <html><head><title>更新基準</title><script>secret()</script></head>
      <body><main><h1>専門医更新基準</h1><p>更新には50単位が必要です。</p>
      <a href="/docs/rule.pdf">更新基準 PDF</a></main></body></html>
    `),
    'https://official.example.jp/rules/',
  );

  assert.equal(document.title, '更新基準');
  assert.match(document.text, /50単位/u);
  assert.doesNotMatch(document.text, /secret/u);
  assert.equal(document.links[0]?.url, 'https://official.example.jp/docs/rule.pdf');
});

test('structureRenewalRule extracts cycle, total and requirement evidence', () => {
  const result = structureRenewalRule({
    title: '専門医更新基準',
    links: [],
    text: `
      専門医資格は5年毎に更新する。
      更新単位は4項目の合計50単位の取得が必要です。
      項目 i) 診療実績の証明 10単位（必須）
      項目 ii) 専門医共通講習 最小8単位、最大10単位（必修講習を含む）
      項目 iii) 領域講習 最小20単位
      1回の講習は1時間以上とし、講師には2単位を付与する。
      直近1年間の勤務実態を自己申告する。
    `,
  });

  assert.equal(result.rule.renewalCycleYears, 5);
  assert.equal(result.rule.requiredTotalCredits, 50);
  assert.ok(result.rule.requirements.length >= 3);
  assert.equal(
    result.rule.requirements.some((item) => item.label.includes('1回の講習')),
    false,
  );
  assert.ok(result.rule.mandatoryNotes.length >= 1);
  assert.ok(result.confidence >= 0.8);
});

test('calendar years are not mistaken for a renewal cycle', () => {
  const result = structureRenewalRule({
    title: '2027年3月31日満了者向け更新案内',
    links: [],
    text: '2027年3月31日に認定期間が満了する方は、50単位以上の取得が必要です。',
  });

  assert.equal(result.rule.renewalCycleYears, undefined);
  assert.ok(result.rule.warnings.some((warning) => warning.includes('対象者')));
});

test('linksForDiscovery only follows matching links on the official host', () => {
  const links = linksForDiscovery(
    [
      { title: '専門医更新基準', url: 'https://official.example.jp/rule.pdf' },
      { title: '更新基準', url: 'https://untrusted.example/rule.pdf' },
      { title: '交通案内', url: 'https://official.example.jp/access.html' },
    ],
    'https://official.example.jp/index.html',
    ['更新'],
  );

  assert.deepEqual(links, [
    { title: '専門医更新基準', url: 'https://official.example.jp/rule.pdf' },
  ]);
});
