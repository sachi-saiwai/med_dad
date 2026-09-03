import { createVerify } from 'node:crypto';

import { firebaseProjectId, HttpError } from './config.js';
import { bearerHeader } from './http.js';
import type { ApiRequest } from './vercel.js';

interface FirebaseTokenHeader {
  alg?: string;
  kid?: string;
}

export interface FirebaseTokenClaims {
  aud?: string;
  auth_time?: number;
  email?: string;
  email_verified?: boolean;
  exp?: number;
  iat?: number;
  iss?: string;
  name?: string;
  sub?: string;
  user_id?: string;
}

export interface AuthenticatedUser {
  id: string;
  email: string;
  displayName: string | null;
}

interface CertificateCache {
  certificates: Record<string, string>;
  expiresAt: number;
}

let certificateCache: CertificateCache | undefined;

const decodePart = <T>(value: string): T => {
  try {
    return JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as T;
  } catch {
    throw new HttpError(401, 'invalid_auth_token');
  }
};

const maxAgeMilliseconds = (cacheControl: string | null): number => {
  const match = cacheControl?.match(/(?:^|,)\s*max-age=(\d+)/i);
  return match ? Number(match[1]) * 1000 : 60 * 60 * 1000;
};

const fetchCertificates = async (): Promise<Record<string, string>> => {
  if (certificateCache && certificateCache.expiresAt > Date.now() + 30_000) {
    return certificateCache.certificates;
  }

  const response = await fetch(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
    { headers: { accept: 'application/json' } },
  );
  if (!response.ok) {
    throw new HttpError(503, 'auth_verification_unavailable');
  }
  const certificates = (await response.json()) as Record<string, string>;
  certificateCache = {
    certificates,
    expiresAt:
      Date.now() + maxAgeMilliseconds(response.headers.get('cache-control')),
  };
  return certificates;
};

export const validateFirebaseClaims = (
  claims: FirebaseTokenClaims,
  projectId: string,
  nowSeconds = Math.floor(Date.now() / 1000),
): AuthenticatedUser => {
  const subject = claims.sub || claims.user_id;
  const email = claims.email?.trim().toLowerCase();
  if (
    !subject ||
    subject.length > 128 ||
    !email ||
    claims.email_verified !== true ||
    claims.aud !== projectId ||
    claims.iss !== `https://securetoken.google.com/${projectId}` ||
    typeof claims.exp !== 'number' ||
    claims.exp <= nowSeconds ||
    typeof claims.iat !== 'number' ||
    claims.iat > nowSeconds + 300
  ) {
    throw new HttpError(401, 'invalid_auth_token');
  }

  return {
    id: subject,
    email,
    displayName: claims.name?.trim().slice(0, 200) || null,
  };
};

export const verifyFirebaseIdToken = async (
  token: string,
): Promise<AuthenticatedUser> => {
  const parts = token.split('.');
  if (parts.length !== 3) throw new HttpError(401, 'invalid_auth_token');

  const header = decodePart<FirebaseTokenHeader>(parts[0]!);
  const claims = decodePart<FirebaseTokenClaims>(parts[1]!);
  if (header.alg !== 'RS256' || !header.kid) {
    throw new HttpError(401, 'invalid_auth_token');
  }

  const certificate = (await fetchCertificates())[header.kid];
  if (typeof certificate !== 'string' || !certificate.includes('BEGIN CERTIFICATE')) {
    throw new HttpError(401, 'invalid_auth_token');
  }

  const verifier = createVerify('RSA-SHA256');
  verifier.update(`${parts[0]}.${parts[1]}`);
  verifier.end();
  if (!verifier.verify(certificate, Buffer.from(parts[2]!, 'base64url'))) {
    throw new HttpError(401, 'invalid_auth_token');
  }

  return validateFirebaseClaims(claims, firebaseProjectId());
};

export const requireFirebaseUser = async (
  request: ApiRequest,
): Promise<AuthenticatedUser> => {
  const authorization = bearerHeader(request);
  if (!authorization?.startsWith('Bearer ')) {
    throw new HttpError(401, 'missing_auth_token');
  }
  return verifyFirebaseIdToken(authorization.slice('Bearer '.length));
};
