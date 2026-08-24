import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { db } = await import('../api/_lib/db.js');

interface CatalogEntry {
  name: string;
  organization: string;
  category: string;
  keywords: string[];
  parentQualification?: string;
}

interface SourceSeed {
  qualificationName: string | null;
  organizationName: string;
  title: string;
  url: string;
  systemType: string;
  isIndex: boolean;
  proposesRule?: boolean;
  keywords: string[];
  renewalYearFrom?: number;
  renewalYearTo?: number;
}

const stableId = (prefix: string, value: string): string =>
  `${prefix}_${createHash('sha256').update(value).digest('hex').slice(0, 16)}`;

const quotedValue = (block: string, field: string): string | undefined =>
  new RegExp(`${field}:\\s*'([^']+)'`, 'u').exec(block)?.[1];

const parseCatalog = (dart: string): CatalogEntry[] => {
  const start = dart.indexOf('const qualificationCatalog = <QualificationCatalogEntry>[');
  const end = dart.indexOf('\n];', start);
  if (start < 0 || end < 0) throw new Error('qualificationCatalog was not found');
  const catalogText = dart.slice(start, end);
  const entries: CatalogEntry[] = [];
  const entryPattern = /QualificationCatalogEntry\(\n([\s\S]*?)\n\s{2}\),/gu;

  for (const match of catalogText.matchAll(entryPattern)) {
    const block = match[1] || '';
    const name = quotedValue(block, 'name');
    const organization = quotedValue(block, 'organization');
    const category = quotedValue(block, 'category');
    if (!name || !organization || !category) continue;

    const keywordsSource = /keywords:\s*\[([^\]]*)\]/u.exec(block)?.[1] || '';
    const keywords = [...keywordsSource.matchAll(/'([^']+)'/gu)].map((item) => item[1]!);
    const literalParent = quotedValue(block, 'parentQualification');
    const constantParent = /parentQualification:\s*(\w+)/u.exec(block)?.[1];
    const parentQualification =
      literalParent ||
      (constantParent === 'surgeryBaseQualificationName'
        ? '外科専門医'
        : constantParent === 'internalMedicineBaseQualificationName'
          ? '内科専門医'
          : undefined);

    entries.push({ name, organization, category, keywords, parentQualification });
  }
  return entries;
};

const officialOrganizationUrls = new Map<string, string>([
  ['日本専門医機構', 'https://jmsb.or.jp/'],
  ['日本専門医機構／日本外科学会', 'https://www.jssoc.or.jp/'],
  ['日本専門医機構／日本内科学会', 'https://www.naika.or.jp/'],
  ['日本専門医機構／日本リハビリテーション医学会', 'https://www.jarm.or.jp/'],
  ['日本リハビリテーション医学会', 'https://www.jarm.or.jp/'],
]);

const officiallyConfirmedQualifications = new Set([
  '内科専門医',
  '小児科専門医',
  '皮膚科専門医',
  '精神科専門医',
  '外科専門医',
  '整形外科専門医',
  '産婦人科専門医',
  '眼科専門医',
  '耳鼻咽喉科専門医',
  '泌尿器科専門医',
  '脳神経外科専門医',
  '放射線科専門医',
  '麻酔科専門医',
  '病理専門医',
  '臨床検査専門医',
  '救急科専門医',
  '形成外科専門医',
  'リハビリテーション科専門医',
  '総合診療専門医',
]);

const dart = await readFile('lib/med_license_app.dart', 'utf8');
const entries = parseCatalog(dart);
if (entries.length < 40) throw new Error(`Only ${entries.length} catalog entries were parsed`);

const organizationNames = new Set(entries.map((entry) => entry.organization));
organizationNames.add('日本専門医機構');

for (const name of organizationNames) {
  const officialUrl = officialOrganizationUrls.get(name) || null;
  await db().query(
    `INSERT INTO organizations (id, name, official_url, verification_status)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       official_url = COALESCE(EXCLUDED.official_url, organizations.official_url),
       verification_status = CASE
         WHEN EXCLUDED.official_url IS NOT NULL THEN 'official_source_confirmed'
         ELSE organizations.verification_status
       END,
       updated_at = now()`,
    [
      stableId('org', name),
      name,
      officialUrl,
      officialUrl ? 'official_source_confirmed' : 'unverified',
    ],
  );
}

for (const entry of entries) {
  await db().query(
    `INSERT INTO qualifications (
       id, name, organization_id, category, keywords, verification_status
     ) VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       organization_id = EXCLUDED.organization_id,
       category = EXCLUDED.category,
       keywords = EXCLUDED.keywords,
       verification_status = EXCLUDED.verification_status,
       active = true,
       updated_at = now()`,
    [
      stableId('qual', entry.name),
      entry.name,
      stableId('org', entry.organization),
      entry.category,
      entry.keywords,
      officiallyConfirmedQualifications.has(entry.name)
        ? 'official_source_confirmed'
        : 'catalog_only',
    ],
  );
}

for (const entry of entries) {
  if (!entry.parentQualification) continue;
  await db().query(
    `UPDATE qualifications SET parent_qualification_id = $2, updated_at = now() WHERE id = $1`,
    [stableId('qual', entry.name), stableId('qual', entry.parentQualification)],
  );
}

const sources: SourceSeed[] = [
  {
    qualificationName: null,
    organizationName: '日本専門医機構',
    title: '日本専門医機構 専門医認定・更新基準',
    url: 'https://jmsb.or.jp/senmoni/',
    systemType: '日本専門医機構認定',
    isIndex: true,
    keywords: ['更新', '認定', '基準', '専門医'],
  },
  {
    qualificationName: null,
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医の更新要件（更新期限別一覧）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=113',
    systemType: '日本専門医機構認定',
    isIndex: true,
    keywords: ['新専門医', '更新要件', '有効期限'],
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科領域 専門医更新基準 2024',
    url: 'https://www.jssoc.or.jp/uploads/files/specialist/update-criterion_2024.pdf',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医更新要件（2026年12月31日満了）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=114',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
    renewalYearFrom: 2026,
    renewalYearTo: 2026,
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医更新要件（2027年12月31日満了）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=115',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
    renewalYearFrom: 2027,
    renewalYearTo: 2027,
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医更新要件（2028年12月31日満了）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=116',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
    renewalYearFrom: 2028,
    renewalYearTo: 2028,
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医更新要件（2029年12月31日満了）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=121',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
    renewalYearFrom: 2029,
    renewalYearTo: 2029,
  },
  {
    qualificationName: '外科専門医',
    organizationName: '日本専門医機構／日本外科学会',
    title: '外科専門医 新専門医更新要件（2030年12月31日満了）',
    url: 'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=134',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
    renewalYearFrom: 2030,
    renewalYearTo: 2030,
  },
  {
    qualificationName: '内科専門医',
    organizationName: '日本専門医機構／日本内科学会',
    title: '日本専門医機構認定 内科専門医の認定と更新',
    url: 'https://www.naika.or.jp/ninteikoshin-naikasenmoni/',
    systemType: '日本専門医機構認定',
    isIndex: true,
    keywords: ['更新', '認定', '単位'],
  },
  {
    qualificationName: '内科専門医',
    organizationName: '日本専門医機構／日本内科学会',
    title: '内科専門医 認定更新案内（2027年3月31日満了者）',
    url: 'https://www.naika.or.jp/wp-content/uploads/2026/04/a6b856635cd7d04da3f234986d554b23.pdf',
    systemType: '日本専門医機構認定',
    isIndex: false,
    keywords: [],
  },
  {
    qualificationName: 'リハビリテーション科専門医',
    organizationName: '日本専門医機構／日本リハビリテーション医学会',
    title: 'リハビリテーション科専門医 更新案内',
    url: 'https://www.jarm.or.jp/member/system/specialist_renewal.html',
    systemType: '日本専門医機構認定',
    isIndex: true,
    keywords: ['専門医更新', '更新基準', '履修単位'],
  },
  {
    qualificationName: '認定臨床医',
    organizationName: '日本リハビリテーション医学会',
    title: '日本リハビリテーション医学会 規則・細則',
    url: 'https://www.jarm.or.jp/jarm/rules.html',
    systemType: '学会認定',
    isIndex: true,
    proposesRule: false,
    keywords: ['認定臨床医', '履修項目', '資格更新'],
  },
  {
    qualificationName: '認定臨床医',
    organizationName: '日本リハビリテーション医学会',
    title: 'V-11 認定臨床医の生涯教育及び資格更新に関する内規',
    url: 'https://www.jarm.or.jp/jarm/document/rules/05/5-11.pdf',
    systemType: '学会認定',
    isIndex: false,
    proposesRule: true,
    keywords: [],
  },
  {
    qualificationName: '認定臨床医',
    organizationName: '日本リハビリテーション医学会',
    title: 'V-12 認定臨床医の資格更新に関する申し合わせ',
    url: 'https://www.jarm.or.jp/jarm/document/rules/05/5-12.pdf',
    systemType: '学会認定',
    isIndex: false,
    proposesRule: false,
    keywords: [],
  },
  {
    qualificationName: '認定臨床医',
    organizationName: '日本リハビリテーション医学会',
    title: 'V-13 別表 認定臨床医生涯教育の履修項目及び単位',
    url: 'https://www.jarm.or.jp/jarm/document/rules/05/5-13.pdf',
    systemType: '学会認定',
    isIndex: false,
    proposesRule: false,
    keywords: [],
  },
];

for (const source of sources) {
  await db().query(
    `INSERT INTO source_documents (
       qualification_id, organization_id, title, source_url, system_type,
       renewal_year_from, renewal_year_to,
       media_type, is_index, proposes_rule, discovery_keywords, fetch_interval_hours
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'auto', $8, $9, $10, 168)
     ON CONFLICT (source_url) DO UPDATE SET
       qualification_id = EXCLUDED.qualification_id,
       organization_id = EXCLUDED.organization_id,
       title = EXCLUDED.title,
       system_type = EXCLUDED.system_type,
       renewal_year_from = EXCLUDED.renewal_year_from,
       renewal_year_to = EXCLUDED.renewal_year_to,
       is_index = EXCLUDED.is_index,
       proposes_rule = EXCLUDED.proposes_rule,
       discovery_keywords = EXCLUDED.discovery_keywords,
       active = true,
       updated_at = now()`,
    [
      source.qualificationName ? stableId('qual', source.qualificationName) : null,
      stableId('org', source.organizationName),
      source.title,
      source.url,
      source.systemType,
      source.renewalYearFrom ?? null,
      source.renewalYearTo ?? null,
      source.isIndex,
      source.proposesRule ?? !source.isIndex,
      source.keywords,
    ],
  );
}

const directSurgeryRuleUrls = sources
  .filter((source) => source.qualificationName === '外科専門医')
  .map((source) => source.url);
await db().query(
  `UPDATE source_documents
      SET qualification_id = NULL,
          updated_at = now()
    WHERE qualification_id = $1
      AND source_url <> ALL($2::text[])`,
  [stableId('qual', '外科専門医'), directSurgeryRuleUrls],
);

const recognizedClinicalPhysicianRuleUrl =
  'https://www.jarm.or.jp/jarm/document/rules/05/5-11.pdf';
await db().query(
  `UPDATE renewal_rule_versions rv
      SET status = 'rejected',
          reviewed_at = now(),
          review_note = '規則一覧ページのみの抽出候補を除外しました。更新条件は公式PDF V-11を主資料として再取得します。',
          reviewed_by = 'system-source-cleanup'
     FROM source_snapshots ss
     JOIN source_documents sd ON sd.id = ss.source_document_id
    WHERE rv.source_snapshot_id = ss.id
      AND rv.qualification_id = $1
      AND rv.status = 'pending_review'
      AND sd.source_url <> $2`,
  [stableId('qual', '認定臨床医'), recognizedClinicalPhysicianRuleUrl],
);

await db().query(
  `UPDATE renewal_rule_versions rv
      SET renewal_year_from = sd.renewal_year_from,
          renewal_year_to = sd.renewal_year_to
     FROM source_snapshots ss
     JOIN source_documents sd ON sd.id = ss.source_document_id
    WHERE rv.source_snapshot_id = ss.id
      AND (
        rv.renewal_year_from IS DISTINCT FROM sd.renewal_year_from
        OR rv.renewal_year_to IS DISTINCT FROM sd.renewal_year_to
      )`,
);

console.log(`Seeded ${entries.length} qualifications and ${sources.length} official sources`);
