import { randomUUID } from 'node:crypto';
import { del, get, put } from '@vercel/blob';

import { blobToken, HttpError } from '../_lib/config.js';
import { db } from '../_lib/db.js';
import { requireFirebaseUser } from '../_lib/firebase-auth.js';
import {
  methodNotAllowed,
  queryString,
  sendError,
  userCors,
} from '../_lib/http.js';
import { ensureAppUser, sha256 } from '../_lib/user-data.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface BackupRow {
  id: string;
  revision: string;
  byte_length: number;
  sha256: string;
  created_at: string;
  blob_path?: string;
}

const serialize = (row: BackupRow) => ({
  id: row.id,
  revision: Number(row.revision),
  byteLength: row.byte_length,
  sha256: row.sha256,
  createdAt: row.created_at,
});

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['GET', 'POST'].includes(request.method || '')) {
    return methodNotAllowed(response, 'GET, POST, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);
    const id = queryString(request, 'id')?.trim();

    if (request.method === 'GET' && id) {
      const rows = (await db().query(
        `SELECT id, revision, blob_path, byte_length, sha256, created_at
           FROM user_backups
          WHERE id = $1 AND user_id = $2`,
        [id, user.id],
      )) as unknown as BackupRow[];
      const row = rows[0];
      if (!row?.blob_path) throw new HttpError(404, 'backup_not_found');
      const result = await get(row.blob_path, {
        access: 'private',
        token: blobToken(),
        useCache: false,
      });
      if (!result || result.statusCode !== 200) {
        throw new HttpError(404, 'backup_not_found');
      }
      const bytes = Buffer.from(await new Response(result.stream).arrayBuffer());
      if (sha256(bytes) !== row.sha256) {
        throw new HttpError(500, 'backup_integrity_error');
      }
      return response.status(200).json({
        data: {
          ...serialize(row),
          snapshot: JSON.parse(bytes.toString('utf8')) as unknown,
        },
      });
    }

    if (request.method === 'GET') {
      const rows = (await db().query(
        `SELECT id, revision, byte_length, sha256, created_at
           FROM user_backups
          WHERE user_id = $1
          ORDER BY created_at DESC
          LIMIT 20`,
        [user.id],
      )) as unknown as BackupRow[];
      return response.status(200).json({ data: rows.map(serialize) });
    }

    const snapshots = (await db().query(
      `SELECT revision, snapshot FROM user_snapshots WHERE user_id = $1`,
      [user.id],
    )) as unknown as Array<{
      revision: string;
      snapshot: Record<string, unknown>;
    }>;
    const snapshot = snapshots[0];
    if (!snapshot) throw new HttpError(409, 'snapshot_not_available');
    const bytes = Buffer.from(JSON.stringify(snapshot.snapshot), 'utf8');
    const digest = sha256(bytes);
    const backupId = randomUUID();
    const blobPath = `user-data/${user.id}/backups/${backupId}.json`;
    await put(blobPath, bytes, {
      access: 'private',
      addRandomSuffix: false,
      contentType: 'application/json; charset=utf-8',
      cacheControlMaxAge: 60,
      token: blobToken(),
    });
    let rows: BackupRow[];
    try {
      rows = (await db().query(
        `INSERT INTO user_backups (
           id, user_id, revision, blob_path, sha256, byte_length
         ) VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, revision, byte_length, sha256, created_at`,
        [backupId, user.id, Number(snapshot.revision), blobPath, digest, bytes.length],
      )) as unknown as BackupRow[];
    } catch (error) {
      await del(blobPath, { token: blobToken() }).catch(console.error);
      throw error;
    }
    return response.status(201).json({ data: serialize(rows[0]!) });
  } catch (error) {
    return sendError(response, error);
  }
}
