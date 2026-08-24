import { assertAdminAuthorization } from '../_lib/config.js';
import { db } from '../_lib/db.js';
import { bearerHeader, methodNotAllowed, sendError } from '../_lib/http.js';
import { validateRuleCorrections } from '../_lib/review.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface ReviewBody {
  ruleId?: number;
  action?: 'publish' | 'reject';
  note?: string;
  rule?: unknown;
}

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  response.setHeader('Cache-Control', 'no-store');
  response.setHeader('Vary', 'Authorization');
  if (request.method !== 'GET' && request.method !== 'POST') {
    return methodNotAllowed(response, 'GET, POST');
  }

  try {
    assertAdminAuthorization(bearerHeader(request));
    if (request.method === 'GET') {
      const [rows, summaryRows, syncRows] = await Promise.all([
        db().query(
        `SELECT rv.id, rv.qualification_id, q.name AS qualification_name,
                rv.system_type, rv.acquired_year_from, rv.acquired_year_to,
                rv.renewal_year_from, rv.renewal_year_to,
                rv.renewal_cycle_years, rv.required_total_credits,
                rv.structured_data, rv.confidence, rv.extraction_method, rv.created_at,
                sd.title AS source_title, sd.source_url, ss.checked_at,
                ss.content_type, ss.extraction_metadata,
                left(ss.extracted_text, 24000) AS source_excerpt
           FROM renewal_rule_versions rv
           JOIN qualifications q ON q.id = rv.qualification_id
           JOIN source_snapshots ss ON ss.id = rv.source_snapshot_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
          WHERE rv.status = 'pending_review'
          ORDER BY rv.created_at DESC
          LIMIT 100`,
        ),
        db().query(
          `SELECT status, count(*)::integer AS count
             FROM renewal_rule_versions
            GROUP BY status`,
        ),
        db().query(
          `SELECT id, trigger_type, status, sources_checked, sources_changed,
                  rules_proposed, errors, started_at, finished_at
             FROM ingestion_runs
            ORDER BY id DESC
            LIMIT 1`,
        ),
      ]);
      const summary = Object.fromEntries(
        summaryRows.map((row) => [String(row.status), Number(row.count)]),
      );
      return response.status(200).json({
        data: rows,
        count: rows.length,
        summary: {
          pendingReview: summary.pending_review || 0,
          published: summary.published || 0,
          rejected: summary.rejected || 0,
          superseded: summary.superseded || 0,
        },
        latestSync: syncRows[0] || null,
        generatedAt: new Date().toISOString(),
      });
    }

    const body = (request.body || {}) as ReviewBody;
    if (!Number.isInteger(body.ruleId) || !['publish', 'reject'].includes(body.action || '')) {
      return response.status(400).json({ error: 'ruleId and action are required' });
    }
    const ruleId = body.ruleId!;
    const note = typeof body.note === 'string' ? body.note.trim().slice(0, 2000) : null;

    if (body.action === 'reject') {
      const rows = await db().query(
        `UPDATE renewal_rule_versions
            SET status = 'rejected', reviewed_at = now(), review_note = $2,
                reviewed_by = 'admin'
          WHERE id = $1 AND status = 'pending_review'
          RETURNING id, status`,
        [ruleId, note],
      );
      if (rows.length === 0) return response.status(409).json({ error: 'rule_not_pending' });
      return response.status(200).json({ data: rows[0] });
    }

    const corrections = validateRuleCorrections(body.rule);
    const targetRows = await db().query(
      `SELECT qualification_id, structured_data
         FROM renewal_rule_versions WHERE id = $1 AND status = 'pending_review'`,
      [ruleId],
    );
    const target = targetRows[0];
    if (!target) return response.status(409).json({ error: 'rule_not_pending' });
    const originalStructuredData = (target.structured_data || {}) as Record<string, unknown>;
    const structuredData = {
      ...originalStructuredData,
      renewalCycleYears: corrections.renewalCycleYears,
      requiredTotalCredits: corrections.requiredTotalCredits,
      requirements: corrections.requirements,
      mandatoryNotes: corrections.mandatoryNotes,
      otherConditions: corrections.otherConditions,
    };

    await db().transaction((transaction) => [
      transaction.query(
        `UPDATE renewal_rule_versions
            SET status = 'superseded', reviewed_at = now()
          WHERE qualification_id = $1
            AND system_type = $2
            AND acquired_year_from IS NOT DISTINCT FROM $3
            AND acquired_year_to IS NOT DISTINCT FROM $4
            AND renewal_year_from IS NOT DISTINCT FROM $5
            AND renewal_year_to IS NOT DISTINCT FROM $6
            AND status = 'published'`,
        [
          target.qualification_id,
          corrections.systemType,
          corrections.acquiredYearFrom ?? null,
          corrections.acquiredYearTo ?? null,
          corrections.renewalYearFrom ?? null,
          corrections.renewalYearTo ?? null,
        ],
      ),
      transaction.query(
        `UPDATE renewal_rule_versions
            SET system_type = $2, acquired_year_from = $3, acquired_year_to = $4,
                renewal_year_from = $5, renewal_year_to = $6,
                renewal_cycle_years = $7, required_total_credits = $8,
                structured_data = $9::jsonb, status = 'published',
                reviewed_at = now(), published_at = now(), review_note = $10,
                reviewed_by = 'admin'
          WHERE id = $1 AND status = 'pending_review'
          RETURNING id, status, published_at`,
        [
          ruleId,
          corrections.systemType,
          corrections.acquiredYearFrom ?? null,
          corrections.acquiredYearTo ?? null,
          corrections.renewalYearFrom ?? null,
          corrections.renewalYearTo ?? null,
          corrections.renewalCycleYears ?? null,
          corrections.requiredTotalCredits ?? null,
          JSON.stringify(structuredData),
          note,
        ],
      ),
    ]);
    return response.status(200).json({ data: { id: ruleId, status: 'published' } });
  } catch (error) {
    return sendError(response, error);
  }
}
