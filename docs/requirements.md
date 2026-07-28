# Requirements — Literature

> Reverse-documented from the current codebase. "Met" = observably true in
> the code today; everything else is a gap to close before a real launch.

## Functional Requirements

| # | Requirement | Status |
|---|---|---|
| F1 | Users can view a feed of posts across content categories | Met |
| F2 | Users can like, comment on, share, and favourite posts | Met (comments sync to Supabase; likes/shares/favourites are still local-only counters) |
| F3 | Posts can include audio | Met (streams from demo URLs — no real upload pipeline, see F21) |
| F4 | Users can read full-length books in-app (paginated reader) | Met |
| F5 | Users can browse a marketplace of physical books, e-books, audiobooks | Met |
| F6 | Users can filter marketplace by type/genre/category | Met |
| F7 | Users can add listings to a cart and view purchase history | Met (local only, no real checkout/payment) |
| F8 | Creators can list their own work for sale (sell flow) | Met — syncs to Supabase (`marketplace_listings`) |
| F9 | Users can follow/unfollow other users | Met — the "who I follow" write syncs to Supabase; the reverse "who follows me" read is still mock data (see F22) |
| F10 | Users can view and edit their own profile | Met — profile row lives in Supabase (`users` table), not just device-local |
| F11 | Users can message other users 1:1 | Met — persists to Supabase (`conversations`/`messages`), but not delivered live (see F23) |
| F12 | Users can search | Met (UI present — verify against live mock data scope) |
| F13 | Users receive alerts/notifications (incl. marketplace-specific) | Met (UI only, no push, no server-generated events) |
| F14 | Users can switch theme (system/light/dark) | Met, persisted locally |
| F15 | User accounts persist across sessions | Met — real Supabase Auth session, not just device-local |
| F16 | User accounts sync across devices | Met for posts/comments/listings/conversations/follows-I-make; **not met** for file uploads (see F21) or followers-of-me (see F22) |
| F17 | Real user authentication (sign up/login) | Met — Supabase Auth, email/password |
| F18 | Real payments for marketplace purchases | **Not met** |
| F19 | Push notifications | **Not met** |
| F20 | Content moderation / reporting | **Not met** |
| F21 | Uploaded audio/PDFs/covers are actually stored server-side | **Not met** — `file_picker` selections are read locally and never uploaded; feed/marketplace audio uses rotating demo URLs |
| F22 | Followers list reflects real "who follows me" data | **Not met** — placeholder list (other seeded users), no reverse-follow query exists |
| F23 | Messages/posts delivered live to other sessions | **Not met** — each provider fetches once on init, no realtime subscription |
| F24 | A failed backend write is surfaced to the user, not silent | Met (2026-07-27) — every write path shows a "couldn't sync" message on failure instead of looking like it succeeded |

## Non-Functional Requirements

| # | Requirement | Status |
|---|---|---|
| N1 | App remains usable offline | Partially met — requires auth (can't sign in offline), but once signed in, screens fall back to local/cached data and writes queue as local-only until the next successful sync |
| N2 | Data survives app restarts | Met via `shared_preferences` (cache) and Supabase (source of truth for synced data) |
| N3 | Data survives reinstall / device change | Met for data that synced to Supabase (posts, comments, listings, conversations, follows-I-make); **not met** for anything that only ever lived locally (cart, purchases — see `out-of-scope.md`) |
| N4 | Scalable multi-user backend | Met — Supabase-managed Postgres with RLS; no bespoke API server of our own |
| N5 | Cross-platform (Android/iOS at minimum) | Met — Flutter targets both |
| N6 | Accessibility (screen readers, contrast, text scaling) | Not verified |
| N7 | Automated test coverage | 164 tests as of 2026-07-27 (unit, widget, and a cross-route overflow-regression suite at two narrow screen sizes) — see `mobile-app/test/` |

## Assumptions

- Single logical "current user" per device (no multi-account switching).
- Mock data (`mockUsers`, `mockPosts`, `mockListings`, `mockComments`,
  `mockBooks`) still seeds first launch and backs the parts of the app with
  no real backend counterpart (Earnings/tips, the Followers list, cart) —
  everything else now loads from Supabase once `loadFromSupabase()` resolves.

## Dependencies

- Flutter SDK ^3.10.7 and the packages listed in
  [`../mobile-app/README.md`](../mobile-app/README.md).
