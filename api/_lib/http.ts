import { UnauthorizedError } from './config.js';
import type { ApiRequest, ApiResponse } from './vercel.js';

export const publicCors = (response: ApiResponse): void => {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  response.setHeader('Cache-Control', 'public, s-maxage=300, stale-while-revalidate=3600');
};

export const queryString = (
  request: ApiRequest,
  name: string,
): string | undefined => {
  const value = request.query[name];
  return Array.isArray(value) ? value[0] : value;
};

export const bearerHeader = (request: ApiRequest): string | undefined => {
  const value = request.headers.authorization;
  return Array.isArray(value) ? value[0] : value;
};

export const sendError = (
  response: ApiResponse,
  error: unknown,
): ApiResponse => {
  if (error instanceof UnauthorizedError) {
    return response.status(401).json({ error: 'unauthorized' });
  }

  const message = error instanceof Error ? error.message : 'Unexpected error';
  console.error(error);
  return response.status(500).json({ error: 'server_error', message });
};

export const methodNotAllowed = (
  response: ApiResponse,
  allowed: string,
): ApiResponse => {
  response.setHeader('Allow', allowed);
  return response.status(405).json({ error: 'method_not_allowed' });
};
