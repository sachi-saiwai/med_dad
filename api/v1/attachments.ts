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
import {
  ensureAppUser,
  jsonBody,
  safeFileName,
  sha256,
} from '../_lib/user-data.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

// Base64 expands by roughly 33%; keep the JSON request below Vercel's body limit.
const maxAttachmentBytes = 3 * 1024 * 1024;
const allowedContentTypes = new Map<string, string>([
  ['application/pdf', 'pdf'],
  ['image/jpeg', 'jpg'],
  ['image/png', 'png'],
  ['image/webp', 'webp'],
  ['image/heic', 'heic'],
  ['image/heif', 'heif'],
]);

interface AttachmentRow {
  id: string;
  blob_path: string;
  original_name: string;
  content_type: string;
  byte_length: number;
  sha256: string;
  created_at: string;
}

const serialize = (row: AttachmentRow) => ({
  id: row.id,
  originalName: row.original_name,
  contentType: row.content_type,
  byteLength: row.byte_length,
  sha256: row.sha256,
  createdAt: row.created_at,
});

const hasExpectedSignature = (bytes: Buffer, contentType: string): boolean => {
  if (contentType === 'application/pdf') {
    return bytes.subarray(0, 5).toString('ascii') === '%PDF-';
  }
  if (contentType === 'image/jpeg') {
    return bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  }
  if (contentType === 'image/png') {
    return bytes.subarray(0, 8).equals(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
  }
  if (contentType === 'image/webp') {
    return (
      bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
      bytes.subarray(8, 12).toString('ascii') === 'WEBP'
    );
  }
  if (contentType === 'image/heic' || contentType === 'image/heif') {
    if (bytes.subarray(4, 8).toString('ascii') !== 'ftyp') return false;
    const brand = bytes.subarray(8, 12).toString('ascii');
    return ['heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'mif1', 'msf1'].includes(
      brand,
    );
  }
  return false;
};

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (!['GET', 'POST', 'DELETE'].includes(request.method || '')) {
    return methodNotAllowed(response, 'GET, POST, DELETE, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);
    const id = queryString(request, 'id')?.trim();

    if (request.method === 'GET') {
      if (!id) throw new HttpError(400, 'attachment_id_required');
      const rows = (await db().query(
        `SELECT id, blob_path, original_name, content_type,
                byte_length, sha256, created_at
           FROM user_attachments
          WHERE id = $1 AND user_id = $2`,
        [id, user.id],
      )) as unknown as AttachmentRow[];
      const row = rows[0];
      if (!row) throw new HttpError(404, 'attachment_not_found');
      const result = await get(row.blob_path, {
        access: 'private',
        token: blobToken(),
        useCache: false,
      });
      if (!result || result.statusCode !== 200) {
        throw new HttpError(404, 'attachment_not_found');
      }
      const bytes = Buffer.from(await new Response(result.stream).arrayBuffer());
      response.setHeader('Content-Type', row.content_type);
      response.setHeader('Content-Length', String(bytes.length));
      response.setHeader(
        'Content-Disposition',
        `attachment; filename*=UTF-8''${encodeURIComponent(row.original_name)}`,
      );
      response.setHeader('X-Content-Type-Options', 'nosniff');
      return response.status(200).send(bytes);
    }

    if (request.method === 'DELETE') {
      if (!id) throw new HttpError(400, 'attachment_id_required');
      const rows = (await db().query(
        `DELETE FROM user_attachments
          WHERE id = $1 AND user_id = $2
          RETURNING blob_path`,
        [id, user.id],
      )) as unknown as Array<{ blob_path: string }>;
      if (!rows[0]) throw new HttpError(404, 'attachment_not_found');
      await del(rows[0].blob_path, { token: blobToken() });
      return response.status(200).json({ deleted: true });
    }

    const body = jsonBody<{
      base64?: unknown;
      contentType?: unknown;
      name?: unknown;
    }>(request);
    if (
      typeof body.base64 !== 'string' ||
      typeof body.contentType !== 'string' ||
      typeof body.name !== 'string'
    ) {
      throw new HttpError(400, 'invalid_attachment');
    }
    const contentType = body.contentType.toLowerCase().split(';')[0]!.trim();
    const extension = allowedContentTypes.get(contentType);
    if (!extension) throw new HttpError(415, 'unsupported_attachment_type');
    if (body.base64.length > Math.ceil((maxAttachmentBytes * 4) / 3) + 16) {
      throw new HttpError(413, 'attachment_too_large');
    }
    const bytes = Buffer.from(body.base64, 'base64');
    if (bytes.length === 0 || bytes.length > maxAttachmentBytes) {
      throw new HttpError(413, 'attachment_too_large');
    }
    if (!hasExpectedSignature(bytes, contentType)) {
      throw new HttpError(415, 'attachment_content_mismatch');
    }

    const attachmentId = randomUUID();
    const originalName = safeFileName(body.name);
    const blobPath = `user-data/${user.id}/attachments/${attachmentId}.${extension}`;
    const digest = sha256(bytes);
    await put(blobPath, bytes, {
      access: 'private',
      addRandomSuffix: false,
      contentType,
      cacheControlMaxAge: 60,
      token: blobToken(),
    });
    let rows: AttachmentRow[];
    try {
      rows = (await db().query(
        `INSERT INTO user_attachments (
           id, user_id, blob_path, original_name, content_type, byte_length, sha256
         ) VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, blob_path, original_name, content_type,
                   byte_length, sha256, created_at`,
        [
          attachmentId,
          user.id,
          blobPath,
          originalName,
          contentType,
          bytes.length,
          digest,
        ],
      )) as unknown as AttachmentRow[];
    } catch (error) {
      await del(blobPath, { token: blobToken() }).catch(console.error);
      throw error;
    }
    return response.status(201).json({ data: serialize(rows[0]!) });
  } catch (error) {
    return sendError(response, error);
  }
}
