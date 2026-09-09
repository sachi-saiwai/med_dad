import assert from 'node:assert/strict';
import test from 'node:test';

import {
  parseMigration,
  validateMigrationHistory,
} from '../scripts/lib/migrations.js';

test('migration files are versioned, checksummed, and split explicitly', () => {
  const migration = parseMigration(
    '006_example.sql',
    'CREATE TABLE example (id bigint);\n-- statement-breakpoint\nCREATE INDEX example_idx ON example (id);\n',
  );

  assert.equal(migration.version, 6);
  assert.equal(migration.statements.length, 2);
  assert.match(migration.checksum, /^[a-f0-9]{64}$/u);
});

test('migration history rejects edits to already applied SQL', () => {
  const migration = parseMigration('001_initial.sql', 'SELECT 1;');

  assert.doesNotThrow(() =>
    validateMigrationHistory([migration], [{
      version: 1,
      filename: migration.filename,
      checksum: migration.checksum,
    }]),
  );
  assert.throws(
    () => validateMigrationHistory([migration], [{
      version: 1,
      filename: migration.filename,
      checksum: 'different',
    }]),
    /has been modified/u,
  );
});

test('migration history detects a database newer than the checkout', () => {
  assert.throws(
    () => validateMigrationHistory([], [{
      version: 7,
      filename: '007_future.sql',
      checksum: 'future',
    }]),
    /missing locally/u,
  );
});
