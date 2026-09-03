import { createHash } from 'node:crypto';

import { db } from './db.js';
import type { AuthenticatedUser } from './firebase-auth.js';
import { HttpError, inviteCodeRequired } from './config.js';
import type { ApiRequest } from './vercel.js';

export const normalizeInviteCode = (value: string): string =>
  value.trim().toUpperCase().replace(/[^A-Z0-9]/g, '');

export const sha256 = (value: string | Uint8Array): string =>
  createHash('sha256').update(value).digest('hex');

export const inviteCodeHash = (value: string): string => {
  const normalized = normalizeInviteCode(value);
  if (normalized.length < 8 || normalized.length > 64) {
    throw new HttpError(400, 'invalid_invite_code');
  }
  return sha256(normalized);
};

export const jsonBody = <T extends Record<string, unknown>>(
  request: ApiRequest,
): T => {
  if (!request.body) return {} as T;
  if (typeof request.body === 'string') {
    try {
      return JSON.parse(request.body) as T;
    } catch {
      throw new HttpError(400, 'invalid_json');
    }
  }
  if (typeof request.body !== 'object' || Array.isArray(request.body)) {
    throw new HttpError(400, 'invalid_json');
  }
  return request.body as T;
};

export const ensureAppUser = async (
  user: AuthenticatedUser,
): Promise<void> => {
  const rows = (await db().query(
    inviteCodeRequired()
      ? `UPDATE app_users
            SET email = $2, display_name = $3, last_seen_at = now(), updated_at = now()
          WHERE user_id = $1
          RETURNING user_id`
      : `INSERT INTO app_users (user_id, email, display_name)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id) DO UPDATE SET
           email = EXCLUDED.email,
           display_name = EXCLUDED.display_name,
           last_seen_at = now(),
           updated_at = now()
         RETURNING user_id`,
    [user.id, user.email, user.displayName],
  )) as unknown as Array<{ user_id: string }>;
  if (rows.length === 0) {
    throw new HttpError(403, 'invitation_required');
  }
};

export const sanitizeSnapshot = (
  value: unknown,
  userId: string,
): Record<string, unknown> => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'invalid_snapshot');
  }
  const snapshot = { ...(value as Record<string, unknown>), accountId: userId };
  const encoded = JSON.stringify(snapshot);
  if (Buffer.byteLength(encoded, 'utf8') > 1024 * 1024) {
    throw new HttpError(413, 'snapshot_too_large');
  }
  return snapshot;
};

export const safeFileName = (value: string): string => {
  const normalized = value
    .normalize('NFKC')
    .replace(/[\\/\u0000-\u001f\u007f]+/g, '_')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 160);
  return normalized || 'attachment';
};
