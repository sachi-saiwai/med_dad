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

export const optionalEnv = (name: string): string | undefined => {
  const value = process.env[name]?.trim();
  return value || undefined;
};

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
