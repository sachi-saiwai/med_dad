import assert from 'node:assert/strict';
import test from 'node:test';

import {
  HttpError,
  inviteCodeRequired,
} from '../api/_lib/config.js';
import {
  validateFirebaseClaims,
  type FirebaseTokenClaims,
} from '../api/_lib/firebase-auth.js';
import {
  inviteCodeHash,
  normalizeInviteCode,
  safeFileName,
  sanitizeSnapshot,
} from '../api/_lib/user-data.js';

const validClaims = (overrides: Partial<FirebaseTokenClaims> = {}) => ({
  aud: 'medlicense-production',
  email: 'Doctor@Example.JP',
  email_verified: true,
  exp: 2_000,
  iat: 900,
  iss: 'https://securetoken.google.com/medlicense-production',
  name: '  資格 太郎  ',
  sub: 'firebase-user-1',
  ...overrides,
});

test('Firebase claims are limited to the configured project and verified email', () => {
  const user = validateFirebaseClaims(
    validClaims(),
    'medlicense-production',
    1_000,
  );
  assert.deepEqual(user, {
    id: 'firebase-user-1',
    email: 'doctor@example.jp',
    displayName: '資格 太郎',
  });

  for (const claims of [
    validClaims({ aud: 'another-project' }),
    validClaims({ email_verified: false }),
    validClaims({ email_verified: undefined }),
    validClaims({ exp: 1_000 }),
  ]) {
    assert.throws(
      () =>
        validateFirebaseClaims(claims, 'medlicense-production', 1_000),
      (error) => error instanceof HttpError && error.statusCode === 401,
    );
  }
});

test('invite codes normalize formatting before hashing', () => {
  assert.equal(normalizeInviteCode(' abcde-fghjk-23456 '), 'ABCDEFGHJK23456');
  assert.equal(
    inviteCodeHash('abcde-fghjk-23456'),
    inviteCodeHash(' ABCDE FGHJK 23456 '),
  );
  assert.throws(
    () => inviteCodeHash('short'),
    (error) => error instanceof HttpError && error.code === 'invalid_invite_code',
  );
});

test('invite-only access is disabled by default and remains reversible', () => {
  const previous = process.env.REQUIRE_INVITE_CODE;
  try {
    delete process.env.REQUIRE_INVITE_CODE;
    assert.equal(inviteCodeRequired(), false);
    process.env.REQUIRE_INVITE_CODE = 'true';
    assert.equal(inviteCodeRequired(), true);
    process.env.REQUIRE_INVITE_CODE = 'false';
    assert.equal(inviteCodeRequired(), false);
  } finally {
    if (previous === undefined) delete process.env.REQUIRE_INVITE_CODE;
    else process.env.REQUIRE_INVITE_CODE = previous;
  }
});

test('snapshots are rebound to the authenticated user and size limited', () => {
  const snapshot = sanitizeSnapshot(
    { accountId: 'attacker', displayName: '利用者' },
    'firebase-user-1',
  );
  assert.equal(snapshot.accountId, 'firebase-user-1');
  assert.throws(
    () => sanitizeSnapshot({ note: 'x'.repeat(1024 * 1024) }, 'user'),
    (error) => error instanceof HttpError && error.statusCode === 413,
  );
});

test('attachment names cannot contain path separators or control characters', () => {
  assert.equal(safeFileName('../証明\u0000書.pdf'), '.._証明_書.pdf');
});
