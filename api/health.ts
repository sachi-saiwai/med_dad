import { db } from './_lib/db.js';
import { methodNotAllowed, sendError } from './_lib/http.js';
import type { ApiRequest, ApiResponse } from './_lib/vercel.js';

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  if (request.method !== 'GET') return methodNotAllowed(response, 'GET');
  try {
    await db()`SELECT 1 AS ok`;
    return response.status(200).json({
      status: 'ok',
      database: 'connected',
      blob: process.env.BLOB_READ_WRITE_TOKEN ? 'configured' : 'missing',
      openai: process.env.OPENAI_API_KEY ? 'configured' : 'missing',
      checkedAt: new Date().toISOString(),
    });
  } catch (error) {
    return sendError(response, error);
  }
}
