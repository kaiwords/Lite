# Tasks Completed

> Git history for this repo currently has a single squashed "first commit",
> so this log is reconstructed from the current state of the codebase rather
> than from commit-by-commit history. Add new entries as dated bullet points
> going forward so this stays accurate.

## Baseline build (as of 2026-07-08, from initial commit)

**App scaffolding**
- Flutter project set up (`literature`, Dart SDK ^3.10.7) targeting Android,
  iOS, Web, Windows, macOS, Linux
- Riverpod (+ codegen), go_router, google_fonts, flutter_animate, file_picker,
  shared_preferences wired in as the core dependency set

**Data layer**
- Domain models built: `LitUser`, `Post` (+ `ContentCategory`, 12 values),
  `MarketplaceListing` (+ `ListingType`, `Genre`), `Comment`, `Book` (+
  `BookPage`/`BookPageType`)
- Mock/seed datasets for each model (`mockUsers`, `mockPosts`, `mockListings`,
  `mockComments`, `mockBooks`)
- `LocalStore` local persistence layer over `shared_preferences` covering
  posts, cart, purchases, my-listings, comments, current user, theme mode,
  follows, visible categories

**Feed & content**
- Home feed screen with category chips/filter row/bottom sheet
- Post card, audio post card, marketplace badge/audio-marketplace badge on
  posts
- Full-screen post viewer
- Comments sheet with per-comment like
- Post creation screen (text and audio-first flows)

**Audio & reading**
- Audio tab/screen
- Standalone audiobook player screen
- In-app paginated book reader (cover/title/intro/chapters/glossary/
  references/back cover) reachable from a post via `bookId`

**Marketplace**
- Marketplace screen, marketplace hub, listing detail screen
- Marketplace filter bar/sheet, marketplace listing card
- Marketplace-specific notifications and messages screens
- Cart, purchases, and "my listings" (sell flow) via `LocalStore`

**Social**
- Follow/unfollow (`follow_provider`)
- Own profile screen + edit-profile sheet, other users' profile screen
  (`/user/:userId`)
- Messages list + 1:1 conversation screen

**Other**
- Search screen
- Alerts/notifications screen
- Settings screen with theme mode (system/light/dark), persisted
- Bottom nav bar, app bar, generic action sheet, share sheet
- Full `go_router` route table (`lib/router/app_router.dart`) wiring all of
  the above together

**Documentation (2026-07-08)**
- Added `docs/` with `BRD.md`, `PRD.md`, `requirements.md`,
  `out-of-scope.md`, `database.md`, and this file
- Decided on Supabase (Postgres) over Firebase for the future backend,
  given the relational marketplace/social data model
- Added five project-scoped Claude Code subagents under `.claude/agents/`
  (Mobile App Builder, Database Optimizer, Code Reviewer, Application
  Security Engineer, Accessibility Auditor) to complement the
  Downloads-level agent set already covering Backend Architect, Frontend
  Developer, UX Architect, Sprint Prioritizer, etc.

**Repo restructure (2026-07-08)**
- Moved the entire Flutter project (`lib/`, `android/`, `ios/`, `web/`,
  `windows/`, `macos/`, `linux/`, `pubspec.yaml`, `.idea/`, `literature.iml`,
  etc.) into `mobile-app/`; created an empty `web-app/` placeholder for the
  future web client
- Discovered the git repo was accidentally rooted at the home directory
  (`C:/Users/shres`) with an unrelated remote (`kaiwords/Javascript.git`);
  removed that `.git` and initialized a fresh repo scoped to this project
  folder instead

---

## Log

Add new entries below, newest first, dated `YYYY-MM-DD`.
