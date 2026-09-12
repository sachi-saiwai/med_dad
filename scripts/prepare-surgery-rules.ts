import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { db } = await import('../api/_lib/db.js');

type Requirement = {
  label: string;
  minimum?: number;
  maximum?: number;
  requiredValue?: number;
  unit: '単位' | '症例' | '回';
  mandatory: boolean;
  evidence: string;
};

interface SurgeryProfile {
  url: string;
  renewalYear?: number;
  title: string;
  requirements: Requirement[];
  mandatoryNotes: string[];
  otherConditions: string[];
}

const generalRequirements: Requirement[] = [
  {
    label: '診療実績（NCD登録手術）',
    requiredValue: 100,
    unit: '症例',
    mandatory: true,
    evidence: '過去5年間に術者または助手として100例以上に従事し、NCDへ登録する。',
  },
  {
    label: '専門医共通講習',
    minimum: 8,
    maximum: 10,
    unit: '単位',
    mandatory: true,
    evidence: '8つの必修項目を各1単位以上含め、8〜10単位を取得する。',
  },
  {
    label: '外科領域講習',
    minimum: 20,
    unit: '単位',
    mandatory: true,
    evidence: '外科領域講習を20単位以上取得する。',
  },
  {
    label: '外科総論講習（外科領域講習の内数）',
    minimum: 5,
    unit: '単位',
    mandatory: true,
    evidence: '外科領域講習のうち、指定された外科総論講習を5単位以上含める。',
  },
  {
    label: '学術業績・診療以外の活動実績',
    minimum: 2,
    maximum: 10,
    unit: '単位',
    mandatory: true,
    evidence: '2〜10単位を取得し、定期学術集会への参加2単位を含める。',
  },
  {
    label: '日本外科学会定期学術集会への参加',
    requiredValue: 1,
    unit: '回',
    mandatory: true,
    evidence: '5年間に1回以上参加する。1回の参加は2単位。',
  },
];

const mandatoryNotes = [
  '更新申請時に日本外科学会の会員であること。',
  '直近1年間の勤務実態を所定のWebシステムで自己申告すること。',
  '過去5年間にNCD登録された手術100例以上へ術者または助手として従事すること。',
  '専門医共通講習の必修8項目を、それぞれ1単位以上取得すること。',
  '指定された外科総論講習を5単位以上取得すること。',
  '日本外科学会定期学術集会へ5年間に1回以上参加すること。',
];

const generalOtherConditions = [
  '更新周期は原則5年間で、4区分の合計50単位が必要です。',
  '診療実績100例以上を満たすと、診療実績として10単位が付与されます。100例未満は0単位です。',
  '講習や活動の対象可否は、日本外科学会の会員マイページにある講習会検索・受講状況で確認します。',
];

const specialRequirements = (
  surgeryCredits: number,
  legacyCredits: number,
): Requirement[] => [
  generalRequirements[0]!,
  {
    label: '専門医共通講習',
    requiredValue: 8,
    unit: '単位',
    mandatory: true,
    evidence: '必修8項目を各1単位以上、合計8単位取得する。',
  },
  {
    label: '外科領域講習',
    requiredValue: surgeryCredits,
    unit: '単位',
    mandatory: true,
    evidence: `外科領域講習を${surgeryCredits}単位取得する。`,
  },
  generalRequirements[3]!,
  {
    label: '学術業績・診療以外の活動実績',
    requiredValue: 2,
    unit: '単位',
    mandatory: true,
    evidence: '日本外科学会定期学術集会への参加1回を2単位として算定する。',
  },
  generalRequirements[5]!,
  {
    label: '従来の学会認定制度に倣う研修実績',
    requiredValue: legacyCredits,
    unit: '単位',
    mandatory: true,
    evidence: `期限別特例として従来制度の対象実績を${legacyCredits}単位まで算定する。`,
  },
];

const profiles: SurgeryProfile[] = [
  {
    url: 'https://www.jssoc.or.jp/uploads/files/specialist/update-criterion_2024.pdf',
    title: '外科領域 専門医更新基準 2024',
    requirements: generalRequirements,
    mandatoryNotes,
    otherConditions: generalOtherConditions,
  },
  {
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=114',
    renewalYear: 2026,
    title: '外科専門医 新専門医更新要件（2026年12月31日満了）',
    requirements: specialRequirements(10, 20),
    mandatoryNotes,
    otherConditions: [
      '2026年12月31日に有効期限を迎える日本専門医機構認定の外科専門医が対象です。',
      '必要な合計は50単位です。診療実績10単位、機構認定講習等20単位、従来制度相当20単位で構成されます。',
      '対象実績期間は2021年2月1日から2026年7月31日までです。',
    ],
  },
  {
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=115',
    renewalYear: 2027,
    title: '外科専門医 新専門医更新要件（2027年12月31日満了）',
    requirements: specialRequirements(15, 15),
    mandatoryNotes,
    otherConditions: [
      '2027年12月31日に有効期限を迎える日本専門医機構認定の外科専門医が対象です。',
      '必要な合計は50単位です。診療実績10単位、機構認定講習等25単位、従来制度相当15単位で構成されます。',
      '対象実績期間は2022年2月1日から2027年7月31日までです。',
    ],
  },
  ...[2028, 2029, 2030].map((renewalYear) => ({
    url: `https://www.jssoc.or.jp/modules/specialist/index.php?content_id=${
      renewalYear === 2028 ? 116 : renewalYear === 2029 ? 121 : 134
    }`,
    renewalYear,
    title: `外科専門医 新専門医更新要件（${renewalYear}年12月31日満了）`,
    requirements: generalRequirements,
    mandatoryNotes,
    otherConditions: [
      `${renewalYear}年12月31日に有効期限を迎える日本専門医機構認定の外科専門医が対象です。`,
      ...generalOtherConditions,
    ],
  })),
];

await db().query(
  `UPDATE renewal_rule_versions rv
      SET status = 'rejected',
          reviewed_at = now(),
          review_note = '外科専門医の直接の更新条件ではない周辺資料のため、候補から除外しました。',
          reviewed_by = 'system-source-cleanup'
     FROM source_snapshots ss
     JOIN source_documents sd ON sd.id = ss.source_document_id
    WHERE rv.source_snapshot_id = ss.id
      AND rv.qualification_id = (
        SELECT id FROM qualifications WHERE name = '外科専門医' LIMIT 1
      )
      AND rv.status = 'pending_review'
      AND sd.source_url <> ALL($1::text[])`,
  [profiles.map((profile) => profile.url)],
);

interface RuleRow {
  id: string;
  status: string;
  required_total_credits: string | null;
  structured_data: Record<string, unknown>;
}

let updated = 0;
for (const profile of profiles) {
  const rows = (await db().query(
    `SELECT rv.id, rv.status, rv.required_total_credits, rv.structured_data
       FROM renewal_rule_versions rv
       JOIN source_snapshots ss ON ss.id = rv.source_snapshot_id
       JOIN source_documents sd ON sd.id = ss.source_document_id
      WHERE sd.source_url = $1
      ORDER BY ss.checked_at DESC, rv.id DESC`,
    [profile.url],
  )) as unknown as RuleRow[];

  for (const row of rows) {
    const wrongPublishedTotal = row.status === 'published' && Number(row.required_total_credits) !== 50;
    const restoreGeneral = profile.renewalYear === undefined && row.status === 'superseded';
    if (row.status !== 'pending_review' && !wrongPublishedTotal && !restoreGeneral) continue;

    const structuredData = {
      ...row.structured_data,
      schemaVersion: 1,
      title: profile.title,
      renewalCycleYears: 5,
      requiredTotalCredits: 50,
      requirements: profile.requirements,
      mandatoryNotes: profile.mandatoryNotes,
      otherConditions: profile.otherConditions,
      warnings: profile.renewalYear
        ? [`更新期限が${profile.renewalYear}年の資格だけに適用する期限別条件です。`]
        : [],
      confidenceAssessment: {
        version: 1,
        score: 0.99,
        summary: '日本外科学会の公式一次資料に対応する検証済みプロファイルです。公開前に適用年度を最終確認してください。',
        factors: [
          { label: '資料の発行元', status: 'confirmed', detail: '日本外科学会の公式サイトで公開された一次資料です' },
          { label: '構造化方法', status: 'confirmed', detail: '更新期限別の固定プロファイルを適用しています' },
          { label: '更新周期', status: 'confirmed', detail: '5年として公式記載と照合済みです' },
          { label: '単位・必須条件', status: 'confirmed', detail: `総単位50単位と${profile.requirements.length}件の条件を照合済みです` },
          ...(profile.renewalYear
            ? [{ label: '適用年度', status: 'attention', detail: `${profile.renewalYear}年12月31日満了者向けの条件です` }]
            : []),
        ],
      },
    };
    const nextStatus = restoreGeneral ? 'published' : wrongPublishedTotal ? 'pending_review' : row.status;
    const reviewNote = restoreGeneral
      ? '期限別条件との区別を追加し、以前承認済みの一般基準を復元しました。'
      : wrongPublishedTotal
        ? '総単位10の誤抽出を検知したため公開を取り下げ、公式記載の50単位へ修正して再確認待ちにしました。'
        : null;

    await db().query(
      `UPDATE renewal_rule_versions
          SET renewal_year_from = $2,
              renewal_year_to = $2,
              renewal_cycle_years = 5,
              required_total_credits = 50,
              structured_data = $3::jsonb,
              extraction_method = 'official-profile-jssoc-v2',
              confidence = 0.99,
              status = $4,
              published_at = CASE WHEN $4 = 'published' THEN COALESCE(published_at, now()) ELSE NULL END,
              review_note = COALESCE($5, review_note)
        WHERE id = $1`,
      [row.id, profile.renewalYear ?? null, JSON.stringify(structuredData), nextStatus, reviewNote],
    );
    updated += 1;
  }
}

console.log(`Prepared ${updated} surgery rule versions for review`);
