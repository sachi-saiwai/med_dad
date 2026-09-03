import { del } from '@vercel/blob';

import { blobToken } from './config.js';
import { db } from './db.js';
import { requireFirebaseUser } from './firebase-auth.js';
import {
  methodNotAllowed,
  sendError,
  userCors,
} from './http.js';
import { ensureAppUser } from './user-data.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (request.method !== 'DELETE') {
    return methodNotAllowed(response, 'DELETE, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);
    const paths = (await db().query(
      `SELECT blob_path FROM user_attachments WHERE user_id = $1
       UNION ALL
       SELECT blob_path FROM user_backups WHERE user_id = $1`,
      [user.id],
    )) as unknown as Array<{ blob_path: string }>;
    if (paths.length > 0) {
      await del(
        paths.map((row) => row.blob_path),
        { token: blobToken() },
      );
    }
    await db().query(`DELETE FROM app_users WHERE user_id = $1`, [user.id]);
    return response.status(200).json({ deleted: true });
  } catch (error) {
    return sendError(response, error);
  }
}
