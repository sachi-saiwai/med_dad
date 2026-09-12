import type {
  ConfidenceAssessment,
  StructuredRenewalRule,
} from './extract.js';

interface ProfileResult {
  rule: StructuredRenewalRule;
  confidence: number;
  extractionMethod: string;
}

type Requirement = StructuredRenewalRule['requirements'][number];

interface OfficialProfile {
  title: string;
  renewalCycleYears: number;
  requiredTotalCredits?: number;
  requirements: Requirement[];
  mandatoryNotes: string[];
  otherConditions: string[];
  warnings?: string[];
  confidence?: number;
  extractionMethod: string;
}

const recognizedClinicalPhysicianUrl =
  'https://www.jarm.or.jp/jarm/document/rules/05/5-11.pdf';

const internalMedicineRequirements: Requirement[] = [
  {
    label: '診療実績の証明（セルフトレーニング問題）',
    requiredValue: 10,
    unit: '単位',
    mandatory: true,
    evidence: 'セルフトレーニング問題で原則60％以上正解し、診療実績の証明として10単位を取得する。',
  },
  {
    label: '専門医共通講習',
    minimum: 3,
    maximum: 10,
    unit: '単位',
    mandatory: true,
    evidence: '専門医共通講習を3〜10単位取得する。医療倫理・感染対策・医療安全を含む。',
  },
  {
    label: '内科領域講習',
    minimum: 20,
    unit: '単位',
    mandatory: true,
    evidence: '内科領域講習を20単位以上取得する。',
  },
  {
    label: '学術業績・診療以外の活動実績',
    minimum: 2,
    maximum: 10,
    unit: '単位',
    mandatory: true,
    evidence: '学会活動・地域活動等を2〜10単位取得する。',
  },
];

const internalMedicineMandatoryNotes = [
  '更新年度1年間の勤務実態を自己申告すること。',
  'セルフトレーニング問題で原則60％以上正解し、診療実績を証明すること。',
  '必須区分を含む合計50単位以上を取得すること。',
  '日本内科学会の会員資格を継続していること。',
];

const surgeryGeneralRequirements: Requirement[] = [
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
    evidence: '必修8項目を各1単位以上含め、8〜10単位を取得する。',
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

const surgeryMandatoryNotes = [
  '更新申請時に日本外科学会の会員であること。',
  '直近1年間の勤務実態を所定のWebシステムで自己申告すること。',
  '過去5年間にNCD登録された手術100例以上へ術者または助手として従事すること。',
  '専門医共通講習の必修8項目を、それぞれ1単位以上取得すること。',
  '指定された外科総論講習を5単位以上取得すること。',
  '日本外科学会定期学術集会へ5年間に1回以上参加すること。',
];

const surgeryOtherConditions = [
  '更新周期は原則5年間で、4区分の合計50単位が必要です。',
  '診療実績100例以上を満たすと、診療実績として10単位が付与されます。100例未満は0単位です。',
  '講習や活動の対象可否は、日本外科学会の会員マイページにある講習会検索・受講状況で確認します。',
];

const surgeryProfile = (
  title: string,
  renewalYear?: number,
): OfficialProfile => ({
  title,
  renewalCycleYears: 5,
  requiredTotalCredits: 50,
  requirements: surgeryGeneralRequirements,
  mandatoryNotes: surgeryMandatoryNotes,
  otherConditions: renewalYear
    ? [
        `${renewalYear}年12月31日に有効期限を迎える日本専門医機構認定の外科専門医が対象です。`,
        ...surgeryOtherConditions,
      ]
    : surgeryOtherConditions,
  warnings: renewalYear
    ? [`更新期限が${renewalYear}年の資格だけに適用する期限別条件です。`]
    : [],
  confidence: 0.99,
  extractionMethod: 'official-profile-jssoc-v2',
});

const profiles = new Map<string, OfficialProfile>([
  [
    'https://www.naika.or.jp/ninteikoshin-naikasenmoni/',
    {
      title: '日本専門医機構認定 内科専門医の認定と更新',
      renewalCycleYears: 5,
      requiredTotalCredits: 50,
      requirements: internalMedicineRequirements,
      mandatoryNotes: internalMedicineMandatoryNotes,
      otherConditions: [
        '更新審査は日本内科学会の一次審査後、日本専門医機構の二次審査を受けます。',
        '更新料は日本内科学会5,000円と日本専門医機構11,000円の合計16,000円です。',
      ],
      confidence: 0.99,
      extractionMethod: 'official-profile-naika-v1',
    },
  ],
  [
    'https://www.naika.or.jp/wp-content/uploads/2026/04/a6b856635cd7d04da3f234986d554b23.pdf',
    {
      title: '内科専門医 認定更新案内（2027年3月31日満了者）',
      renewalCycleYears: 5,
      requiredTotalCredits: 50,
      requirements: internalMedicineRequirements,
      mandatoryNotes: internalMedicineMandatoryNotes,
      otherConditions: [
        '2027年3月31日に認定期間が満了する内科専門医が対象です。',
        '更新手続き期間は2026年8月から2027年3月31日までです。',
        '更新料16,000円を一括納入します。',
      ],
      warnings: ['更新期限が2027年3月31日の資格だけに適用する案内です。'],
      confidence: 0.99,
      extractionMethod: 'official-profile-naika-2027-v1',
    },
  ],
  [
    'https://www.jarm.or.jp/member/system/specialist_renewal.html',
    {
      title: 'リハビリテーション科専門医 更新基準',
      renewalCycleYears: 5,
      requiredTotalCredits: 50,
      requirements: [
        {
          label: '診療実績の証明',
          requiredValue: 100,
          unit: '症例',
          mandatory: true,
          evidence: '5年間に診療した100症例を提示し、9領域のうち3領域以上を含める。更新単位では10単位として算定する。',
        },
        {
          label: '専門医共通講習',
          minimum: 8,
          maximum: 10,
          unit: '単位',
          mandatory: true,
          evidence: '共通講習を8〜10単位取得し、必修講習A・Bの8項目を各1単位以上含める。',
        },
        {
          label: 'リハビリテーション科領域講習',
          minimum: 20,
          unit: '単位',
          mandatory: true,
          evidence: 'リハビリテーション科領域講習を20単位以上取得する。',
        },
        {
          label: '指導医講習会',
          requiredValue: 1,
          unit: '回',
          mandatory: true,
          evidence: '更新までの5年間に指導医講習会を1回（2単位）以上受講する。',
        },
        {
          label: '学術業績・診療以外の活動実績',
          minimum: 4,
          maximum: 10,
          unit: '単位',
          mandatory: true,
          evidence: '学術業績・診療以外の活動実績を4〜10単位取得する。',
        },
        {
          label: '指定学術集会への参加',
          requiredValue: 2,
          unit: '回',
          mandatory: true,
          evidence: '5年間に年次学術集会と秋季学術集会へ各1回以上参加する。',
        },
      ],
      mandatoryNotes: [
        '直近1年間の勤務実態を自己申告すること。',
        '5年間の診療症例100例を提出し、9領域のうち3領域以上を含めること。',
        '4区分の合計50単位を取得すること。',
        '2027年度以降の更新では、所定期間内にe-テストを受け全問正解すること。',
      ],
      otherConditions: [
        '単位取得状況と申請書類を日本リハビリテーション医学会へ提出します。',
        '特別な理由で更新できない場合の措置は別添資料に定められています。',
      ],
      confidence: 0.99,
      extractionMethod: 'official-profile-jarm-specialist-v1',
    },
  ],
  [
    'https://www.jssoc.or.jp/uploads/files/specialist/update-criterion_2024.pdf',
    surgeryProfile('外科領域 専門医更新基準 2024'),
  ],
  [
    'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=114',
    surgeryProfile('外科専門医 新専門医更新要件（2026年12月31日満了）', 2026),
  ],
  [
    'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=115',
    surgeryProfile('外科専門医 新専門医更新要件（2027年12月31日満了）', 2027),
  ],
  [
    'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=116',
    surgeryProfile('外科専門医 新専門医更新要件（2028年12月31日満了）', 2028),
  ],
  [
    'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=121',
    surgeryProfile('外科専門医 新専門医更新要件（2029年12月31日満了）', 2029),
  ],
  [
    'https://www.jssoc.or.jp/modules/specialist/index.php?content_id=134',
    surgeryProfile('外科専門医 新専門医更新要件（2030年12月31日満了）', 2030),
  ],
  [
    'https://www.jsgs.or.jp/senmon/others/senmon_shidoi_koshin/',
    {
      title: '消化器外科専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '消化器外科手術経験', requiredValue: 100, unit: '症例', mandatory: true, evidence: '最近5年間に術者又は助手として100例以上。2011年以降はNCD登録症例に限る。' },
        { label: '日本消化器外科学会の総会又は大会', requiredValue: 2, unit: '回', mandatory: true, evidence: '最近5年間に本学会総会又は大会へ2回参加する。' },
        { label: '日本外科学会定期学術集会', requiredValue: 1, unit: '回', mandatory: true, evidence: '最近5年間に日本外科学会定期学術集会へ1回参加する。' },
        { label: '教育講座（異なる4領域）', requiredValue: 4, unit: '回', mandatory: true, evidence: '最近5年度に総論・がん診療を含む異なる4領域のeラーニングを受講する。' },
      ],
      mandatoryNotes: ['外科専門医または日本外科学会認定登録医であることが必要です。'],
      otherConditions: ['参加証・受講証による証明が必要です。', '研修実績の対象期間は申請年の7月31日までの最近5年間です。'],
      extractionMethod: 'official-profile-jsgs-v1',
    },
  ],
  [
    'https://chest.umin.jp/std/std_apl_kou.html',
    {
      title: '呼吸器外科専門医の更新条件',
      renewalCycleYears: 5,
      requiredTotalCredits: 20,
      requirements: [
        { label: '呼吸器外科手術経験', requiredValue: 100, unit: '症例', mandatory: true, evidence: '5年間に術者又は助手として100例以上。' },
        { label: '指定学会・セミナー参加', requiredValue: 4, unit: '回', mandatory: true, evidence: '呼吸器外科学会、胸部外科学会または指定セミナーに合計4回以上参加する。' },
        { label: '日本外科学会定期学術集会', requiredValue: 1, unit: '回', mandatory: true, evidence: '日本外科学会定期学術集会へ1回以上参加する。' },
        { label: '医療安全等の研修', requiredValue: 2, unit: '回', mandatory: true, evidence: '参加証明が可能な医療安全等の研修を2回以上受講する。' },
        { label: '論文・著書', requiredValue: 2, unit: '件', mandatory: true, evidence: '査読制度のある全国誌以上の論文等を2編以上。' },
      ],
      mandatoryNotes: ['基礎条件とは別に、規定の単位表による20単位以上が必要です。'],
      otherConditions: ['基礎条件に使用した実績は、20単位の単位条件へ重複使用できません。', '追加単位は手術5件=1単位、論文1編=5単位、学会発表・座長等1回=1単位などで算定されます。'],
      extractionMethod: 'official-profile-thoracic-v1',
    },
  ],
  [
    'https://jcvs.jp/senmoni/shinsei/koushin/',
    {
      title: '2026年度 心臓血管外科専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '構成3学会の学術集会', requiredValue: 5, unit: '回', mandatory: true, evidence: '構成3学会のいずれかが主催する学術集会に5回以上参加する。' },
        { label: '日本外科学会定期学術集会', requiredValue: 1, unit: '回', mandatory: true, evidence: '日本外科学会定期学術集会に1回以上参加する。' },
        { label: '指定セミナー・Postgraduate Course等', requiredValue: 3, unit: '回', mandatory: true, evidence: '認定機構が認めるセミナー等に3回以上参加する。' },
        { label: '医療安全講習会', requiredValue: 2, unit: '回', mandatory: true, evidence: '認定機構が認める医療安全講習会を2回以上受講する。' },
        { label: '指導医講習会', requiredValue: 1, unit: '回', mandatory: true, evidence: '認定機構が認める指導医講習会を1回以上受講する。' },
        { label: '心臓血管外科関連論文', requiredValue: 3, unit: '件', mandatory: true, evidence: '査読制度のある全国誌以上の掲載論文等を3編以上。' },
        { label: '手術経験（換算）', requiredValue: 100, unit: '症例', mandatory: true, evidence: '術者又は指導的助手として難易度表による換算100例以上。' },
      ],
      mandatoryNotes: ['外科専門医と心臓血管外科専門医の両資格が必要です。', '構成3学会のうち少なくとも2学会で、引き続き5年間の会員歴が必要です。'],
      otherConditions: ['初回更新者は手術経験のうち換算50例以上が難易度B又はCである必要があります。', '2026年度申請の業績対象期間は原則2021年9月1日〜2026年8月31日です。'],
      extractionMethod: 'official-profile-jcvs-2026-v1',
    },
  ],
  [
    'https://jcvs.jp/newseido/',
    {
      title: '2028年度以降 心臓血管外科専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '専門医共通講習', requiredValue: 10, unit: '単位', mandatory: true, evidence: '2028年度以降は共通講習10単位以上。必修A・Bの8単位を含む。' },
        { label: '外科領域講習', requiredValue: 20, unit: '単位', mandatory: true, evidence: '外科総論e-learning 5単位と4領域各1単位を含む20単位以上。' },
        { label: '構成3学会の学術集会', requiredValue: 5, unit: '回', mandatory: true, evidence: '構成3学会の学術集会に5回以上参加する。' },
        { label: '日本外科学会定期学術集会', requiredValue: 1, unit: '回', mandatory: true, evidence: '日本外科学会定期学術集会に1回以上参加する。' },
        { label: '医療安全講習会', requiredValue: 2, unit: '回', mandatory: true, evidence: '構成3学会開催の医療安全講習会を2回受講する。' },
        { label: '指導医講習会', requiredValue: 1, unit: '回', mandatory: true, evidence: '認定機構が認める指導医講習会を1回以上受講する。' },
        { label: '心臓血管外科関連論文', requiredValue: 3, unit: '件', mandatory: true, evidence: '心臓血管外科関連論文を3編以上発表する。' },
        { label: '手術経験（換算）', requiredValue: 100, unit: '症例', mandatory: true, evidence: '別に定める手術要件を満たす。' },
      ],
      mandatoryNotes: ['外科領域講習は外科総論e-learning 5単位とA・C・V・E各領域1単位以上を含みます。'],
      otherConditions: ['2028年度から最長5年間は、従来のセミナー受講回数を外科領域講習単位へ読み替える移行措置があります。'],
      warnings: ['更新期限が2028年以降の資格にだけ適用する変更基準です。'],
      extractionMethod: 'official-profile-jcvs-2028-v1',
    },
  ],
  [
    'https://jmsb.or.jp/wp-content/uploads/2026/03/gaiho_2025.pdf',
    {
      title: '小児外科専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '所定の学術集会・研究会', requiredValue: 5, unit: '回', mandatory: true, evidence: '最近5年間に所定の学術集会・研究会へ5回以上参加する。' },
        { label: '日本小児外科学会企画', requiredValue: 3, unit: '回', mandatory: true, evidence: '上記のうち学術集会、秋季シンポジウム、卒後教育セミナーへ3回以上参加する。' },
      ],
      mandatoryNotes: ['参加を証明する書類の提出が必要です。'],
      otherConditions: ['日本専門医機構の令和7年度概報に掲載された現行の学会認定更新条件です。'],
      warnings: ['日本小児外科学会の更新案内が公開された場合は、その内容を優先して再確認してください。'],
      confidence: 0.97,
      extractionMethod: 'official-profile-jsps-overview-v1',
    },
  ],
  [
    'https://www.jbcs.gr.jp/modules/elearning/index.php?content_id=13',
    {
      title: '乳腺専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '乳癌症例の診療経験', requiredValue: 100, unit: '症例', mandatory: true, evidence: '過去5年間に100例以上の乳癌症例の診療経験を有する。' },
        { label: '研究業績', requiredValue: 8, unit: '単位', mandatory: true, evidence: '過去5年間に業績点数表で8点以上。' },
        { label: '研修実績', requiredValue: 30, unit: '単位', mandatory: true, evidence: '過去5年間に研修実績点数表で30点以上。' },
      ],
      mandatoryNotes: ['日本乳癌学会の会員を継続していることが必要です。'],
      otherConditions: ['この条件は学会認定の「乳腺専門医」用であり、新制度の「乳腺外科専門医」へは適用しません。'],
      extractionMethod: 'official-profile-jbcs-v1',
    },
  ],
  [
    'https://jaes.umin.jp/nintei/specialist/specialist_bylaws.pdf',
    {
      title: '内分泌外科専門医の更新条件',
      renewalCycleYears: 5,
      requirements: [
        { label: '研究業績', requiredValue: 8, unit: '単位', mandatory: true, evidence: '直近5年間に研究業績点数表で8点以上。' },
        { label: '研修実績', requiredValue: 30, unit: '単位', mandatory: true, evidence: '直近5年間に研修実績点数表で30点以上。' },
        { label: '指定学会・セミナーによる研修実績', requiredValue: 15, unit: '単位', mandatory: true, evidence: '研修実績30点のうち指定学会・セミナー参加で15点以上。' },
        { label: '日本外科学会定期学術集会', requiredValue: 1, unit: '回', mandatory: true, evidence: '外科専門医を基盤とする場合は1回以上参加する。' },
        { label: '外科領域を含む診療経験', requiredValue: 100, unit: '症例', mandatory: true, evidence: '外科専門医を基盤とする場合、NCD登録された診療経験を合計100例以上。' },
      ],
      mandatoryNotes: ['内分泌外科の診療実績は、規定された4つの症例構成のいずれかを満たす必要があります。'],
      otherConditions: ['症例構成は、甲状腺・副甲状腺50例以上／副甲状腺・副腎30例以上／副甲状腺25例以上／副腎10例以上のいずれかです。', '専門医更新は2年間猶予できる規定があります。'],
      extractionMethod: 'official-profile-jaes-v1',
    },
  ],
]);

const confidenceAssessmentForProfile = (
  profile: Pick<OfficialProfile, 'renewalCycleYears' | 'requiredTotalCredits' | 'requirements' | 'warnings'>,
  score: number,
  evidenceCount: number,
): ConfidenceAssessment => ({
  version: 1,
  score,
  summary: '公式一次資料に対応する検証済みプロファイルです。公開前に適用対象と原文を最終確認してください。',
  factors: [
    {
      label: '資料の発行元',
      status: 'confirmed',
      detail: '認定団体・学会の公式サイトで公開された一次資料です',
    },
    {
      label: '構造化方法',
      status: 'confirmed',
      detail: '公式資料ごとに検証した固定プロファイルを適用しています',
    },
    {
      label: '更新周期',
      status: 'confirmed',
      detail: `${profile.renewalCycleYears}年として公式記載と照合済みです`,
    },
    {
      label: '単位・必須条件',
      status: 'confirmed',
      detail: profile.requiredTotalCredits === undefined
        ? `単一の総単位を定めない制度として、${profile.requirements.length}件の条件を照合済みです`
        : `総単位${profile.requiredTotalCredits}単位と${profile.requirements.length}件の条件を照合済みです`,
    },
    {
      label: '原文根拠',
      status: evidenceCount > 0 ? 'confirmed' : 'partial',
      detail: evidenceCount > 0
        ? `保存済み本文から関連箇所を${evidenceCount}件参照できます`
        : '固定プロファイルの根拠はありますが、抽出本文を取得できていません',
    },
    ...(profile.warnings?.length
      ? [{
          label: '適用上の注意',
          status: 'attention' as const,
          detail: profile.warnings.join(' '),
        }]
      : []),
  ],
});

export const applyOfficialSourceProfile = (
  sourceUrl: string,
  fallback: { rule: StructuredRenewalRule; confidence: number },
): ProfileResult => {
  if (sourceUrl !== recognizedClinicalPhysicianUrl) {
    const profile = profiles.get(sourceUrl);
    if (!profile) return { ...fallback, extractionMethod: 'deterministic-v2' };
    const confidence = profile.confidence ?? 0.99;
    return {
      extractionMethod: profile.extractionMethod,
      confidence,
      rule: {
        schemaVersion: 1,
        title: profile.title,
        renewalCycleYears: profile.renewalCycleYears,
        requiredTotalCredits: profile.requiredTotalCredits,
        requirements: profile.requirements,
        mandatoryNotes: profile.mandatoryNotes,
        otherConditions: profile.otherConditions,
        evidence: fallback.rule.evidence,
        warnings: profile.warnings ?? [],
        confidenceAssessment: confidenceAssessmentForProfile(
          profile,
          confidence,
          fallback.rule.evidence.length,
        ),
      },
    };
  }

  const confidence = 0.98;
  const profileWarnings = [
    'V-11を主資料、V-12を更新手続・猶予、V-13を単位表の補足資料として構造化しています。公開前に3資料を確認してください。',
  ];
  return {
    extractionMethod: 'official-profile-jarm-v1',
    confidence,
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
      warnings: profileWarnings,
      confidenceAssessment: confidenceAssessmentForProfile(
        {
          renewalCycleYears: 5,
          requiredTotalCredits: 200,
          requirements: [{
            label: '年次・秋季・地方会いずれかの学術集会参加',
            requiredValue: 1,
            unit: '回',
            mandatory: true,
            evidence: 'V-11第2条第2項(3)',
          }],
          warnings: profileWarnings,
        },
        confidence,
        fallback.rule.evidence.length,
      ),
    },
  };
};
