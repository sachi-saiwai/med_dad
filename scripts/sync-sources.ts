import { config } from 'dotenv';

config({ path: process.env.MEDLICENSE_ENV_FILE || '.env.local' });

const { runSourceSync } = await import('../api/_lib/sync.js');

const parsedSourceId = Number.parseInt(process.env.SYNC_SOURCE_ID || '', 10);

const summary = await runSourceSync({
  triggerType: 'manual',
  limit: Number.parseInt(process.env.SYNC_LIMIT || '10', 10),
  sourceId: Number.isFinite(parsedSourceId) ? parsedSourceId : undefined,
  force: process.env.SYNC_FORCE === 'true',
});

console.log(JSON.stringify(summary, null, 2));
if (summary.status === 'failed') process.exitCode = 1;
