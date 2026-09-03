import { randomBytes } from 'node:crypto';

import { assertAdminAuthorization, HttpError } from '../_lib/config.js';
import { db } from '../_lib/db.js';
import {
  bearerHeader,
  methodNotAllowed,
  queryString,
  sendError,
} from '../_lib/http.js';
import {
  inviteCodeHash,
  jsonBody,
  normalizeInviteCode,
} from '../_lib/user-data.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

const generateInviteCode = (): string => {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = randomBytes(15);
  const raw = Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join(
    '',
  );
  return `${raw.slice(0, 5)}-${raw.slice(5, 10)}-${raw.slice(10, 15)}`;
};

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  if (!['GET', 'POST', 'DELETE'].includes(request.method || '')) {
    return methodNotAllowed(response, 'GET, POST, DELETE');
  }

  try {
    assertAdminAuthorization(bearerHeader(request));

    if (request.method === 'GET') {
      const rows = await db().query(
        `SELECT code_hash, email, email_domain, max_uses, use_count,
                expires_at, revoked_at, created_by, created_at
           FROM app_invites
          ORDER BY created_at DESC
          LIMIT 200`,
      );
      return response.status(200).json({ data: rows });
    }

    if (request.method === 'DELETE') {
      const hash = queryString(request, 'hash')?.trim().toLowerCase();
      if (!hash || !/^[a-f0-9]{64}$/.test(hash)) {
        throw new HttpError(400, 'invalid_invite_hash');
      }
      await db().query(
        `UPDATE app_invites SET revoked_at = now() WHERE code_hash = $1`,
        [hash],
      );
      return response.status(200).json({ revoked: true });
    }

    const body = jsonBody<{
      email?: unknown;
      emailDomain?: unknown;
      expiresInDays?: unknown;
      maxUses?: unknown;
      createdBy?: unknown;
    }>(request);
    const email =
      typeof body.email === 'string'
        ? body.email.trim().toLowerCase().slice(0, 320) || null
        : null;
    const emailDomain =
      typeof body.emailDomain === 'string'
        ? body.emailDomain
            .trim()
            .toLowerCase()
            .replace(/^@/, '')
            .slice(0, 255) || null
        : null;
    if (email && !email.includes('@')) {
      throw new HttpError(400, 'invalid_email');
    }
    if (emailDomain && (!emailDomain.includes('.') || emailDomain.includes('@'))) {
      throw new HttpError(400, 'invalid_email_domain');
    }

    const maxUses = Math.max(
      1,
      Math.min(Number.isInteger(body.maxUses) ? Number(body.maxUses) : 1, 10_000),
    );
    const expiresInDays = Math.max(
      1,
      Math.min(
        Number.isInteger(body.expiresInDays)
          ? Number(body.expiresInDays)
          : 30,
        365,
      ),
    );
    const code = generateInviteCode();
    const hash = inviteCodeHash(code);
    const createdBy =
      typeof body.createdBy === 'string'
        ? body.createdBy.trim().slice(0, 200) || 'admin'
        : 'admin';

    await db().query(
      `INSERT INTO app_invites (
         code_hash, email, email_domain, max_uses, expires_at, created_by
       ) VALUES ($1, $2, $3, $4, now() + ($5::text || ' days')::interval, $6)`,
      [hash, email, emailDomain, maxUses, expiresInDays, createdBy],
    );

    return response.status(201).json({
      code,
      normalizedCode: normalizeInviteCode(code),
      hash,
      email,
      emailDomain,
      maxUses,
      expiresInDays,
    });
  } catch (error) {
    return sendError(response, error);
  }
}
