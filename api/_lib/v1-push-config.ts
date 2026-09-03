import { optionalEnv } from './config.js';
import { methodNotAllowed, publicCors } from './http.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

export default async function pushConfigHandler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  publicCors(response);
  if (request.method === 'OPTIONS') return response.status(204).end();
  if (request.method !== 'GET') return methodNotAllowed(response, 'GET, OPTIONS');
  const publicKey = optionalEnv('WEB_PUSH_PUBLIC_KEY');
  if (!publicKey) {
    return response.status(503).json({ error: 'web_push_not_configured' });
  }
  return response.status(200).json({ publicKey });
}
