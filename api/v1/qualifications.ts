import { db } from '../_lib/db.js';
import {
  methodNotAllowed,
  publicCors,
  queryString,
  sendError,
} from '../_lib/http.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface QualificationRow {
  id: string;
  name: string;
  organization: string;
  organization_official_url: string | null;
  category: string;
  parent_qualification_id: string | null;
  parent_qualification_name: string | null;
  keywords: string[];
  verification_status: string;
  rule_id: string | null;
  system_type: string | null;
  acquired_year_from: number | null;
  acquired_year_to: number | null;
  renewal_year_from: number | null;
  renewal_year_to: number | null;
  renewal_cycle_years: string | null;
  required_total_credits: string | null;
  structured_data: Record<string, unknown> | null;
  confidence: string | null;
  published_at: string | null;
  source_title: string | null;
  source_url: string | null;
  checked_at: string | null;
}

const serialize = (row: QualificationRow) => ({
  id: row.id,
  name: row.name,
  organization: {
    name: row.organization,
    officialUrl: row.organization_official_url,
  },
  category: row.category,
  parentQualification: row.parent_qualification_id
    ? { id: row.parent_qualification_id, name: row.parent_qualification_name }
    : null,
  keywords: row.keywords,
  verificationStatus: row.verification_status,
  renewalRule: row.rule_id
    ? {
        id: Number(row.rule_id),
        systemType: row.system_type,
        acquiredYearFrom: row.acquired_year_from,
        acquiredYearTo: row.acquired_year_to,
        renewalYearFrom: row.renewal_year_from,
        renewalYearTo: row.renewal_year_to,
        renewalCycleYears: row.renewal_cycle_years ? Number(row.renewal_cycle_years) : null,
        requiredTotalCredits: row.required_total_credits
          ? Number(row.required_total_credits)
          : null,
        details: row.structured_data,
        confidence: row.confidence ? Number(row.confidence) : null,
        publishedAt: row.published_at,
        source: {
          title: row.source_title,
          url: row.source_url,
          checkedAt: row.checked_at,
        },
      }
    : null,
});

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  publicCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (request.method !== 'GET') return methodNotAllowed(response, 'GET, OPTIONS');

  try {
    const id = queryString(request, 'id')?.trim() || null;
    const search = queryString(request, 'q')?.trim().slice(0, 100) || null;
    const systemType = queryString(request, 'systemType')?.trim().slice(0, 100) || null;
    const requestedYear = Number.parseInt(queryString(request, 'acquiredYear') || '', 10);
    const acquiredYear = Number.isFinite(requestedYear) ? requestedYear : null;
    const requestedRenewalYear = Number.parseInt(queryString(request, 'renewalYear') || '', 10);
    const renewalYear = Number.isFinite(requestedRenewalYear) ? requestedRenewalYear : null;
    const requestedLimit = Number.parseInt(queryString(request, 'limit') || '50', 10);
    const limit = Math.max(1, Math.min(Number.isFinite(requestedLimit) ? requestedLimit : 50, 100));

    const rows = (await db().query(
      `SELECT
         q.id, q.name, o.name AS organization, o.official_url AS organization_official_url,
         q.category, q.parent_qualification_id, parent.name AS parent_qualification_name,
         q.keywords, q.verification_status,
         rule.id AS rule_id, rule.system_type, rule.acquired_year_from,
         rule.acquired_year_to, rule.renewal_year_from, rule.renewal_year_to,
         rule.renewal_cycle_years, rule.required_total_credits,
         rule.structured_data, rule.confidence, rule.published_at,
         rule.source_title, rule.source_url, rule.checked_at
       FROM qualifications q
       JOIN organizations o ON o.id = q.organization_id
       LEFT JOIN qualifications parent ON parent.id = q.parent_qualification_id
       LEFT JOIN LATERAL (
         SELECT rv.id, rv.system_type, rv.acquired_year_from, rv.acquired_year_to,
                rv.renewal_year_from, rv.renewal_year_to,
                rv.renewal_cycle_years, rv.required_total_credits, rv.structured_data,
                rv.confidence, rv.published_at, sd.title AS source_title,
                sd.source_url, ss.checked_at
           FROM renewal_rule_versions rv
           JOIN source_snapshots ss ON ss.id = rv.source_snapshot_id
           JOIN source_documents sd ON sd.id = ss.source_document_id
          WHERE rv.qualification_id = q.id
            AND rv.status = 'published'
            AND ($3::text IS NULL OR rv.system_type = $3)
            AND (
              $4::integer IS NULL
              OR (
                (rv.acquired_year_from IS NULL OR rv.acquired_year_from <= $4)
                AND (rv.acquired_year_to IS NULL OR rv.acquired_year_to >= $4)
              )
            )
            AND (
              (
                $5::integer IS NULL
                AND rv.renewal_year_from IS NULL
                AND rv.renewal_year_to IS NULL
              )
              OR (
                $5::integer IS NOT NULL
                AND (
                  (
                    (rv.renewal_year_from IS NOT NULL OR rv.renewal_year_to IS NOT NULL)
                    AND (rv.renewal_year_from IS NULL OR rv.renewal_year_from <= $5)
                    AND (rv.renewal_year_to IS NULL OR rv.renewal_year_to >= $5)
                  )
                  OR (
                    rv.renewal_year_from IS NULL
                    AND rv.renewal_year_to IS NULL
                    AND NOT EXISTS (
                      SELECT 1
                        FROM source_documents scoped_source
                       WHERE scoped_source.qualification_id = q.id
                         AND scoped_source.active = true
                         AND (
                           scoped_source.renewal_year_from IS NOT NULL
                           OR scoped_source.renewal_year_to IS NOT NULL
                         )
                         AND (
                           scoped_source.renewal_year_from IS NULL
                           OR scoped_source.renewal_year_from <= $5
                         )
                         AND (
                           scoped_source.renewal_year_to IS NULL
                           OR scoped_source.renewal_year_to >= $5
                         )
                    )
                  )
                )
              )
            )
          ORDER BY
            CASE WHEN $5::integer IS NOT NULL
                       AND (rv.renewal_year_from IS NOT NULL OR rv.renewal_year_to IS NOT NULL)
                 THEN 0 ELSE 1 END,
            CASE WHEN $4::integer IS NOT NULL
                       AND rv.acquired_year_from IS NOT NULL
                       AND rv.acquired_year_to IS NOT NULL THEN 0 ELSE 1 END,
            rv.published_at DESC NULLS LAST,
            rv.id DESC
          LIMIT 1
       ) rule ON true
       WHERE q.active = true
         AND ($1::text IS NULL OR q.id = $1)
         AND (
           $2::text IS NULL
           OR q.name ILIKE '%' || $2 || '%'
           OR o.name ILIKE '%' || $2 || '%'
           OR EXISTS (SELECT 1 FROM unnest(q.keywords) keyword WHERE keyword ILIKE '%' || $2 || '%')
         )
       ORDER BY
         CASE WHEN $2::text IS NOT NULL AND q.name ILIKE $2 || '%' THEN 0 ELSE 1 END,
         CASE WHEN q.category = '基本領域' THEN 0 ELSE 1 END,
         q.name
       LIMIT $6`,
      [id, search, systemType, acquiredYear, renewalYear, id ? 1 : limit],
    )) as unknown as QualificationRow[];

    if (id && rows.length === 0) {
      return response.status(404).json({ error: 'qualification_not_found' });
    }
    return response.status(200).json({
      data: id ? serialize(rows[0]!) : rows.map(serialize),
      meta: {
        count: rows.length,
        query: search,
        acquiredYear,
        renewalYear,
        systemType,
        generatedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    return sendError(response, error);
  }
}
