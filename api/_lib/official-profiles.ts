import type { StructuredRenewalRule } from './extract.js';

interface ProfileResult {
  rule: StructuredRenewalRule;
  confidence: number;
  extractionMethod: string;
}

const recognizedClinicalPhysicianUrl =
  'https://www.jarm.or.jp/jarm/document/rules/05/5-11.pdf';

export const applyOfficialSourceProfile = (
  sourceUrl: string,
  fallback: { rule: StructuredRenewalRule; confidence: number },
): ProfileResult => {
  if (sourceUrl !== recognizedClinicalPhysicianUrl) {
    return {
      ...fallback,
      extractionMethod: 'deterministic-v2',
    };
  }

  return {
    extractionMethod: 'official-profile-jarm-v1',
    confidence: 0.95,
    rule: {
      schemaVersion: 1,
      title: '認定臨床医の生涯教育及び資格更新に関する内規',
      renewalCycleYears: 5,
      requiredTotalCredits: 200,
      requirements: [
        {
          label: '年次・秋季・地方会いずれかの学術集会参加',
          requiredValue: 1,
          unit: '回',
          mandatory: true,
          evidence:
            'V-11第2条第2項(3)：年次学術集会、秋季学術集会、地方会学術集会いずれかの参加による単位を必須とする。',
        },
      ],
      mandatoryNotes: [
        '5年間に200単位を履修する必要があります。',
        '年次学術集会・秋季学術集会・地方会学術集会のいずれかへの参加による単位が必須です。',
      ],
      otherConditions: [
        '学会参加、教育研修講演等の受講、論文、学会発表等が履修対象です。',
        '年次・秋季学術集会は20単位、地方会学術集会は10単位です（V-13別表）。',
        '単位不足時は資格喪失日の翌日から2年間、更新を保留できる場合があります（V-12）。',
        '留学、疾病、出産等により研修を受講できない場合は、所定の手続で更新猶予を申請できます（V-12）。',
        '年齢、認定歴、会員歴等の条件により認定臨床医（終身）となる規定があります。',
      ],
      evidence: fallback.rule.evidence,
      warnings: [
        'V-11を主資料、V-12を更新手続・猶予、V-13を単位表の補足資料として構造化しています。公開前に3資料を確認してください。',
      ],
    },
  };
};
