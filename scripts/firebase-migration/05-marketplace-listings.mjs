import { loadEnv, isCommit } from './lib/env.mjs';
import { firestore, tsToIso } from './lib/firebase.mjs';
import { supabaseAdmin } from './lib/supabase.mjs';
import { loadUidMap } from './lib/uid-map.mjs';
import { logFallback, printSummary } from './lib/log.mjs';
import { classifyListingType, DEFAULT_LISTING_TYPE } from './lib/constants.mjs';

const env = loadEnv();
const commit = isCommit();
console.log(commit ? '=== COMMIT RUN ===' : '=== DRY RUN (pass --commit to write) ===');

const db = firestore(env.firebaseServiceAccountPath);
const supabase = supabaseAdmin(env.supabaseUrl, env.supabaseServiceKey);
const uidMap = loadUidMap(env.envFile);

const snapshot = await db.collection('book_listings').get();
let processed = 0;

for (const doc of snapshot.docs) {
  const data = doc.data();
  processed += 1;

  const sellerId = uidMap[data.sellerId];
  if (!sellerId) {
    logFallback({ collection: 'book_listings', id: doc.id, reason: `no Supabase user for sellerId ${data.sellerId} — run 01-users.mjs first` });
    continue;
  }

  let type = classifyListingType(data.bookType);
  if (!type) {
    logFallback({ collection: 'book_listings', id: doc.id, reason: `unrecognized bookType "${data.bookType}", defaulted to "${DEFAULT_LISTING_TYPE}"` });
    type = DEFAULT_LISTING_TYPE;
  }

  // "category" (e.g. "Non-Fiction") doesn't fit either content_category's
  // ContentCategory enum or genre's Genre enum — confirmed to leave both
  // null rather than force a bad guess.

  const row = {
    id: doc.id,
    title: data.title ?? '',
    author_name: data.sellerName ?? '',
    seller_id: sellerId,
    price: data.price != null ? String(data.price) : '0',
    type,
    description: data.description ?? '',
    cover_image_url: data.imageUrl ?? null,
    qty: data.qty ?? null,
    is_sold_out: data.isSoldOut ?? false,
  };
  // created_at/updated_at are NOT NULL with a now() default — only set them
  // when Firestore actually has a value, so a missing field falls through
  // to the column default instead of an explicit null violating the constraint.
  const createdAt = tsToIso(data.createdAt);
  const updatedAt = tsToIso(data.updatedAt);
  if (createdAt) row.created_at = createdAt;
  if (updatedAt) row.updated_at = updatedAt;

  if (commit) {
    const { error } = await supabase.from('marketplace_listings').upsert(row, { onConflict: 'id' });
    if (error) logFallback({ collection: 'book_listings', id: doc.id, reason: `upsert failed: ${error.message}` });
  } else {
    console.log('[dry-run] marketplace_listings upsert', row);
  }
}

printSummary('book_listings -> marketplace_listings', processed);
