# Mobile App

**Status: Active. This is the only implemented part of the product.**

"Literature" is a Flutter mobile app — a social platform for writers and
readers combining a social feed, an audio/audiobook player, an in-app book
reader, and a marketplace for buying/selling books, e-books, and audiobooks.

The Flutter project lives entirely in this folder (`lib/`, `android/`,
`ios/`, `web/`, `windows/`, `macos/`, `linux/`, `pubspec.yaml`, etc.) — run
all `flutter` commands from inside `mobile-app/`.

## Stack

| Concern | Package / tool |
|---|---|
| Framework | Flutter (Dart SDK ^3.10.7) |
| State management | `flutter_riverpod` + `riverpod_annotation` (codegen via `riverpod_generator` / `build_runner`) |
| Routing | `go_router` |
| Fonts | `google_fonts` |
| Animations | `flutter_animate` |
| File selection | `file_picker` (picking cover images, PDFs, audio files for uploads) |
| Local persistence | `shared_preferences`, see "Backend / data layer" below |
| Relative timestamps | `timeago` |
| Linting | `flutter_lints` |
| Icons | `cupertino_icons` |

## Platforms

Configured build targets: Android, iOS, Web, Windows, macOS, Linux (standard
Flutter multi-platform scaffolding). Primary target is mobile (Android/iOS);
the `web/`, `windows/`, `macos/`, `linux/` folders here are Flutter's default
scaffolding and are **not** the planned dedicated web app — see
[`../web-app`](../web-app) for that.

## Architecture

- `lib/models/` — plain Dart data classes + `mockX` seed data (`Post`, `LitUser`,
  `MarketplaceListing`, `Comment`, `Book`)
- `lib/providers/` — Riverpod providers/notifiers (feed, marketplace, auth,
  audio, comments, follow, settings, theme, navigation)
- `lib/screens/` — one folder per feature area (home, audio, marketplace,
  messages, alerts, profile, settings, search, post, reader, viewer)
- `lib/widgets/` — shared UI components (cards, sheets, bars, badges)
- `lib/services/local_store.dart` — local persistence layer
- `lib/router/app_router.dart` — `go_router` route table
- `lib/theme/app_theme.dart` — theming

## Key features implemented

- Social feed of posts across content categories (poem, story, novel, essay,
  article, joke, haiku, biography, script, lyrics, book) with like/comment/
  share/favourite
- Audio posts + a standalone audiobook player
- In-app paginated book reader (cover, title page, intro, chapters, glossary,
  references, back cover)
- Marketplace: physical books, e-books, audiobooks; listing detail, cart,
  purchases, "my listings" (sell flow), marketplace hub, marketplace-specific
  notifications and messages
- Follows, user profiles, direct messages/conversations
- Search, alerts/notifications, settings (theme mode), full-screen post
  viewer

For full product intent see [`../docs/PRD.md`](../docs/PRD.md) and
[`../docs/requirements.md`](../docs/requirements.md).

## Backend / data layer

The app talks to a real backend: a Supabase-managed Postgres project
(RLS-enabled), with real email/password auth. Data flows through three
layers:

1. **Seeded mock data** hard-coded in `lib/models/*.dart` (`mockUsers`,
   `mockPosts`, `mockListings`, `mockComments`, `mockBooks`) — used to render
   instantly on first launch and as a fallback for the pieces that still
   have no real backend counterpart (Earnings/tips, the Followers list, cart).
2. **User-mutable state persisted locally** via `lib/services/local_store.dart`
   (the `LocalStore` singleton), backed by the `shared_preferences` package —
   an instant local cache, not the source of truth for synced data.
3. **`lib/services/*_repository.dart`** — one per domain (posts, comments,
   conversations, follows, marketplace, users), each reading/writing the
   Supabase tables directly. Every provider seeds from (1)/(2) immediately,
   then calls `loadFromSupabase()` to replace it with live data once it
   arrives; writes apply locally first and sync in the background, surfacing
   a "couldn't sync" message if the write fails.

Still true: no cloud file storage (uploaded audio/PDFs/covers are read
locally, never uploaded), no real-time/live delivery (each screen fetches
once, not pushed), no real payments. See
[`../docs/database.md`](../docs/database.md) for the full picture of what's
real vs. still mocked, and [`../docs/out-of-scope.md`](../docs/out-of-scope.md)
for what's deliberately not built. The future web app, if built, would share
this same backend rather than getting its own.
