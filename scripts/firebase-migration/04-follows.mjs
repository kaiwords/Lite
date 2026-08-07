import { loadEnv, isCommit } from './lib/env.mjs';
import { firestore, tsToIso } from './lib/firebase.mjs';
import { supabaseAdmin } from './lib/supabase.mjs';
import { loadUidMap } from './lib/uid-map.mjs';
import { logFallback, printSummary } from './lib/log.mjs';

const env = loadEnv();
const commit = isCommit();
console.log(commit ? '=== COMMIT RUN ===' : '=== DRY RUN (pass --commit to write) ===');

const db = firestore(env.firebaseServiceAccountPath);
const supabase = supabaseAdmin(env.supabaseUrl, env.supabaseServiceKey);
const uidMap = loadUidMap(env.envFile);

const snapshot = await db.collection('follows').get();
let processed = 0;

for (const doc of snapshot.docs) {
  const data = doc.data();
  processed += 1;

  const followerId = uidMap[data.followerId];
  const followeeId = uidMap[data.followingId];
  if (!followerId || !followeeId) {
    logFallback({ collection: 'follows', id: doc.id, reason: `missing Supabase user for follower (${data.followerId}) or followee (${data.followingId})` });
    continue;
  }

  const row = {
    follower_id: followerId,
    followee_id: followeeId,
  };
  const createdAt = tsToIso(data.createdAt);
  if (createdAt) row.created_at = createdAt;

  if (commit) {
    const { error } = await supabase.from('follows').upsert(row, { onConflict: 'follower_id,followee_id' });
    if (error) logFallback({ collection: 'follows', id: doc.id, reason: `upsert failed: ${error.message}` });
  } else {
    console.log('[dry-run] follows upsert', row);
  }
}

printSummary('follows', processed);
