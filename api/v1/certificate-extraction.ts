import { HttpError } from '../_lib/config.js';
import { extractCertificateWithAi } from '../_lib/certificate-extraction.js';
import { extractPdf } from '../_lib/extract.js';
import { requireFirebaseUser } from '../_lib/firebase-auth.js';
import { methodNotAllowed, sendError, userCors } from '../_lib/http.js';
import { ensureAppUser, jsonBody } from '../_lib/user-data.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

const maxInlineBytes = 3 * 1024 * 1024;
const allowedInlineTypes = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  userCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (request.method !== 'POST') {
    return methodNotAllowed(response, 'POST, OPTIONS');
  }

  try {
    const user = await requireFirebaseUser(request);
    await ensureAppUser(user);
    const body = jsonBody<{
      ocrText?: unknown;
      qualificationNames?: unknown;
      fileBase64?: unknown;
      contentType?: unknown;
    }>(request);
    let ocrText = typeof body.ocrText === 'string' ? body.ocrText.trim() : '';
    if (ocrText.length > 30_000) ocrText = ocrText.slice(0, 30_000);
    const qualificationNames = Array.isArray(body.qualificationNames)
      ? body.qualificationNames
          .filter((item): item is string => typeof item === 'string')
          .map((item) => item.trim().slice(0, 200))
          .filter(Boolean)
          .slice(0, 30)
      : [];

    let inlineData: { mimeType: string; data: string } | undefined;
    if (typeof body.fileBase64 === 'string' && body.fileBase64.length > 0) {
      const contentType = typeof body.contentType === 'string'
        ? body.contentType.toLowerCase().split(';')[0]!.trim()
        : '';
      if (!allowedInlineTypes.has(contentType)) {
        throw new HttpError(415, 'unsupported_attachment_type');
      }
      if (body.fileBase64.length > Math.ceil((maxInlineBytes * 4) / 3) + 16) {
        throw new HttpError(413, 'attachment_too_large');
      }
      const bytes = Buffer.from(body.fileBase64, 'base64');
      if (bytes.length === 0 || bytes.length > maxInlineBytes) {
        throw new HttpError(413, 'attachment_too_large');
      }
      inlineData = {
        mimeType: contentType,
        data: body.fileBase64,
      };
      if (!ocrText && contentType === 'application/pdf') {
        ocrText = (await extractPdf(bytes)).text.slice(0, 30_000);
        if (ocrText.trim()) inlineData = undefined;
      }
    }
    if (!ocrText && !inlineData) {
      throw new HttpError(400, 'certificate_content_required');
    }

    const data = await extractCertificateWithAi({
      ocrText,
      qualificationNames,
      inlineData,
    });
    return response.status(200).json({ data });
  } catch (error) {
    return sendError(response, error);
  }
}
