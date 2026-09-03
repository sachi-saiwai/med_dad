import { methodNotAllowed, queryString } from '../_lib/http.js';
import accountHandler from '../_lib/v1-account.js';
import accessHandler from '../_lib/v1-access.js';
import backupsHandler from '../_lib/v1-backups.js';
import meHandler from '../_lib/v1-me.js';
import pushConfigHandler from '../_lib/v1-push-config.js';
import pushSubscriptionsHandler from '../_lib/v1-push-subscriptions.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

type RouteHandler = (
  request: ApiRequest,
  response: ApiResponse,
) => Promise<ApiResponse>;

const handlers: Record<string, RouteHandler> = {
  account: accountHandler,
  access: accessHandler,
  backups: backupsHandler,
  me: meHandler,
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
