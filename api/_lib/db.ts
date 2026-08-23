import { neon, type NeonQueryFunction } from '@neondatabase/serverless';

import { databaseUrl } from './config.js';

let cachedSql: NeonQueryFunction<false, false> | undefined;

export const db = (): NeonQueryFunction<false, false> => {
  cachedSql ??= neon(databaseUrl(), {
    fetchOptions: { cache: 'no-store' },
  });
  return cachedSql;
};
