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

const snapshot = await db.collection('comments').get();
let processed = 0;

for (const doc of snapshot.docs) {
  const data = doc.data();
  processed += 1;

  const authorId = uidMap[data.authorId];
  if (!authorId) {
    logFallback({ collection: 'comments', id: doc.id, reason: `no Supabase user for authorId ${data.authorId} — run 01-users.mjs first` });
    continue;
  }
  if (!data.postId) {
    logFallback({ collection: 'comments', id: doc.id, reason: 'missing postId' });
    continue;
  }

  const row = {
    id: doc.id,
    post_id: data.postId,
    author_id: authorId,
    text: data.content ?? '',
  };
  const createdAt = tsToIso(data.createdAt);
  if (createdAt) row.created_at = createdAt;

  if (commit) {
    const { error } = await supabase.from('comments').upsert(row, { onConflict: 'id' });
    if (error) logFallback({ collection: 'comments', id: doc.id, reason: `upsert failed: ${error.message}` });
  } else {
    console.log('[dry-run] comments upsert', row);
  }
}

printSummary('comments', processed);
