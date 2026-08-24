import { createHash } from 'node:crypto';
import { put } from '@vercel/blob';

import { blobToken } from './config.js';
import { db } from './db.js';
import {
  extractDocument,
  linksForDiscovery,
  structureRenewalRule,
  type ExtractedDocument,
} from './extract.js';

interface SourceDocumentRow {
  id: string;
  qualification_id: string | null;
  organization_id: string | null;
  title: string;
  source_url: string;
  system_type: string;
  acquired_year_from: number | null;
  acquired_year_to: number | null;
  renewal_year_from: number | null;
  renewal_year_to: number | null;
  media_type: 'auto' | 'html' | 'pdf';
  is_index: boolean;
  discovery_keywords: string[];
}

interface SyncOptions {
  triggerType: 'cron' | 'github_actions' | 'manual';
  limit?: number;
  sourceId?: number;
  qualificationId?: string;
  force?: boolean;
}

export interface SyncSummary {
  runId: number;
  status: 'succeeded' | 'partial' | 'failed';
  sourcesChecked: number;
  sourcesChanged: number;
  rulesProposed: number;
  errors: Array<{ sourceId: string; message: string }>;
}

const maxSourceBytes = 20 * 1024 * 1024;

const contentExtension = (contentType: string, url: string): string => {
  if (contentType.includes('pdf') || new URL(url).pathname.endsWith('.pdf')) return 'pdf';
  return 'html';
};

const fetchSource = async (
  source: SourceDocumentRow,
): Promise<{
  bytes: Buffer;
  contentType: string;
  status: number;
  etag?: string;
  lastModified?: string;
  finalUrl: string;
}> => {
  const url = new URL(source.source_url);
  if (url.protocol !== 'https:' && url.protocol !== 'http:') {
    throw new Error('Only HTTP(S) sources are allowed');
  }

  const response = await fetch(url, {
    redirect: 'follow',
    signal: AbortSignal.timeout(25_000),
    headers: {
      Accept: 'text/html,application/xhtml+xml,application/pdf;q=0.9,*/*;q=0.5',
      'User-Agent': 'MedLicenseSourceMonitor/1.0 (+https://github.com/sachi-saiwai/med_dad)',
    },
  });
  if (!response.ok) throw new Error(`Source returned HTTP ${response.status}`);

  const contentLength = Number.parseInt(response.headers.get('content-length') || '0', 10);
  if (contentLength > maxSourceBytes) throw new Error('Source exceeds the 20 MB limit');

  const bytes = Buffer.from(await response.arrayBuffer());
  if (bytes.byteLength > maxSourceBytes) throw new Error('Source exceeds the 20 MB limit');

  return {
    bytes,
    contentType: response.headers.get('content-type') || 'application/octet-stream',
    status: response.status,
    etag: response.headers.get('etag') || undefined,
    lastModified: response.headers.get('last-modified') || undefined,
    finalUrl: response.url || source.source_url,
  };
};

const recordFailure = async (sourceId: string, error: unknown): Promise<string> => {
  const message = error instanceof Error ? error.message : String(error);
  await db().query(
    `UPDATE source_documents
       SET last_checked_at = now(), last_error = $2, updated_at = now()
     WHERE id = $1`,
    [sourceId, message.slice(0, 2000)],
  );
  return message;
};

const discoverDocuments = async (
  source: SourceDocumentRow,
  document: ExtractedDocument,
): Promise<number> => {
  if (!source.is_index) return 0;
  const links = linksForDiscovery(
    document.links,
    source.source_url,
    source.discovery_keywords,
  );
  for (const link of links) {
    await db().query(
      `INSERT INTO source_documents (
         qualification_id, organization_id, title, source_url, system_type,
         acquired_year_from, acquired_year_to, renewal_year_from, renewal_year_to,
         media_type, is_index,
         discovery_keywords, fetch_interval_hours
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'auto', false, '{}', 168)
       ON CONFLICT (source_url) DO UPDATE SET
         title = EXCLUDED.title,
         qualification_id = COALESCE(source_documents.qualification_id, EXCLUDED.qualification_id),
         organization_id = COALESCE(source_documents.organization_id, EXCLUDED.organization_id),
         updated_at = now()`,
      [
        source.qualification_id,
        source.organization_id,
        link.title.slice(0, 500),
        link.url,
        source.system_type,
        source.acquired_year_from,
        source.acquired_year_to,
        source.renewal_year_from,
        source.renewal_year_to,
      ],
    );
  }
  return links.length;
};

const syncOne = async (
  source: SourceDocumentRow,
): Promise<{ changed: boolean; ruleProposed: boolean }> => {
  const fetched = await fetchSource(source);
  const sha256 = createHash('sha256').update(fetched.bytes).digest('hex');
  const existing = await db().query(
    `SELECT id FROM source_snapshots WHERE source_document_id = $1 AND sha256 = $2 LIMIT 1`,
    [source.id, sha256],
  );

  if (existing.length > 0) {
    await db().query(
      `UPDATE source_documents
         SET last_checked_at = now(), last_http_status = $2, last_error = NULL, updated_at = now()
       WHERE id = $1`,
      [source.id, fetched.status],
    );
    return { changed: false, ruleProposed: false };
  }

  const extracted = await extractDocument(fetched.bytes, fetched.contentType, fetched.finalUrl);
  extracted.title ??= source.title;
  const extension = contentExtension(fetched.contentType, fetched.finalUrl);
  const blobPath = `official-sources/${source.id}/${sha256}.${extension}`;
  const stored = await put(blobPath, fetched.bytes, {
    access: 'private',
    addRandomSuffix: false,
    allowOverwrite: false,
    contentType: fetched.contentType,
    token: blobToken(),
  });

  const snapshotRows = await db().query(
    `INSERT INTO source_snapshots (
       source_document_id, http_status, content_type, sha256, byte_length,
       blob_path, blob_url, etag, last_modified, extracted_text, extraction_metadata
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::jsonb)
     RETURNING id`,
    [
      source.id,
      fetched.status,
      fetched.contentType,
      sha256,
      fetched.bytes.byteLength,
      blobPath,
      stored.url,
      fetched.etag || null,
      fetched.lastModified || null,
      extracted.text.slice(0, 1_500_000),
      JSON.stringify({
        title: extracted.title,
        pageCount: extracted.pageCount,
        finalUrl: fetched.finalUrl,
        discoveredLinkCount: extracted.links.length,
      }),
    ],
  );
  const snapshotId = String(snapshotRows[0]?.id);

  await db().query(
    `UPDATE source_documents
       SET last_checked_at = now(), last_changed_at = now(), last_http_status = $2,
           last_error = NULL, updated_at = now()
     WHERE id = $1`,
    [source.id, fetched.status],
  );

  await discoverDocuments(source, extracted);

  if (!source.qualification_id) return { changed: true, ruleProposed: false };

  const structured = structureRenewalRule(extracted);
  await db().query(
    `INSERT INTO renewal_rule_versions (
       qualification_id, source_snapshot_id, system_type, acquired_year_from,
       acquired_year_to, renewal_year_from, renewal_year_to,
       renewal_cycle_years, required_total_credits,
       structured_data, extraction_method, confidence, status
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, 'deterministic-v2', $11, 'pending_review')
     ON CONFLICT (qualification_id, source_snapshot_id, system_type) DO NOTHING`,
    [
      source.qualification_id,
      snapshotId,
      source.system_type,
      source.acquired_year_from,
      source.acquired_year_to,
      source.renewal_year_from,
      source.renewal_year_to,
      structured.rule.renewalCycleYears || null,
      structured.rule.requiredTotalCredits || null,
      JSON.stringify(structured.rule),
      structured.confidence,
    ],
  );
  return { changed: true, ruleProposed: true };
};

export const runSourceSync = async (options: SyncOptions): Promise<SyncSummary> => {
  const limit = Math.max(1, Math.min(options.limit ?? 5, 20));
  const runRows = await db().query(
    `INSERT INTO ingestion_runs (trigger_type, status) VALUES ($1, 'running') RETURNING id`,
    [options.triggerType],
  );
  const runId = Number(runRows[0]?.id);
  const params: unknown[] = [];
  let where = 'active = true';
  if (options.sourceId !== undefined) {
    params.push(options.sourceId);
    where += ` AND id = $${params.length}`;
  } else if (!options.force) {
    where += ` AND (
      last_error IS NOT NULL
      OR last_checked_at IS NULL
      OR last_checked_at <= now() - make_interval(hours => fetch_interval_hours)
    )`;
  }
  if (options.qualificationId) {
    params.push(options.qualificationId);
    where += ` AND qualification_id = $${params.length}`;
  }
  params.push(limit);
  const sources = (await db().query(
    `SELECT id, qualification_id, organization_id, title, source_url, system_type,
            acquired_year_from, acquired_year_to, renewal_year_from, renewal_year_to,
            media_type, is_index, discovery_keywords
       FROM source_documents
      WHERE ${where}
      ORDER BY last_checked_at ASC NULLS FIRST, id ASC
      LIMIT $${params.length}`,
    params,
  )) as unknown as SourceDocumentRow[];

  let sourcesChanged = 0;
  let rulesProposed = 0;
  const errors: SyncSummary['errors'] = [];
  for (const source of sources) {
    try {
      const result = await syncOne(source);
      if (result.changed) sourcesChanged += 1;
      if (result.ruleProposed) rulesProposed += 1;
    } catch (error) {
      const message = await recordFailure(source.id, error);
      errors.push({ sourceId: source.id, message });
    }
  }

  const status: SyncSummary['status'] =
    errors.length === 0 ? 'succeeded' : errors.length < sources.length ? 'partial' : 'failed';
  await db().query(
    `UPDATE ingestion_runs
        SET status = $2, sources_checked = $3, sources_changed = $4,
            rules_proposed = $5, errors = $6::jsonb, finished_at = now()
      WHERE id = $1`,
    [runId, status, sources.length, sourcesChanged, rulesProposed, JSON.stringify(errors)],
  );

  return {
    runId,
    status,
    sourcesChecked: sources.length,
    sourcesChanged,
    rulesProposed,
    errors,
  };
};
