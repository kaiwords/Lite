import { randomUUID } from 'node:crypto';
import { loadEnv, isCommit } from './lib/env.mjs';
import { firestore, tsToIso } from './lib/firebase.mjs';
import { supabaseAdmin } from './lib/supabase.mjs';
import { loadUidMap, saveUidMap } from './lib/uid-map.mjs';
import { logFallback, printSummary } from './lib/log.mjs';

const env = loadEnv();
const commit = isCommit();
console.log(commit ? '=== COMMIT RUN ===' : '=== DRY RUN (pass --commit to write) ===');

const db = firestore(env.firebaseServiceAccountPath);
const supabase = supabaseAdmin(env.supabaseUrl, env.supabaseServiceKey);
const uidMap = loadUidMap(env.envFile);

// Built once so checking "does this email already have a Supabase account"
// doesn't mean a paginated lookup per user.
async function loadExistingEmails() {
  const byEmail = new Map();
  let page = 1;
  for (;;) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) throw error;
    for (const u of data.users) byEmail.set(u.email?.toLowerCase(), u.id);
    if (data.users.length < 1000) break;
    page += 1;
  }
  return byEmail;
}

const existingEmails = commit ? await loadExistingEmails() : new Map();

const snapshot = await db.collection('users').get();
let processed = 0;

for (const doc of snapshot.docs) {
  const firebaseUid = doc.id;
  const data = doc.data();
  processed += 1;

  if (!data.email) {
    logFallback({ collection: 'users', firebaseUid, reason: 'missing email, cannot create Auth account' });
    continue;
  }

  // Only a *real* uid-map.json entry counts as "already migrated" — a
  // dry run must never persist a placeholder, or a later --commit run
  // would find it here and wrongly skip real Auth account creation.
  let supabaseId = uidMap[firebaseUid];

  if (!supabaseId) {
    const existing = existingEmails.get(data.email.toLowerCase());
    if (existing) {
      supabaseId = existing;
      logFallback({ collection: 'users', firebaseUid, email: data.email, reason: 'email already had a Supabase account, reusing it' });
      uidMap[firebaseUid] = supabaseId;
      saveUidMap(env.envFile, uidMap);
    } else if (commit) {
      // public.users has an on_auth_user_created trigger that inserts a row
      // itself, falling back to email-local-part as username when
      // raw_user_meta_data has none — pass the real username so it doesn't
      // collide with an existing account's fallback-derived username
      // (username has its own UNIQUE constraint the trigger doesn't guard).
      const { data: created, error } = await supabase.auth.admin.createUser({
        email: data.email,
        password: randomUUID() + randomUUID(),
        email_confirm: true,
        user_metadata: {
          migrated_from_firebase_uid: firebaseUid,
          username: data.username ?? undefined,
          display_name: data.username ?? undefined,
        },
      });
      if (error) {
        logFallback({ collection: 'users', firebaseUid, email: data.email, reason: `createUser failed: ${error.message}` });
        continue;
      }
      supabaseId = created.user.id;
      uidMap[firebaseUid] = supabaseId;
      saveUidMap(env.envFile, uidMap);
    } else {
      supabaseId = `dry-run-${firebaseUid}`;
    }
  }

  const row = {
    id: supabaseId,
    username: data.username ?? null,
    display_name: data.username ?? null,
    bio: data.bio ?? '',
    avatar_url: data.profileImageUrl ?? null,
    followers_count: data.followersCount ?? 0,
    following_count: data.followingCount ?? 0,
    posts_count: data.postsCount ?? 0,
  };
  // created_at is NOT NULL with a now() default — only set it when
  // Firestore has a value, so a missing field uses the column default
  // instead of an explicit null violating the constraint.
  const createdAt = tsToIso(data.createdAt);
  if (createdAt) row.created_at = createdAt;

  if (commit) {
    const { error } = await supabase.from('users').upsert(row, { onConflict: 'id' });
    if (error) logFallback({ collection: 'users', firebaseUid, reason: `upsert failed: ${error.message}` });
  } else {
    console.log('[dry-run] users upsert', row);
  }
}

printSummary('users', processed);
