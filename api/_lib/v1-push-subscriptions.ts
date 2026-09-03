import { HttpError } from './config.js';
import { db } from './db.js';
import { requireFirebaseUser } from './firebase-auth.js';
import { methodNotAllowed, sendError, userCors } from './http.js';
import { ensureAppUser, jsonBody, sha256 } from './user-data.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

interface PushBody extends Record<string, unknown> {
  endpoint?: unknown;
  expirationTime?: unknown;
  keys?: unknown;
}

export default async function pushSubscriptionsHandler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['POST', 'DELETE'].includes(request.method || '')) {
    return methodNotAllowed(response, 'POST, DELETE, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);
    const body = jsonBody<PushBody>(request);
    if (typeof body.endpoint !== 'string' || body.endpoint.length > 4096) {
      throw new HttpError(400, 'invalid_push_subscription');
    }
    const endpointHash = sha256(body.endpoint);

    if (request.method === 'DELETE') {
      await db().query(
        `DELETE FROM web_push_subscriptions
          WHERE user_id = $1 AND endpoint_hash = $2`,
        [user.id, endpointHash],
      );
      return response.status(200).json({ deleted: true });
    }

    if (!body.keys || typeof body.keys !== 'object' || Array.isArray(body.keys)) {
      throw new HttpError(400, 'invalid_push_subscription');
    }
    const keys = body.keys as Record<string, unknown>;
    if (
      typeof keys.p256dh !== 'string' ||
      typeof keys.auth !== 'string' ||
      keys.p256dh.length > 512 ||
      keys.auth.length > 256
    ) {
      throw new HttpError(400, 'invalid_push_subscription');
    }
    const expirationTime =
      typeof body.expirationTime === 'number' &&
      Number.isSafeInteger(body.expirationTime)
        ? body.expirationTime
        : null;
    const rows = await db().query(
      `INSERT INTO web_push_subscriptions (
         user_id, endpoint_hash, endpoint, p256dh, auth, expiration_time
       ) VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (endpoint_hash) DO UPDATE SET
         user_id = EXCLUDED.user_id,
         endpoint = EXCLUDED.endpoint,
         p256dh = EXCLUDED.p256dh,
         auth = EXCLUDED.auth,
         expiration_time = EXCLUDED.expiration_time,
         updated_at = now()
       RETURNING id, created_at, updated_at`,
      [
        user.id,
        endpointHash,
        body.endpoint,
        keys.p256dh,
        keys.auth,
        expirationTime,
      ],
    );
    return response.status(201).json({ data: rows[0] });
  } catch (error) {
    return sendError(response, error);
  }
}
