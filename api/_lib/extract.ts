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

  let confidence = 0.15;
  if (requiredTotalCredits !== undefined) confidence += 0.25;
  if (renewalCycleYears !== undefined) confidence += 0.15;
  if (requirements.length >= 2) confidence += 0.2;
  if (mandatoryNotes.length > 0) confidence += 0.1;
  if (otherConditions.length > 0) confidence += 0.05;
  if (warnings.length > 0) confidence -= Math.min(0.2, warnings.length * 0.05);

  return {
    rule: {
      schemaVersion: 1,
      title: document.title,
      renewalCycleYears,
      requiredTotalCredits,
      requirements,
      otherConditions,
      mandatoryNotes,
      evidence,
      warnings,
    },
    confidence: Math.max(0, Math.min(0.9, confidence)),
  };
};

export const linksForDiscovery = (
  links: DiscoveredLink[],
  indexUrl: string,
  keywords: string[],
): DiscoveredLink[] => {
  const origin = new URL(indexUrl);
  const normalizedKeywords = keywords.map((value) => value.toLowerCase());
  return links
    .filter((link) => {
      const target = new URL(link.url);
      if (target.hostname !== origin.hostname) return false;
      const haystack = `${link.title} ${target.pathname}`.toLowerCase();
      const keywordMatch = normalizedKeywords.some((keyword) => haystack.includes(keyword));
      return keywordMatch && (/\.pdf$/i.test(target.pathname) || /更新|認定|基準|規則/u.test(link.title));
    })
    .slice(0, 20);
};
