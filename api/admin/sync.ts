import { assertAdminAuthorization } from '../_lib/config.js';
import { db } from '../_lib/db.js';
import { bearerHeader, methodNotAllowed, sendError } from '../_lib/http.js';
import { runSourceSync } from '../_lib/sync.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface SyncBody {
  qualificationId?: string;
  limit?: number;
  force?: boolean;
}

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  response.setHeader('Cache-Control', 'no-store');
  response.setHeader('Vary', 'Authorization');
  if (request.method !== 'POST') return methodNotAllowed(response, 'POST');

  try {
    assertAdminAuthorization(bearerHeader(request));
    const body = (request.body || {}) as SyncBody;
    const qualificationId = typeof body.qualificationId === 'string'
      ? body.qualificationId.trim().slice(0, 100)
      : '';
    if (!qualificationId) {
      return response.status(400).json({ error: 'qualificationId is required' });
    }
    const qualification = await db().query(
      `SELECT id FROM qualifications WHERE id = $1 AND active = true LIMIT 1`,
      [qualificationId],
    );
    if (qualification.length === 0) {
      return response.status(404).json({ error: 'qualification_not_found' });
    }
    const limit = Number.isFinite(body.limit) ? Number(body.limit) : 10;
    const summary = await runSourceSync({
      triggerType: 'manual',
      qualificationId,
      limit,
      force: body.force === true,
    });
    return response.status(summary.status === 'failed' ? 502 : 200).json(summary);
  } catch (error) {
    return sendError(response, error);
  }
}
