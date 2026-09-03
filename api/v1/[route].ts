import { methodNotAllowed, queryString } from '../_lib/http.js';
import accessHandler from '../_lib/v1-access.js';
import pushConfigHandler from '../_lib/v1-push-config.js';
import pushSubscriptionsHandler from '../_lib/v1-push-subscriptions.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

type RouteHandler = (
  request: ApiRequest,
  response: ApiResponse,
) => Promise<ApiResponse>;

const handlers: Record<string, RouteHandler> = {
  access: accessHandler,
  'push-config': pushConfigHandler,
  'push-subscriptions': pushSubscriptionsHandler,
};

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  const route = queryString(request, 'route') || '';
  const routeHandler = handlers[route];
  if (!routeHandler) {
    return methodNotAllowed(response, 'GET, POST, DELETE, OPTIONS');
  }
  return routeHandler(request, response);
}
