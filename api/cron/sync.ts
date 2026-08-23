import { assertCronAuthorization } from '../_lib/config.js';
import { bearerHeader, methodNotAllowed, queryString, sendError } from '../_lib/http.js';
import { runSourceSync } from '../_lib/sync.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  if (request.method !== 'GET' && request.method !== 'POST') {
    return methodNotAllowed(response, 'GET, POST');
  }
  try {
    assertCronAuthorization(bearerHeader(request));
    const parsedLimit = Number.parseInt(queryString(request, 'limit') || '5', 10);
    const summary = await runSourceSync({
      triggerType: request.headers['x-github-event'] ? 'github_actions' : 'cron',
      limit: Number.isFinite(parsedLimit) ? parsedLimit : 5,
    });
    return response.status(summary.status === 'failed' ? 502 : 200).json(summary);
  } catch (error) {
    return sendError(response, error);
  }
}
