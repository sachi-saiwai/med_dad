import { resolve } from 'node:path';
import { Client, neonConfig } from '@neondatabase/serverless';
import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { databaseUrl } = await import('../api/_lib/config.js');
const {
  loadMigrations,
  validateMigrationHistory,
} = await import('./lib/migrations.js');

const args = new Set(process.argv.slice(2));
const unknownArgs = [...args].filter((arg) => arg !== '--status');
if (unknownArgs.length > 0) {
  throw new Error(`Unknown migration option: ${unknownArgs.join(', ')}`);
}

const migrations = await loadMigrations(resolve('db/migrations'));
if (migrations.length === 0) throw new Error('No database migrations were found.');

if (typeof WebSocket !== 'function') {
  throw new Error('This migration runner requires the Node.js 24 WebSocket runtime.');
}
neonConfig.webSocketConstructor = WebSocket;
const client = new Client({ connectionString: databaseUrl() });

const migrationTableSql = `CREATE TABLE IF NOT EXISTS schema_migrations (
  version integer PRIMARY KEY CHECK (version > 0),
  filename text NOT NULL UNIQUE,
  checksum text NOT NULL,
  statement_count integer NOT NULL CHECK (statement_count > 0),
  applied_at timestamptz NOT NULL DEFAULT now()
)`;

interface MigrationRow {
  version: number;
  filename: string;
  checksum: string;
}

const readAppliedMigrations = async (): Promise<MigrationRow[]> => {
  const result = await client.query<MigrationRow>(
    `SELECT version, filename, checksum
       FROM schema_migrations
      ORDER BY version`,
  );
  return result.rows;
};

await client.connect();
try {
  if (args.has('--status')) {
    const table = await client.query<{ exists: boolean }>(
      `SELECT to_regclass('public.schema_migrations') IS NOT NULL AS exists`,
    );
    const applied = table.rows[0]?.exists ? await readAppliedMigrations() : [];
    validateMigrationHistory(migrations, applied);
    const appliedVersions = new Set(applied.map((migration) => migration.version));
    for (const migration of migrations) {
      console.log(
        `${appliedVersions.has(migration.version) ? 'applied' : 'pending'} ${migration.filename}`,
      );
    }
  } else {
    await client.query('BEGIN');
    try {
      // A single transaction and advisory lock make concurrent deploys safe and
      // leave existing data unchanged if any pending migration fails.
      await client.query(
        `SELECT pg_advisory_xact_lock(hashtext('medlicense:schema_migrations'))`,
      );
      await client.query(migrationTableSql);
      const applied = await readAppliedMigrations();
      validateMigrationHistory(migrations, applied);
      const appliedVersions = new Set(applied.map((migration) => migration.version));
      const pending = migrations.filter(
        (migration) => !appliedVersions.has(migration.version),
      );

      for (const migration of pending) {
        for (const statement of migration.statements) {
          await client.query(statement);
        }
        await client.query(
          `INSERT INTO schema_migrations (
             version, filename, checksum, statement_count
           ) VALUES ($1, $2, $3, $4)`,
          [
            migration.version,
            migration.filename,
            migration.checksum,
            migration.statements.length,
          ],
        );
        console.log(
          `Applied ${migration.filename} (${migration.statements.length} statements)`,
        );
      }
      await client.query('COMMIT');
      if (pending.length === 0) console.log('Database schema is up to date.');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  }
} finally {
  await client.end();
}
