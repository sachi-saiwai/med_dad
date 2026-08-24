import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { db } = await import('../api/_lib/db.js');

const migrationFiles = [
  '001_initial.sql',
  '002_rule_review_audit.sql',
  '003_renewal_year_scope.sql',
  '004_source_rule_role.sql',
];

for (const filename of migrationFiles) {
  const fullPath = resolve('db/migrations', filename);
  const source = await readFile(fullPath, 'utf8');
  const statements = source
    .split('-- statement-breakpoint')
    .map((statement) => statement.trim())
    .filter(Boolean);

  for (const statement of statements) {
    await db().query(statement);
  }
  console.log(`Applied ${filename} (${statements.length} statements)`);
}
