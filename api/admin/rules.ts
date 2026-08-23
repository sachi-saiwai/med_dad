import { assertAdminAuthorization } from '../_lib/config.js';
import { db } from '../_lib/db.js';
import { bearerHeader, methodNotAllowed, sendError } from '../_lib/http.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface ReviewBody {
  ruleId?: number;
  action?: 'publish' | 'reject';
}

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  if (request.method !== 'GET' && request.method !== 'POST') {
    return methodNotAllowed(response, 'GET, POST');
  }

  try {
    assertAdminAuthorization(bearerHeader(request));
    if (request.method === 'GET') {
      const rows = await db().query(
        `SELECT rv.id, rv.qualification_id, q.name AS qualification_name,
                rv.system_type, rv.acquired_year_from, rv.acquired_year_to,
                rv.renewal_cycle_years, rv.required_total_credits,
                rv.structured_data, rv.confidence, rv.created_at,
                sd.title AS source_title, sd.source_url, ss.checked_at
           FROM renewal_rule_versions rv
           JOIN qualifications q ON q.id = rv.qualification_id
           JOIN source_snapshots ss ON ss.id = rv.source_snapshot_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
          WHERE rv.status = 'pending_review'
          ORDER BY rv.created_at DESC
          LIMIT 100`,
      );
      return response.status(200).json({ data: rows, count: rows.length });
    }

    const body = (request.body || {}) as ReviewBody;
    if (!Number.isInteger(body.ruleId) || !['publish', 'reject'].includes(body.action || '')) {
      return response.status(400).json({ error: 'ruleId and action are required' });
    }
    const ruleId = body.ruleId!;

    if (body.action === 'reject') {
      const rows = await db().query(
        `UPDATE renewal_rule_versions
            SET status = 'rejected', reviewed_at = now()
          WHERE id = $1 AND status = 'pending_review'
          RETURNING id, status`,
        [ruleId],
      );
      if (rows.length === 0) return response.status(409).json({ error: 'rule_not_pending' });
      return response.status(200).json({ data: rows[0] });
    }

    const targetRows = await db().query(
      `SELECT qualification_id, system_type, acquired_year_from, acquired_year_to
         FROM renewal_rule_versions WHERE id = $1 AND status = 'pending_review'`,
      [ruleId],
    );
    const target = targetRows[0];
    if (!target) return response.status(409).json({ error: 'rule_not_pending' });

    await db().transaction((transaction) => [
      transaction.query(
        `UPDATE renewal_rule_versions
            SET status = 'superseded', reviewed_at = now()
          WHERE qualification_id = $1
            AND system_type = $2
            AND acquired_year_from IS NOT DISTINCT FROM $3
            AND acquired_year_to IS NOT DISTINCT FROM $4
            AND status = 'published'`,
        [
          target.qualification_id,
          target.system_type,
          target.acquired_year_from,
          target.acquired_year_to,
        ],
      ),
      transaction.query(
        `UPDATE renewal_rule_versions
            SET status = 'published', reviewed_at = now(), published_at = now()
          WHERE id = $1 AND status = 'pending_review'
          RETURNING id, status, published_at`,
        [ruleId],
      ),
    ]);
    return response.status(200).json({ data: { id: ruleId, status: 'published' } });
  } catch (error) {
    return sendError(response, error);
  }
}
