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

// Firestore stores one shared doc per pair of participants. Supabase's
// schema is per-owner (owner_id/peer_id, RLS-scoped to owner_id =
// auth.uid()) — see mobile-app/lib/models/conversation.dart — so each
// Firestore conversation fans out into two Supabase rows, one per
// participant's perspective, and every message is written into both.
function conversationRowId(firestoreConvId, ownerSupabaseId) {
  return `${firestoreConvId}:${ownerSupabaseId}`;
}

const snapshot = await db.collection('conversations').get();
let processed = 0;

for (const convDoc of snapshot.docs) {
  const data = convDoc.data();
  processed += 1;

  const participants = data.participants ?? [];
  if (participants.length !== 2) {
    logFallback({ collection: 'conversations', id: convDoc.id, reason: `expected 2 participants, found ${participants.length} — skipped` });
    continue;
  }

  const [uidA, uidB] = participants;
  const perspectives = [
    { ownerFirebaseUid: uidA, peerFirebaseUid: uidB },
    { ownerFirebaseUid: uidB, peerFirebaseUid: uidA },
  ];

  const messagesSnapshot = await convDoc.ref.collection('messages').get();

  for (const { ownerFirebaseUid, peerFirebaseUid } of perspectives) {
    const ownerId = uidMap[ownerFirebaseUid];
    const peerId = uidMap[peerFirebaseUid];
    if (!ownerId || !peerId) {
      logFallback({ collection: 'conversations', id: convDoc.id, reason: `missing Supabase user for owner (${ownerFirebaseUid}) or peer (${peerFirebaseUid})` });
      continue;
    }

    const rowId = conversationRowId(convDoc.id, ownerId);
    const conversationRow = {
      id: rowId,
      owner_id: ownerId,
      peer_id: peerId,
    };
    // created_at is NOT NULL with a now() default. Firestore has no
    // separate createdAt for conversations — updatedAt is the best
    // available timestamp; omit entirely (falls to the default) if absent.
    const conversationCreatedAt = tsToIso(data.updatedAt);
    if (conversationCreatedAt) conversationRow.created_at = conversationCreatedAt;

    if (commit) {
      const { error } = await supabase.from('conversations').upsert(conversationRow, { onConflict: 'id' });
      if (error) {
        logFallback({ collection: 'conversations', id: convDoc.id, reason: `upsert failed: ${error.message}` });
        continue;
      }
    } else {
      console.log('[dry-run] conversations upsert', conversationRow);
    }

    let existingKeys = new Set();
    if (commit) {
      const { data: existing, error } = await supabase
        .from('messages')
        .select('sent_at, text')
        .eq('conversation_id', rowId);
      if (error) {
        logFallback({ collection: 'messages', id: convDoc.id, reason: `existing-message lookup failed: ${error.message}` });
      } else {
        existingKeys = new Set(existing.map((m) => `${m.sent_at}|${m.text}`));
      }
    }

    for (const msgDoc of messagesSnapshot.docs) {
      const msg = msgDoc.data();
      const senderId = uidMap[msg.senderId];
      if (!senderId) {
        logFallback({ collection: 'messages', id: `${convDoc.id}/${msgDoc.id}`, reason: `no Supabase user for senderId ${msg.senderId}` });
        continue;
      }

      const sentAt = tsToIso(msg.timestamp);
      const text = msg.content ?? '';
      const key = `${sentAt}|${text}`;
      if (existingKeys.has(key)) continue;

      const messageRow = {
        conversation_id: rowId,
        text,
        from_me: msg.senderId === ownerFirebaseUid,
        is_read: msg.isRead ?? false,
        sender_id: senderId,
      };
      // sent_at is NOT NULL with a now() default — omit rather than send
      // an explicit null when Firestore has no timestamp.
      if (sentAt) messageRow.sent_at = sentAt;

      if (commit) {
        const { error } = await supabase.from('messages').insert(messageRow);
        if (error) logFallback({ collection: 'messages', id: `${convDoc.id}/${msgDoc.id}`, reason: `insert failed: ${error.message}` });
      } else {
        console.log('[dry-run] messages insert', messageRow);
      }
    }
  }
}

printSummary('conversations + messages', processed);
