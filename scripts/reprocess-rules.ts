import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { db } = await import('../api/_lib/db.js');
const { structureRenewalRule } = await import('../api/_lib/extract.js');
const { applyOfficialSourceProfile } = await import('../api/_lib/official-profiles.js');

interface PendingRow {
  id: string;
  title: string;
  source_url: string;
  extracted_text: string;
}

const rows = (await db().query(
  `SELECT rv.id, sd.title, sd.source_url, ss.extracted_text
     FROM renewal_rule_versions rv
     JOIN source_snapshots ss ON ss.id = rv.source_snapshot_id
     JOIN source_documents sd ON sd.id = ss.source_document_id
    WHERE rv.status = 'pending_review' AND ss.extracted_text IS NOT NULL
    ORDER BY rv.id`,
)) as unknown as PendingRow[];

for (const row of rows) {
  const result = applyOfficialSourceProfile(
    row.source_url,
    structureRenewalRule({
      title: row.title,
      text: row.extracted_text,
      links: [],
    }),
  );
  await db().query(
    `UPDATE renewal_rule_versions
        SET renewal_cycle_years = $2,
            required_total_credits = $3,
            structured_data = $4::jsonb,
            extraction_method = $5,
            confidence = $6
      WHERE id = $1 AND status = 'pending_review'`,
    [
      row.id,
      result.rule.renewalCycleYears || null,
      result.rule.requiredTotalCredits || null,
      JSON.stringify(result.rule),
      result.extractionMethod,
      result.confidence,
    ],
  );
}

console.log(`Reprocessed ${rows.length} pending rules with source-appropriate profiles`);
