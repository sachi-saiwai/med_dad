const requiredOneOf = (names: string[]): string => {
  for (const name of names) {
    const value = process.env[name]?.trim();
    if (value) return value;
  }
  throw new Error(`${names.join(' or ')} is not configured`);
};

export const databaseUrl = (): string =>
  requiredOneOf(['DATABASE_URL', 'database_DATABASE_URL', 'DATABASE_DATABASE_URL']);
export const blobToken = (): string => requiredOneOf(['BLOB_READ_WRITE_TOKEN']);
export const firebaseProjectId = (): string =>
  requiredOneOf(['FIREBASE_PROJECT_ID']);

export const optionalEnv = (name: string): string | undefined => {
  const value = process.env[name]?.trim();
  return value || undefined;
};

// Invitation-only access can be restored without deleting invite records or
// changing the schema. It is intentionally disabled when the flag is absent.
export const inviteCodeRequired = (): boolean =>
  optionalEnv('REQUIRE_INVITE_CODE')?.toLowerCase() === 'true';

export const assertCronAuthorization = (authorization?: string): void => {
  const secret = requiredOneOf(['CRON_SECRET']);
  if (authorization !== `Bearer ${secret}`) {
    throw new UnauthorizedError();
  }
};

export const assertAdminAuthorization = (authorization?: string): void => {
  const secret = requiredOneOf(['SYNC_ADMIN_TOKEN']);
  if (authorization !== `Bearer ${secret}`) {
    throw new UnauthorizedError();
  }
};

export class UnauthorizedError extends Error {
  constructor() {
    super('Unauthorized');
    this.name = 'UnauthorizedError';
  }
}

export class HttpError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message?: string,
  ) {
    super(message || code);
    this.name = 'HttpError';
  }
}
