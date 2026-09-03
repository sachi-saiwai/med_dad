import webpush from 'web-push';

import {
  assertCronAuthorization,
  optionalEnv,
} from '../_lib/config.js';
import { db } from '../_lib/db.js';
import { bearerHeader, methodNotAllowed, sendError } from '../_lib/http.js';
import type { ApiRequest, ApiResponse } from '../_lib/vercel.js';

interface ReminderRow {
  user_id: string;
  snapshot: Record<string, unknown>;
  subscription_id: string;
  endpoint: string;
  p256dh: string;
  auth: string;
}

interface QualificationLike {
  id?: unknown;
  name?: unknown;
  deadline?: unknown;
}

const tokyoDate = (date = new Date()): Date => {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
  return new Date(`${parts}T00:00:00Z`);
};

const parseDeadline = (value: unknown): Date | null => {
  if (typeof value !== 'string') return null;
  const match = value.trim().match(/^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$/);
  if (!match) return null;
  const date = new Date(
    Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])),
  );
  return Number.isNaN(date.getTime()) ? null : date;
};

const deadlineReminders = (
  snapshot: Record<string, unknown>,
  today: Date,
): Array<{ key: string; title: string; body: string }> => {
  const settings =
    snapshot.settings && typeof snapshot.settings === 'object'
      ? (snapshot.settings as Record<string, unknown>)
      : {};
  if (settings.deadlineNotifications === false) return [];
  const qualifications = Array.isArray(snapshot.qualifications)
    ? (snapshot.qualifications as QualificationLike[])
    : [];
  const results: Array<{ key: string; title: string; body: string }> = [];
  for (const qualification of qualifications) {
    const deadline = parseDeadline(qualification.deadline);
    if (!deadline) continue;
    const days = Math.round((deadline.getTime() - today.getTime()) / 86_400_000);
    if (![180, 90, 30, 7].includes(days)) continue;
    const name =
      typeof qualification.name === 'string' && qualification.name.trim()
        ? qualification.name.trim()
        : '登録資格';
    const id =
      typeof qualification.id === 'string' && qualification.id
        ? qualification.id
        : name;
    const deadlineText = deadline.toISOString().slice(0, 10).replaceAll('-', '/');
    results.push({
      key: `${id}:${deadlineText}:${days}`,
      title: `${name}の更新期限まで${days}日`,
      body: `更新期限は${deadlineText}です。必要単位と提出条件を確認しましょう。`,
    });
  }
  return results;
};

export default async function handler(
  request: ApiRequest,
  response: ApiResponse,
): Promise<ApiResponse> {
  if (request.method !== 'GET') return methodNotAllowed(response, 'GET');
  try {
    assertCronAuthorization(bearerHeader(request));
    const publicKey = optionalEnv('WEB_PUSH_PUBLIC_KEY');
    const privateKey = optionalEnv('WEB_PUSH_PRIVATE_KEY');
    const subject = optionalEnv('WEB_PUSH_SUBJECT');
    if (!publicKey || !privateKey || !subject) {
      throw new Error('Web Push VAPID settings are not configured');
    }
    webpush.setVapidDetails(subject, publicKey, privateKey);

    const rows = (await db().query(
      `SELECT s.user_id, s.snapshot,
              p.id AS subscription_id, p.endpoint, p.p256dh, p.auth
         FROM user_snapshots s
         JOIN web_push_subscriptions p ON p.user_id = s.user_id`,
    )) as unknown as ReminderRow[];
    const today = tokyoDate();
    let sent = 0;
    let skipped = 0;
    let removed = 0;

    for (const row of rows) {
      for (const reminder of deadlineReminders(row.snapshot, today)) {
        const inserted = await db().query(
          `INSERT INTO web_push_deliveries (
             user_id, subscription_id, notification_key
           ) VALUES ($1, $2, $3)
           ON CONFLICT (subscription_id, notification_key) DO NOTHING
           RETURNING id`,
          [row.user_id, Number(row.subscription_id), reminder.key],
        );
        if (!inserted[0]) {
          skipped += 1;
          continue;
        }
        try {
          await webpush.sendNotification(
            {
              endpoint: row.endpoint,
              keys: { p256dh: row.p256dh, auth: row.auth },
            },
            JSON.stringify({
              title: reminder.title,
              body: reminder.body,
              url: '/',
              tag: reminder.key,
            }),
            { TTL: 24 * 60 * 60, urgency: 'normal' },
          );
          sent += 1;
        } catch (error) {
          const statusCode =
            typeof error === 'object' && error && 'statusCode' in error
              ? Number((error as { statusCode: unknown }).statusCode)
              : 0;
          if (statusCode === 404 || statusCode === 410) {
            await db().query(`DELETE FROM web_push_subscriptions WHERE id = $1`, [
              Number(row.subscription_id),
            ]);
            removed += 1;
          } else {
            await db().query(
              `DELETE FROM web_push_deliveries
                WHERE subscription_id = $1 AND notification_key = $2`,
              [Number(row.subscription_id), reminder.key],
            );
            console.error(error);
          }
        }
      }
    }

    return response.status(200).json({
      status: 'ok',
      subscriptions: rows.length,
      sent,
      skipped,
      removed,
      date: today.toISOString().slice(0, 10),
    });
  } catch (error) {
    return sendError(response, error);
  }
}
