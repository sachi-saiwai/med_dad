import { load } from 'cheerio';
// Import the library implementation directly. The package's legacy index.js
// executes its bundled demo file when loaded from ESM/TypeScript.
import pdfParse from 'pdf-parse/lib/pdf-parse.js';

export interface DiscoveredLink {
  title: string;
  url: string;
}

export interface ExtractedDocument {
  title?: string;
  text: string;
  links: DiscoveredLink[];
  pageCount?: number;
}

export interface RequirementCandidate {
  label: string;
  minimum?: number;
  maximum?: number;
  requiredValue?: number;
  unit: '単位' | '症例' | '回' | '件';
  mandatory: boolean;
  evidence: string;
}

export interface ConfidenceFactor {
  label: string;
  status: 'confirmed' | 'partial' | 'missing' | 'attention';
  detail: string;
}

export interface ConfidenceAssessment {
  version: 1;
  score: number;
  summary: string;
  factors: ConfidenceFactor[];
}

export interface StructuredRenewalRule {
  schemaVersion: 1;
  title?: string;
  renewalCycleYears?: number;
  requiredTotalCredits?: number;
  requirements: RequirementCandidate[];
  otherConditions: string[];
  mandatoryNotes: string[];
  evidence: string[];
  warnings: string[];
  confidenceAssessment?: ConfidenceAssessment;
}

const compactWhitespace = (value: string): string =>
  value
    .replace(/\r/g, '')
    .replace(/[\t\f\v　]+/g, ' ')
    .replace(/ +/g, ' ')
    .replace(/ *\n */g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

const textBlocks = (text: string): string[] => {
  const lines = compactWhitespace(text)
    .split(/\n|(?<=[。．])\s*/u)
    .map((line) => line.trim())
    .filter((line) => line.length >= 4 && line.length <= 500);
  return [...new Set(lines)];
};

export const extractHtml = (bytes: Buffer, baseUrl: string): ExtractedDocument => {
  const html = bytes.toString('utf8');
  const $ = load(html);
  const title = compactWhitespace($('title').first().text()) || undefined;
  const links: DiscoveredLink[] = [];

  $('a[href]').each((_index, element) => {
    const href = $(element).attr('href');
    if (!href) return;
    try {
      const url = new URL(href, baseUrl);
      if (url.protocol !== 'https:' && url.protocol !== 'http:') return;
      url.hash = '';
      links.push({
        title: compactWhitespace($(element).text()) || url.pathname.split('/').pop() || '資料',
        url: url.toString(),
      });
    } catch {
      // Ignore malformed links from the source page.
    }
  });

  $('script, style, noscript, svg, nav, footer').remove();
  const mainText = $('main, article, [role="main"]').first().text();
  const text = compactWhitespace(mainText || $('body').text());

  return { title, text, links: deduplicateLinks(links) };
};

export const extractPdf = async (bytes: Buffer): Promise<ExtractedDocument> => {
  const result = await pdfParse(bytes);
  return {
    text: compactWhitespace(result.text),
    links: [],
    pageCount: result.numpages,
  };
};

export const extractDocument = async (
  bytes: Buffer,
  contentType: string,
  sourceUrl: string,
): Promise<ExtractedDocument> => {
  const isPdf =
    contentType.toLowerCase().includes('application/pdf') ||
    new URL(sourceUrl).pathname.toLowerCase().endsWith('.pdf');
  return isPdf ? extractPdf(bytes) : extractHtml(bytes, sourceUrl);
};

const deduplicateLinks = (links: DiscoveredLink[]): DiscoveredLink[] => {
  const seen = new Set<string>();
  return links.filter((link) => {
    if (seen.has(link.url)) return false;
    seen.add(link.url);
    return true;
  });
};

const firstNumber = (value: string, expression: RegExp): number | undefined => {
  const match = expression.exec(value);
  const parsed = match?.[1] ? Number.parseFloat(match[1]) : Number.NaN;
  return Number.isFinite(parsed) ? parsed : undefined;
};

const totalCreditCandidate = (blocks: string[]): number | undefined => {
  const explicitPatterns = [
    /必要単位\s*(\d{1,3}(?:\.\d+)?)\s*単位/u,
    /更新単位\s*(\d{1,3}(?:\.\d+)?)\s*単位/u,
    /総単位(?:数)?[^\d]{0,12}(\d{1,3}(?:\.\d+)?)\s*単位/u,
    /合計[^\d]{0,12}(\d{1,3}(?:\.\d+)?)\s*単位[^。．]{0,30}必要/u,
  ];
  for (const pattern of explicitPatterns) {
    for (const block of blocks) {
      const value = firstNumber(block, pattern);
      if (value !== undefined) return value;
    }
  }

  const scored = blocks
    .filter((block) => block.includes('単位'))
    .map((block) => {
      const value = firstNumber(block, /(\d{1,3}(?:\.\d+)?)\s*単位/u);
      let score = 0;
      if (/合計|総単位|更新単位/u.test(block)) score += 3;
      if (/必要|取得|基準/u.test(block)) score += 2;
      if (/更新/u.test(block)) score += 1;
      if (/最小|最大|上限|項目/u.test(block)) score -= 2;
      return { value, score, block };
    })
    .filter((item): item is { value: number; score: number; block: string } => item.value !== undefined)
    .sort((a, b) => b.score - a.score || b.value - a.value);
  return scored[0]?.score && scored[0].score > 1 ? scored[0].value : undefined;
};

const requirementLabel = (block: string): string => {
  const withoutPrefix = block.replace(/^.*?(?:項目\s*[ivxⅠⅡⅢⅣⅤ]+[)）.]?|\d+[)）.、])\s*/u, '');
  const beforeNumber = withoutPrefix.split(/(?:最小|最大|\d+(?:\.\d+)?\s*(?:単位|症例|回|件))/u)[0]?.trim();
  return (beforeNumber || withoutPrefix).slice(0, 80);
};

const unitFor = (block: string): RequirementCandidate['unit'] => {
  if (/症例/u.test(block)) return '症例';
  if (/\d+\s*回/u.test(block)) return '回';
  if (/\d+\s*件/u.test(block)) return '件';
  return '単位';
};

const requirementCandidates = (blocks: string[]): RequirementCandidate[] => {
  const candidates = blocks
    .filter(
      (block) =>
        /(単位|症例|\d+\s*回|\d+\s*件)/u.test(block) &&
        /(講習|診療実績|学術|活動実績|症例|研修|必修|必須|項目)/u.test(block) &&
        // Only rows that are visibly part of a numbered requirement table/list.
        // Explanatory examples such as "a lecturer receives 2 credits" remain
        // in evidence but must not become progress requirements.
        /^(?:項\s*目\s*)?(?:[ivxⅠⅡⅢⅣⅤ]+[)）.]|\d+[)）.]|[①-⑳])|^更新単位/u.test(block),
    )
    .map((block) => {
      const minimum = firstNumber(block, /最小\s*(\d+(?:\.\d+)?)\s*(?:単位|症例|回|件)?/u);
      const maximum = firstNumber(block, /最大\s*(\d+(?:\.\d+)?)\s*(?:単位|症例|回|件)?/u);
      const direct = firstNumber(block, /(\d+(?:\.\d+)?)\s*(?:単位|症例|回|件)/u);
      return {
        label: requirementLabel(block),
        minimum,
        maximum,
        requiredValue: minimum === undefined && maximum === undefined ? direct : undefined,
        unit: unitFor(block),
        mandatory: /必修|必須/u.test(block),
        evidence: block.slice(0, 500),
      } satisfies RequirementCandidate;
    })
    .filter((item) => item.minimum !== undefined || item.maximum !== undefined || item.requiredValue !== undefined);

  const seen = new Set<string>();
  return candidates.filter((item) => {
    const key = `${item.label}:${item.minimum}:${item.maximum}:${item.requiredValue}:${item.unit}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  }).slice(0, 30);
};

const confidenceAssessmentFor = (
  rule: Omit<StructuredRenewalRule, 'confidenceAssessment'>,
): ConfidenceAssessment => {
  const factors: ConfidenceFactor[] = [];
  let score = 0;
  const addFactor = (
    label: string,
    status: ConfidenceFactor['status'],
    detail: string,
    points: number,
  ): void => {
    factors.push({ label, status, detail });
    score += points;
  };

  if (rule.evidence.length >= 3) {
    addFactor('原文根拠', 'confirmed', `更新条件に関する原文を${rule.evidence.length}件抽出`, 0.2);
  } else if (rule.evidence.length > 0) {
    addFactor('原文根拠', 'partial', `関連する原文は${rule.evidence.length}件のみ`, 0.12);
  } else {
    addFactor('原文根拠', 'missing', '更新条件に関する原文を抽出できていません', 0.04);
  }

  addFactor(
    '資料タイトル',
    rule.title ? 'confirmed' : 'missing',
    rule.title ? '資料タイトルを取得済み' : '資料タイトルを取得できていません',
    rule.title ? 0.05 : 0,
  );
  addFactor(
    '更新周期',
    rule.renewalCycleYears !== undefined ? 'confirmed' : 'missing',
    rule.renewalCycleYears !== undefined
      ? `${rule.renewalCycleYears}年として原文から抽出`
      : '更新周期を特定できていません',
    rule.renewalCycleYears !== undefined ? 0.15 : 0,
  );
  addFactor(
    '必要総単位',
    rule.requiredTotalCredits !== undefined ? 'confirmed' : 'missing',
    rule.requiredTotalCredits !== undefined
      ? `${rule.requiredTotalCredits}単位として原文から抽出`
      : '必要総単位を特定できていません',
    rule.requiredTotalCredits !== undefined ? 0.2 : 0,
  );

  if (rule.requirements.length >= 3) {
    addFactor('区分別・必須条件', 'confirmed', `${rule.requirements.length}件を数値と根拠付きで抽出`, 0.2);
  } else if (rule.requirements.length > 0) {
    addFactor('区分別・必須条件', 'partial', `${rule.requirements.length}件を抽出。資料全体との照合が必要`, 0.12);
  } else {
    addFactor('区分別・必須条件', 'missing', '数値付きの区分別条件を抽出できていません', 0);
  }

  addFactor(
    '必須事項',
    rule.mandatoryNotes.length > 0 ? 'confirmed' : 'partial',
    rule.mandatoryNotes.length > 0
      ? `${rule.mandatoryNotes.length}件の必須記載を抽出`
      : '必須事項の独立した記載は見つかっていません',
    rule.mandatoryNotes.length > 0 ? 0.1 : 0,
  );
  addFactor(
    '補足条件',
    rule.otherConditions.length > 0 ? 'confirmed' : 'partial',
    rule.otherConditions.length > 0
      ? `${rule.otherConditions.length}件の補足条件を抽出`
      : '補足条件の独立した記載は見つかっていません',
    rule.otherConditions.length > 0 ? 0.05 : 0,
  );

  if (
    rule.renewalCycleYears !== undefined &&
    rule.requiredTotalCredits !== undefined &&
    rule.requirements.length >= 2
  ) {
    addFactor('主要項目の整合性', 'confirmed', '周期・総単位・区分別条件が同じ資料内で揃っています', 0.03);
  }

  if (rule.warnings.length > 0) {
    const penalty = Math.min(0.15, rule.warnings.length * 0.05);
    addFactor(
      '自動抽出上の注意',
      'attention',
      `${rule.warnings.length}件の未確定項目があるため${Math.round(penalty * 100)}ポイント減点`,
      -penalty,
    );
  }

  const normalizedScore = Math.max(0, Math.min(0.98, Number(score.toFixed(2))));
  const summary = normalizedScore >= 0.95
    ? '主要項目と原文根拠が揃っています。公開前の最終照合のみ必要です。'
    : normalizedScore >= 0.8
      ? '主要項目は概ね揃っていますが、一部を公式資料で確認してください。'
      : normalizedScore >= 0.5
        ? '一部の条件は抽出できています。欠けている項目の補完が必要です。'
        : '重要項目が不足しています。このまま公開せず公式資料と照合してください。';
  return { version: 1, score: normalizedScore, summary, factors };
};

export const structureRenewalRule = (
  document: ExtractedDocument,
): { rule: StructuredRenewalRule; confidence: number } => {
  const blocks = textBlocks(document.text);
  const evidence = blocks
    .filter((block) => /(更新|認定期間|単位|必修|必須|診療実績)/u.test(block))
    .slice(0, 40);
  const renewalCycleYears = blocks
    .filter((block) => /(更新|認定期間|有効期間)/u.test(block))
    .flatMap((block) =>
      [...block.matchAll(/(\d+(?:\.\d+)?)\s*年(?:間|毎|ごと)?/gu)].map((match) =>
        Number.parseFloat(match[1]!),
      ),
    )
    .find((value) => value >= 1 && value <= 15);
  const requiredTotalCredits = totalCreditCandidate(blocks);
  const requirements = requirementCandidates(blocks);
  const mandatoryNotes = blocks
    .filter((block) => /必修|必須/u.test(block))
    .slice(0, 20);
  const otherConditions = blocks
    .filter((block) => /(勤務実態|診療実績|症例|更新料|申請書類|試験)/u.test(block))
    .slice(0, 20);
  const warnings: string[] = [];

  if (requiredTotalCredits === undefined) warnings.push('更新に必要な総単位を自動判定できませんでした');
  if (renewalCycleYears === undefined) warnings.push('更新周期を自動判定できませんでした');
  if (requirements.length === 0) warnings.push('区分別条件を自動判定できませんでした');
  if (document.title && /期限別|満了者|対象者|対象の方/u.test(document.title)) {
    warnings.push('特定の満了年度・対象者向け資料です。適用範囲の確認が必要です');
  }

  const rule: StructuredRenewalRule = {
    schemaVersion: 1,
    title: document.title,
    renewalCycleYears,
    requiredTotalCredits,
    requirements,
    otherConditions,
    mandatoryNotes,
    evidence,
    warnings,
  };
  const confidenceAssessment = confidenceAssessmentFor(rule);
  rule.confidenceAssessment = confidenceAssessment;
  return { rule, confidence: confidenceAssessment.score };
};

export const linksForDiscovery = (
  links: DiscoveredLink[],
  indexUrl: string,
  keywords: string[],
): DiscoveredLink[] => {
  const origin = new URL(indexUrl);
  const normalizedKeywords = keywords.map((value) => value.toLowerCase());
  const genericKeywords = new Set(['更新', '認定', '基準', '規則', '単位', '専門医']);
  const specificKeywords = normalizedKeywords.filter((value) => !genericKeywords.has(value));
  const requiredKeywords = specificKeywords.length > 0 ? specificKeywords : normalizedKeywords;
  return links
    .filter((link) => {
      const target = new URL(link.url);
      if (target.hostname !== origin.hostname) return false;
      const haystack = `${link.title} ${target.pathname}`.toLowerCase();
      const keywordMatch = requiredKeywords.some((keyword) => haystack.includes(keyword));
      return keywordMatch && (/\.pdf$/i.test(target.pathname) || /更新|認定|基準|規則/u.test(link.title));
    })
    .slice(0, 20);
};
