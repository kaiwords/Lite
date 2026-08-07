# Firebase → Supabase migration

One-time import of the legacy `ram-literature-v2` Firebase project's data
(`users`, `posts`, `comments`, `follows`, `book_listings`,
`conversations`/`messages`) into the current Supabase backend. See
`docs/database.md` and the plan this was built from for the full field
mapping and the reasoning behind it.

## Setup

```bash
cd scripts/firebase-migration
npm install
```

You need a local credentials file **outside this repo** — e.g.
`C:\Users\shres\secrets\literature-migration\migration.env` — containing:

```
SUPABASE_URL=https://iakggzyqbamynwxdfxxz.supabase.co
SUPABASE_SERVICE_KEY=sb_secret_xxxxxxxxxxxxxxxxxxxx
FIREBASE_SERVICE_ACCOUNT_PATH=C:\Users\shres\secrets\literature-migration\firebase-old-project.json
```

Every script takes `--env-file=<path to that file>` (or set
`MIGRATION_ENV_FILE` once in your shell so you don't have to repeat it).

## Dry run first — always

Every script defaults to a **dry run**: it reads from Firestore, prints
every row it would write and every fallback it had to apply (bad category,
unrecognized bookType, missing user mapping, email collision), and writes
nothing. Only `--commit` actually creates Supabase Auth users or writes
rows.

```bash
node run-all.mjs --env-file="C:\Users\shres\secrets\literature-migration\migration.env"
```

Read the fallback log. Fix anything that looks wrong in Firestore (or
adjust the mapping logic in `lib/constants.mjs`) before committing.

## Committing

Run phases **one at a time** the first time, checking Supabase after each
(via the dashboard or the `list_tables`/`execute_sql` MCP tools) rather
than trusting `run-all.mjs --commit` blindly on the first real attempt:

```bash
node 01-users.mjs --env-file=... --commit
# spot-check a few rows in Supabase, then:
node 02-posts.mjs --env-file=... --commit
node 03-comments.mjs --env-file=... --commit
node 04-follows.mjs --env-file=... --commit
node 05-marketplace-listings.mjs --env-file=... --commit
node 06-conversations-messages.mjs --env-file=... --commit
```

Once you trust it, `node run-all.mjs --env-file=... --commit` runs
everything in order.

Scripts are re-runnable: `01-users.mjs` persists a `uid-map.json` next to
your credentials file (Firebase UID → new Supabase user id) so re-running
never creates duplicate Auth accounts, and every table write is an
`upsert` keyed by id (messages are de-duplicated by
conversation+timestamp+text instead, since their id is a fresh UUID each
run).

## Password reset — separate, deliberate step

Migrated accounts are created with **no usable password** (Firebase's
scrypt hashes can't be imported into Supabase's bcrypt-based Auth). This
script does **not** email anyone. When you're ready for real users to
regain access, trigger Supabase's password-recovery flow yourself
(ideally rate-limited/batched) — that's a conscious decision with a real
side effect (emails sent to real people), not something to bundle into a
data-import run.

## What's intentionally left out

`post_pages`, `ebook_chapters`, and `audio_volumes` aren't populated — the
old Firestore data didn't show multi-page/chapter/volume structure. If a
post/listing doc is found with an unrecognized array field, it's logged
during the dry run rather than guessed at.

Firestore collections with no current-app equivalent (`coin_donations`,
`coin_transactions`, `drafts`, `favorites`, `likes`, `inquiries`,
`notifications`, `orders`, `reports`, `reviews`, `shares`, `wishlists`)
are not touched by this script at all.
