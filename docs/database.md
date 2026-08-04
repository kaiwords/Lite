# Database

## Current state: real, as of the 2026-07 Supabase migration

There is a real backend now: a Supabase-managed Postgres project ("Literature"),
with row-level security (RLS) enabled on every table. This superseded the
original mocks-only build described lower in this file for historical
context — see [`tasks-completed.md`](tasks-completed.md)'s "Migrate to
Supabase" entry for what changed and when.

| Layer | What it is | Where |
|---|---|---|
| Remote database | Supabase-hosted Postgres. Tables: `users`, `posts`, `post_pages`, `comments`, `marketplace_listings`, `ebook_chapters`, `audio_volumes`, `follows`, `conversations`, `messages` — all RLS-enabled | `supabase/migrations/` (RLS policies only; the base schema itself was created directly against the project and isn't captured as migration files yet — see "Gaps" below) |
| Client access | `services/*_repository.dart` (one per domain: posts, comments, conversations, follows, marketplace, users), each calling the Supabase client directly | `lib/services/` |
| Auth | Real Supabase Auth (email/password) | `lib/providers/auth_provider.dart`, `lib/screens/auth/` |
| Local cache/fallback | `shared_preferences` via `LocalStore` — still used to seed instantly on launch and as an offline fallback; each provider's `loadFromSupabase()` then replaces it with live data | `lib/services/local_store.dart` |

### What's real vs. still mocked

Not everything reachable through the UI is actually backed by this database:

- **Real and synced**: posts, comments, marketplace listings, conversations/
  messages, and the "who do I follow" side of the social graph.
- **Still fabricated**: the **Followers** list (shows other seeded users, not
  real reverse-follow data — there's no query for "who follows me" yet) and
  **Earnings/tips** (`earnings_screen.dart` generates entirely mock tip data;
  no payment or tipping system exists at all, real or otherwise).
- **Still local-only, no file storage**: audio in the feed points at rotating
  demo URLs, not user uploads — `file_picker`-selected files (covers, PDFs,
  audio) are read locally and never uploaded to Supabase Storage or anywhere
  else. See "Commerce"/"Backend" gaps in [`out-of-scope.md`](out-of-scope.md).
- **No real-time transport**: `loadFromSupabase()` is a one-shot fetch on
  provider init, not a live subscription — a second device/session won't see
  a new message or post appear without a manual refresh/relaunch.

### Gaps to close before relying on this as the system of record

- The base table schema was applied directly to the Supabase project (not
  via migration files), so `supabase/migrations/` can't currently rebuild
  the database from scratch — only the two RLS-policy migrations are
  captured. A fresh environment (staging, disaster recovery) would need the
  schema exported and turned into migrations first.
- Every write in the app is optimistic-local-then-sync — repository
  failures no longer fail silently (fixed 2026-07-27), but there's still no
  retry/reconciliation if a write never makes it to the server.

## Entities (current shape, as Dart models)

Client-side shapes below; the Postgres tables use snake_case columns and are
mapped via each model's `fromSupabaseRow` (distinct from `fromJson`, which
reads the app's own camelCase local-cache format).

- **User** (`LitUser`) — id, username, displayName, avatarUrl, bio,
  followersCount, followingCount, postsCount, earnings, isFollowing,
  isVerified
- **Post** — id, author (embedded User), title, content, category (enum),
  createdAt, likesCount, commentsCount, sharesCount, isLiked, isFavourited,
  audioUrl, coverImageUrl, linkedListingId, bookId
- **Comment** — id, postId, author (embedded User), text, createdAt,
  likesCount, isLiked
- **MarketplaceListing** — id, title, authorName, price (string, not a
  numeric/currency type), type (physical/ebook/audio), rating, reviewCount,
  linkedPostId, contentCategory, genre, description, pdfFileName,
  ebookContent, audioVolumes
- **Purchase** — referenced by `LocalStore` (`loadPurchases`/`savePurchases`)
- **Book** — id, title, authorName, subtitle, coverColor, coverTextColor,
  pages (each with type/chapterTitle/content)

Note: several relations are denormalized (e.g. `Post.author` embeds a full
`LitUser` rather than a foreign key; `MarketplaceListing.authorName` is a
plain string rather than a reference to a `LitUser`). A real schema would
need to normalize these.

## Decision record: why Supabase

Decided over Firebase given the clearly relational entity model above
(users, posts, comments, listings, follows) and the need for transactional
integrity — Postgres was the natural fit, and Supabase gets a managed
Postgres + auth + RLS stood up quickly without standing up a bespoke API
server. `web-app/` remains unbuilt; if/when it exists it would share this
same backend rather than getting its own.

File storage (Supabase Storage) was not part of this migration — uploaded
covers/PDFs/audio still aren't persisted anywhere, per the gaps above.
