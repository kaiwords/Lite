# Database

## Current state: real, as of the 2026-07 Supabase migration

There is a real backend now: a Supabase-managed Postgres project ("Literature"),
with row-level security (RLS) enabled on every table. This superseded the
original mocks-only build described lower in this file for historical
context — see [`tasks-completed.md`](tasks-completed.md)'s "Migrate to
Supabase" entry for what changed and when.

| Layer | What it is | Where |
|---|---|---|
| Remote database | Supabase-hosted Postgres. Tables: `users`, `posts`, `post_pages`, `comments`, `marketplace_listings`, `ebook_chapters`, `audio_volumes`, `follows`, `conversations`, `messages`, `user_stripe_accounts`, `orders`, `order_items` — all RLS-enabled | `supabase/migrations/` (RLS policies only; the base schema itself was created directly against the project and isn't captured as migration files yet — see "Gaps" below) |
| Client access | `services/*_repository.dart` (one per domain: posts, comments, conversations, follows, marketplace, users, commerce), each calling the Supabase client directly | `lib/services/` |
| Auth | Real Supabase Auth (email/password) | `lib/providers/auth_provider.dart`, `lib/screens/auth/` |
| Payments | Stripe (Connect, "separate charges and transfers") for marketplace purchases/payouts — the one place with real server-side code, since Stripe's secret key and checkout amount validation can't live in the client | `supabase/functions/stripe-*` (Edge Functions), called via `lib/services/stripe_service.dart` |
| Local cache/fallback | `shared_preferences` via `LocalStore` — still used to seed instantly on launch and as an offline fallback; each provider's `loadFromSupabase()` then replaces it with live data | `lib/services/local_store.dart` |

### What's real vs. still mocked

Not everything reachable through the UI is actually backed by this database:

- **Real and synced**: posts, comments, marketplace listings, conversations/
  messages, the "who do I follow" side of the social graph, and (as of
  2026-08-13) marketplace purchases and payouts — real Stripe charges via
  Connect, see "Commerce (Stripe)" below.
- **Still fabricated**: the **Followers** list (shows other seeded users, not
  real reverse-follow data — there's no query for "who follows me" yet) and
  **creator tipping** (`earnings_screen.dart`'s "tips" are unrelated to
  marketplace sales — a reader tipping a writer directly, as opposed to
  buying a listing — and still generates entirely mock data; no tipping
  system exists, real or otherwise).
- **Still local-only, no file storage**: audio in the feed points at rotating
  demo URLs, not user uploads — `file_picker`-selected files (covers, PDFs,
  audio, and profile/cover photos) are read locally and never uploaded to
  Supabase Storage or anywhere else. `users.avatar_url`/`cover_image_url`
  *are* synced to the row, but the value is the device's local file path —
  meaningless on any other device until real storage exists. See
  "Commerce"/"Backend" gaps in [`out-of-scope.md`](out-of-scope.md).
  Exception: rows brought in by the legacy Firebase import (below) have a
  real `firebasestorage.googleapis.com` URL in `avatar_url`/
  `marketplace_listings.cover_image_url`, which works today but goes dead
  if the old `ram-literature-v2` Firebase project is ever deleted.
- **`marketplace_listings.qty`** (added 2026-08-07, first actually
  read/written by the app 2026-08-13): originally carried over by
  `scripts/firebase-migration/` from the legacy app's `book_listings`
  collection with no app flow touching it; now doubles as the "Quantity
  Available" field the List a Book sheet writes for Physical listings.
  **`is_sold_out`** (also added 2026-08-07, first actually read/written
  2026-08-13): now set true by the `claim-listing` Edge Function once a
  Free/Swap listing is claimed — see "Free & Swap listings" below.
  **`created_at`/`updated_at`** are still untouched by any current app flow.
- **`marketplace_listings.cover_image_url`** (added 2026-08-07, first
  actually written by the app 2026-08-10): the "List a Book" sheet's Cover
  step now sets this to a picked photo's local file path — same
  local-only caveat as `users.avatar_url`/`cover_image_url` above.
  **`marketplace_listings.cover_color`** (added 2026-08-10): the same
  Cover step's "design a cover" alternative — an ARGB int driving the
  gradient cover shown when no photo was picked.
- **`marketplace_listings.isbn`/`publisher`/`publication_date`** (added
  2026-08-13): book metadata the List a Book sheet asks for on Physical and
  E-Book listings (not Audio). **`condition`/`edition`** (same date):
  Physical-listing-only fields for the copy's condition (New/Like New/
  Good/Fair) and edition/language.
- **`marketplace_listings.shipping_methods`** (added 2026-08-13):
  which of Pickup/Delivery/Meetup a Physical listing's seller supports —
  set in the List a Book sheet, empty for listings that predate this field.
  The buyer picks one of these at checkout
  (`widgets/shipping_method_sheet.dart`); `stripe-create-checkout` requires
  and validates the choice server-side, writing it to
  `order_items.shipping_method`. **`pickup_location`/`pickup_phone`** and
  **`meetup_location`/`meetup_phone`** (same date, each pair required
  together when its method is checked; Delivery needs neither) are the
  seller's contact/location details for those methods — the phone numbers
  are only shown to buyers who own the listing. See "Shipping & Meetups"
  below.
- **`marketplace_listings.offer`** (added 2026-08-13): `sale` (default) /
  `free` / `swap` — Physical listings only, set via the "Offer" selector in
  the List a Book sheet; E-Book/Audio are always `sale`. Drives the Books
  section's Free/Swap filter row (underneath the format row) and the
  listing detail screen's Claim button. **`swap_wanted_for`** (same date,
  optional): free-text description of what the seller wants in return,
  meaningful only when `offer` is `swap`. See "Free & Swap listings" below.
- **No real-time transport**: `loadFromSupabase()` is a one-shot fetch on
  provider init, not a live subscription — a second device/session won't see
  a new message or post appear without a manual refresh/relaunch.

### Commerce (Stripe) — added 2026-08-13

Buying a listing (single "Buy Now" or multi-item cart checkout) charges a
real Stripe PaymentIntent and pays the seller out via Stripe Connect
("separate charges and transfers" — one PaymentIntent per cart even when it
spans multiple sellers; the platform account is charged, then
`stripe-webhook` creates a Transfer to each seller's connected account).
Sellers must finish Connect (Express) onboarding — a "Set up payouts"
banner on the Sales tab — before their listings are purchasable;
`stripe-create-checkout` enforces this server-side regardless of what the
client shows.

- `marketplace_listings.price_cents` is the canonical amount (integer
  cents); `price` stays a display string for existing UI code.
- `user_stripe_accounts` holds each user's Stripe identity (buyer
  `stripe_customer_id`, seller `stripe_connect_account_id` +
  `charges_enabled`) — deliberately not columns on `users`, since that
  table's "own row update" RLS policy would let a client forge
  `charges_enabled = true`. No client write policy at all; every row is
  written by the Edge Functions via the service-role key.
- `orders`/`order_items` are the real purchase/sale history —
  `CommerceRepository` reads them for the Library, Sales tab, and "already
  owned" checks; the old local-only `Purchase`/`Sale` state in
  `marketplace_account_provider.dart` is gone.
- Five Edge Functions, all in `supabase/functions/`: `stripe-connect-onboarding`
  (mints a Stripe-hosted onboarding link — opened in the system browser,
  since Stripe-hosted onboarding doesn't work in an embedded webview),
  `stripe-create-checkout` (validates listings server-side, creates the
  order + PaymentIntent), `stripe-webhook` (reconciles order status and
  creates seller Transfers on `payment_intent.succeeded`, idempotent
  against redelivery), `confirm-meetup` (added 2026-08-13, not
  Stripe-related — flips `order_items.meetup_confirmed`, see "Shipping &
  Meetups" below), and `claim-listing` (added 2026-08-13, also not
  Stripe-related — creates a $0 orders/order_items pair for a claimed
  Free/Swap listing with no PaymentIntent involved, see "Free & Swap
  listings" below). See each function's doc comment for the Connect
  charge-type reasoning.
- **Known gap**: there's no deep link back into the app after Stripe-hosted
  onboarding finishes in the browser (`stripe-connect-return` is a static
  "close this tab" page with no app state) — the seller has to return to
  the app manually and tap "I'm done" to re-check their status.

### Shipping & Meetups — added 2026-08-13

Physical listings only. A seller checks which of **Pickup** / **Delivery** /
**Meetup** they support (`marketplace_listings.shipping_methods`, in the List
a Book sheet); checking Pickup or Meetup requires entering that method's
location and phone number right there (`pickup_location` + `pickup_phone`
for Pickup, `meetup_location` + `meetup_phone` for Meetup — Delivery needs
nothing extra). A buyer picks
one of the seller's supported methods at checkout
(`widgets/shipping_method_sheet.dart`, shown from `runPurchaseFlow` before
the Payment Sheet, skipped entirely when nothing in the cart needs it).
`stripe-create-checkout` re-validates the choice server-side and writes it
to `order_items.shipping_method` — for Meetup, the buyer's own suggested
place/time (distinct from the seller's general `meetup_location`) goes to
`order_items.meetup_place` and `meetup_confirmed` starts `false`.

There's no negotiation UI: the seller sees the buyer's suggestion on the
Sales tab and taps "Confirm meetup" to flip `meetup_confirmed` to `true` via
the `confirm-meetup` Edge Function (a service-role-only write, same reason
as the Stripe functions below — `order_items` has no direct UPDATE RLS
policy for authenticated users). **Known gap**: the buyer's own Library
doesn't yet surface meetup status back to them — only the seller's Sales
tab does.

### Free & Swap listings — added 2026-08-13

Physical listings only. The Books section has a filter row underneath the
format row (All / Physical / E-Book / Audio) for `marketplace_listings.offer`:
**For Sale** (default), **Free**, or **Swap** — set in the List a Book
sheet, where picking Free or Swap hides the Price field entirely (nothing
is charged) and Swap adds an optional `swap_wanted_for` text field ("what
would you like in exchange?", blank meaning open to offers). Pickup/
Delivery/Meetup shipping methods work the same regardless of `offer` — a
free or swapped book still has to physically change hands somehow.

Claiming a Free/Swap listing goes through `claim-listing`, not
`stripe-create-checkout` — a $0 orders/order_items pair inserted straight
to `status: 'paid'`, no PaymentIntent, so it's ineligible for the
`transfer_status` payout flow (`platform_fee_cents: 0`,
`transfer_status: 'transferred'` since there's nothing to pay out). Once
claimed, `marketplace_listings.is_sold_out` flips `true` and the listing
stops being claimable by anyone else — unlike a Sale listing, which can be
bought repeatedly (no inventory decrement exists for Sale listings today).
**Known gap**: claim-listing checks `is_sold_out` before inserting but
doesn't lock the row, so two buyers racing to claim the same listing at
the exact same moment could both succeed — acceptable at this app's scale,
not fixed.

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
- **MarketplaceListing** — id, title, authorName, price (display string),
  priceCents (canonical amount), type (physical/ebook/audio), rating,
  reviewCount, linkedPostId, contentCategory, genre, description,
  pdfFileName, ebookContent, audioVolumes
- **Purchase** (`marketplace_account_provider.dart`) — listing, purchasedAt,
  orderId; backed by real `orders`/`order_items` rows via
  `CommerceRepository.fetchPurchases`, cached locally through `LocalStore`
  (`loadPurchases`/`savePurchases`) the same way other providers seed
  instantly then get replaced by `loadFromSupabase()`
- **Sale** (`marketplace_account_provider.dart`) — listing, soldAt,
  buyerName, amount (the seller's actual take, after the platform fee); via
  `CommerceRepository.fetchSales`
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
