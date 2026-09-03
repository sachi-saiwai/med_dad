import { HttpError, inviteCodeRequired } from './config.js';
import { db } from './db.js';
import { requireFirebaseUser } from './firebase-auth.js';
import { methodNotAllowed, sendError, userCors } from './http.js';
import { ensureAppUser, inviteCodeHash, jsonBody } from './user-data.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

export default async function accessHandler(
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

    if (!inviteCodeRequired()) {
      await ensureAppUser(user);
      return response.status(200).json({
        allowed: true,
        user: { id: user.id, email: user.email },
        invitationRequired: false,
      });
    }

    const existing = (await db().query(
      `UPDATE app_users
          SET email = $2, display_name = $3, last_seen_at = now(), updated_at = now()
        WHERE user_id = $1
        RETURNING user_id, invited_at`,
      [user.id, user.email, user.displayName],
    )) as unknown as Array<{ user_id: string; invited_at: string }>;
    if (existing[0]) {
      return response.status(200).json({
        allowed: true,
        user: { id: user.id, email: user.email },
        invitedAt: existing[0].invited_at,
      });
    }

    if (request.method === 'GET') {
      throw new HttpError(403, 'invitation_required');
    }

    const body = jsonBody<{ inviteCode?: unknown }>(request);
    if (typeof body.inviteCode !== 'string') {
      throw new HttpError(400, 'invite_code_required');
    }
    const hash = inviteCodeHash(body.inviteCode);
    const domain = user.email.split('@')[1] || '';
    const rows = (await db().query(
      `WITH consumed AS (
         UPDATE app_invites
            SET use_count = use_count + 1
          WHERE code_hash = $1
            AND revoked_at IS NULL
            AND (expires_at IS NULL OR expires_at > now())
            AND use_count < max_uses
            AND (email IS NULL OR email = $3)
            AND (email_domain IS NULL OR email_domain = $4)
          RETURNING code_hash
       )
       INSERT INTO app_users (
         user_id, email, display_name, invitation_hash
       )
       SELECT $2, $3, $5, code_hash FROM consumed
       ON CONFLICT (user_id) DO UPDATE SET
         email = EXCLUDED.email,
         display_name = EXCLUDED.display_name,
         last_seen_at = now(),
         updated_at = now()
       RETURNING user_id, invited_at`,
      [hash, user.id, user.email, domain, user.displayName],
    )) as unknown as Array<{ user_id: string; invited_at: string }>;

    if (!rows[0]) throw new HttpError(403, 'invalid_or_expired_invite');
    return response.status(201).json({
      allowed: true,
      user: { id: user.id, email: user.email },
      invitedAt: rows[0].invited_at,
    });
  } catch (error) {
    return sendError(response, error);
  }
}
