import { loadEnv, isCommit } from './lib/env.mjs';
import { firestore, tsToIso } from './lib/firebase.mjs';
import { supabaseAdmin } from './lib/supabase.mjs';
import { loadUidMap } from './lib/uid-map.mjs';
import { logFallback, printSummary } from './lib/log.mjs';
import { VALID_CATEGORIES, DEFAULT_CATEGORY } from './lib/constants.mjs';

const env = loadEnv();
const commit = isCommit();
console.log(commit ? '=== COMMIT RUN ===' : '=== DRY RUN (pass --commit to write) ===');

const db = firestore(env.firebaseServiceAccountPath);
const supabase = supabaseAdmin(env.supabaseUrl, env.supabaseServiceKey);
const uidMap = loadUidMap(env.envFile);

const snapshot = await db.collection('posts').get();
let processed = 0;

for (const doc of snapshot.docs) {
  const data = doc.data();
  processed += 1;

  // A missing status field means an older post predating that field being
  // added, not a draft/deleted/reported one — only skip an explicit
  // non-active status, don't treat "field absent" as "not active".
  if (data.status != null && data.status !== 'active') {
    logFallback({ collection: 'posts', id: doc.id, reason: `status is "${data.status}", not "active" — skipped` });
    continue;
  }

  const authorId = uidMap[data.authorId];
  if (!authorId) {
    logFallback({ collection: 'posts', id: doc.id, reason: `no Supabase user for authorId ${data.authorId} — run 01-users.mjs first` });
    continue;
  }

  let category = data.category;
  if (!VALID_CATEGORIES.includes(category)) {
    logFallback({ collection: 'posts', id: doc.id, reason: `unrecognized category "${category}", defaulted to "${DEFAULT_CATEGORY}"` });
    category = DEFAULT_CATEGORY;
  }

  if (Array.isArray(data.pages) && data.pages.length) {
    logFallback({ collection: 'posts', id: doc.id, reason: 'has a "pages" array — post_pages import not implemented, left out' });
  }

  const row = {
    id: doc.id,
    author_id: authorId,
    title: data.title ?? '',
    content: data.content ?? '',
    category,
    likes_count: data.likesCount ?? 0,
    comments_count: data.commentsCount ?? 0,
    shares_count: data.sharesCount ?? 0,
  };
  const createdAt = tsToIso(data.createdAt);
  if (createdAt) row.created_at = createdAt;

  if (commit) {
    const { error } = await supabase.from('posts').upsert(row, { onConflict: 'id' });
    if (error) logFallback({ collection: 'posts', id: doc.id, reason: `upsert failed: ${error.message}` });
  } else {
    console.log('[dry-run] posts upsert', row);
  }
}

printSummary('posts', processed);
