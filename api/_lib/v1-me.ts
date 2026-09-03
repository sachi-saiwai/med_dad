import { HttpError } from './config.js';
import { db } from './db.js';
import { requireFirebaseUser } from './firebase-auth.js';
import {
  methodNotAllowed,
  sendError,
  userCors,
} from './http.js';
import {
  ensureAppUser,
  jsonBody,
  sanitizeSnapshot,
} from './user-data.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

interface SnapshotRow {
  revision: string;
  snapshot: Record<string, unknown>;
  updated_at: string;
}

const serialize = (row: SnapshotRow) => ({
  revision: Number(row.revision),
  snapshot: row.snapshot,
  updatedAt: row.updated_at,
});

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['GET', 'PUT'].includes(request.method || '')) {
    return methodNotAllowed(response, 'GET, PUT, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);

    if (request.method === 'GET') {
      const rows = (await db().query(
        `SELECT revision, snapshot, updated_at
           FROM user_snapshots
          WHERE user_id = $1`,
        [user.id],
      )) as unknown as SnapshotRow[];
      return response.status(200).json({ data: rows[0] ? serialize(rows[0]) : null });
    }

    const body = jsonBody<{
      baseRevision?: unknown;
      snapshot?: unknown;
    }>(request);
    const baseRevision = Number(body.baseRevision);
    if (!Number.isSafeInteger(baseRevision) || baseRevision < 0) {
      throw new HttpError(400, 'invalid_base_revision');
    }
    const snapshot = sanitizeSnapshot(body.snapshot, user.id);

    let rows: SnapshotRow[];
    if (baseRevision === 0) {
      rows = (await db().query(
        `INSERT INTO user_snapshots (user_id, revision, snapshot)
         VALUES ($1, 1, $2::jsonb)
         ON CONFLICT (user_id) DO NOTHING
         RETURNING revision, snapshot, updated_at`,
        [user.id, JSON.stringify(snapshot)],
      )) as unknown as SnapshotRow[];
    } else {
      rows = (await db().query(
        `UPDATE user_snapshots
            SET revision = revision + 1,
                snapshot = $3::jsonb,
                updated_at = now()
          WHERE user_id = $1 AND revision = $2
          RETURNING revision, snapshot, updated_at`,
        [user.id, baseRevision, JSON.stringify(snapshot)],
      )) as unknown as SnapshotRow[];
    }

    if (!rows[0]) {
      const current = (await db().query(
        `SELECT revision, updated_at FROM user_snapshots WHERE user_id = $1`,
        [user.id],
      )) as unknown as Array<{ revision: string; updated_at: string }>;
      return response.status(409).json({
        error: 'revision_conflict',
        currentRevision: current[0] ? Number(current[0].revision) : 0,
        updatedAt: current[0]?.updated_at || null,
      });
    }

    return response.status(200).json({ data: serialize(rows[0]) });
  } catch (error) {
    return sendError(response, error);
  }
}
