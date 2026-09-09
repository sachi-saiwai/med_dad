import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const migrationFilePattern = /^(\d{3,})_([a-z0-9][a-z0-9_-]*)\.sql$/u;
const statementBreakpointPattern = /^\s*-- statement-breakpoint\s*$/gmu;

export interface Migration {
  version: number;
  filename: string;
  checksum: string;
  statements: string[];
}

export interface AppliedMigration {
  version: number;
  filename: string;
  checksum: string;
}

export const checksumMigration = (source: string): string =>
  createHash('sha256')
    .update(source.replace(/\r\n/g, '\n'))
    .digest('hex');

export const parseMigration = (filename: string, source: string): Migration => {
  const match = migrationFilePattern.exec(filename);
  if (!match?.[1]) {
    throw new Error(
      `Invalid migration filename "${filename}". Expected NNN_description.sql.`,
    );
  }
  const version = Number.parseInt(match[1], 10);
  if (!Number.isSafeInteger(version) || version < 1) {
    throw new Error(`Invalid migration version in "${filename}".`);
  }
  const statements = source
    .split(statementBreakpointPattern)
    .map((statement) => statement.trim())
    .filter(Boolean);
  if (statements.length === 0) {
    throw new Error(`Migration "${filename}" contains no SQL statements.`);
  }
  return {
    version,
    filename,
    checksum: checksumMigration(source),
    statements,
  };
};

export const loadMigrations = async (directory: string): Promise<Migration[]> => {
  const filenames = (await readdir(directory))
    .filter((filename) => filename.endsWith('.sql'))
    .sort((left, right) => left.localeCompare(right));
  const migrations = await Promise.all(
    filenames.map(async (filename) =>
      parseMigration(filename, await readFile(resolve(directory, filename), 'utf8')),
    ),
  );

  const versions = new Set<number>();
  for (const migration of migrations) {
    if (versions.has(migration.version)) {
      throw new Error(`Duplicate migration version ${migration.version}.`);
    }
    versions.add(migration.version);
  }
  return migrations.sort((left, right) => left.version - right.version);
};

export const validateMigrationHistory = (
  migrations: Migration[],
  appliedMigrations: AppliedMigration[],
): void => {
  const localByVersion = new Map(
    migrations.map((migration) => [migration.version, migration]),
  );
  for (const applied of appliedMigrations) {
    const local = localByVersion.get(applied.version);
    if (!local) {
      throw new Error(
        `Database migration ${applied.version} (${applied.filename}) is missing locally.`,
      );
    }
    if (local.filename !== applied.filename) {
      throw new Error(
        `Migration ${applied.version} was renamed from "${applied.filename}" to "${local.filename}".`,
      );
    }
    if (local.checksum !== applied.checksum) {
      throw new Error(
        `Applied migration "${local.filename}" has been modified. Add a new migration instead.`,
      );
    }
  }
};

