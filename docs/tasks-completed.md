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
- Added project-scoped Claude Code subagents under `.claude/agents/`
  (Mobile App Builder, Database Optimizer, Code Reviewer, Application
  Security Engineer, Accessibility Auditor, UI/UX Designer) to complement
  the Downloads-level agent set already covering Backend Architect,
  Frontend Developer, UX Architect, Sprint Prioritizer, etc.

**Repo restructure (2026-07-08)**
- Moved the entire Flutter project (`lib/`, `android/`, `ios/`, `web/`,
  `windows/`, `macos/`, `linux/`, `pubspec.yaml`, `.idea/`, `literature.iml`,
  etc.) into `mobile-app/`; created an empty `web-app/` placeholder for the
  future web client
- Discovered the git repo was accidentally rooted at the home directory
  (`C:/Users/shres`) with an unrelated remote (`kaiwords/Javascript.git`);
  removed that `.git` and initialized a fresh repo scoped to this project
  folder instead

**Code review + critical bug fixes (2026-07-08)**
- Ran Code Reviewer / mobile product / UX Architect analyses of `mobile-app`;
  fixed the highest-severity findings:
  - `test/widget_test.dart` never called `LocalStore.init()` and crashed on
    the first `flutter test` run — fixed
  - Marketplace sell flow wrote to "My Listings" but Browse/Search filtered
    the seeded `mockListings` directly, so user-created listings were never
    discoverable — `marketplaceListingsProvider` now merges seeded +
    user-created listings; `marketplace_screen.dart` consumes it
  - Settings toggles (`settings_provider.dart`) used plain `StateProvider`s
    with no persistence — now persisted via `LocalStore` (bool blob +
    dedicated keys for `DmPermission`/`FontSizePref`), same load-then-listen
    pattern as theme/follows
  - Conversations were keyed by display-name string (collision- and
    rename-prone) — routing and `_mockThreads` now key by `LitUser.id`
    (`findUser()` added to `models/user.dart`); the two demo-only peers with
    no backing `LitUser` keep name-based ids
- Deferred (flagged, not fixed, pending a scope decision): the fake/simulated
  audio player, the unreachable `MarketplaceHubScreen`, duplicate
  marketplace-vs-social messaging stacks, placebo settings (notifications/
  privacy/tipping toggles with no enforcement), and the dead
  `marketplace_filter_bar.dart`/`marketplace_filter_sheet.dart` widgets (kept
  alive since their providers are still referenced, even though the widgets
  themselves are unused)

**Cut candidates resolved + UI/UX polish pass (2026-07-09)**
Worked through every item deferred from the prior review, one agent at a time
(Mobile App Builder for the cuts, UI/UX Designer for polish), verifying
`flutter analyze`/`flutter test` clean after each step:
- Deleted the unreachable `MarketplaceHubScreen` (3,334-line file) and the
  dead `marketplace_filter_bar.dart`/`marketplace_filter_sheet.dart` widgets
  + their now-unused providers; split the still-used tabs/sell-flow into
  `cart_tab.dart`, `library_tab.dart`, `my_listings_tab.dart`,
  `sales_tab.dart`, `marketplace_shared_widgets.dart`, `list_item_sheet.dart`
- Merged the two parallel messaging stacks into one shared
  `Conversation`/`Message` model (`models/conversation.dart`) with an optional
  `contextLabel` for marketplace-originated threads; one chat UI
  (`conversation_screen.dart`) now serves both `/messages/:id` and
  `/marketplace/messages`
- Stripped placebo settings entirely rather than "coming soon" labels (no
  auth/payments/push notifications are actually planned per
  `docs/out-of-scope.md`): removed the fake notification/privacy/tipping
  toggles, font size control, fake Change Password dialog, and fake Sign Out;
  deleted `settings_provider.dart` and its now-orphaned `LocalStore` keys
  entirely. Kept Theme, Edit Profile/Username/Email (genuinely wired), and
  the About section
- Wired up **real** audio playback with `just_audio` (kept all existing
  waveform/equalizer/mini-player UI) — mock posts now point at rotating
  SoundHelix demo URLs instead of fake local paths; added loading/error
  states and Android `INTERNET` permission
- UI/UX fixes: extracted one theme-aware `TipSheet` widget (was duplicated
  4x, hardcoded light-mode colors in dark theme); added an `accentOnFill`/
  `darkAccentOnFill` token pair for WCAG-AA contrast on solid-fill+white-text
  buttons (Follow, Checkout, Publish, etc.); Settings no longer shows the
  bottom nav bar as a fake 6th tab; engagement buttons (like/comment/share)
  now have ~44×44px tap targets; not-yet-available marketplace actions get a
  muted "SOON" badge instead of looking fully functional; wired the
  previously-unused `flutter_animate` dependency into a feed entrance stagger

---

## Log

**Buy-from-post, chapter/track uploads, responsive fixes (2026-07-12)**
- **Buy from post, not just cart**: extracted purchase-completion into
  `PurchasesNotifier.buyNow(listing)` (`marketplace_account_provider.dart`) so
  cart checkout, a new "Buy Now" button on `listing_detail_screen.dart`, and
  a new `listing_buy_sheet.dart` all share one code path. Tapping a post's
  marketplace badge (`marketplace_badge.dart`/`audio_marketplace_badge.dart`)
  now opens a buy sheet (cover/title/price + Buy Now/View Listing) instead of
  only deep-linking to the listing
- **Chapter-by-chapter ebook upload**: `MarketplaceListing` gained
  `List<EbookChapter>` (title + content), backward-compatible with the
  legacy flat `ebookContent` string. Sell flow's "Write online" path now
  builds a book via a chapter list editor (add/reorder/edit/remove,
  `_ChapterListScreen` in `list_item_sheet.dart`); reading a chapter-based
  listing reuses the existing `BookReaderScreen`/`Book`/`BookPage` pagination
  (via a transient `Book` built at read-time) instead of a new one-off UI
- **Track-by-track audiobook upload**: `audioVolumes` changed from
  `List<String>` to `List<AudioVolume>` (title + filename), migrating old
  string-list local/mock data automatically. Sellers can now name each
  track; `audiobook_player_screen.dart` shows real track titles instead of
  "Volume N"
- **Responsive/overflow fixes**: added `test/overflow_test.dart` — pumps
  every route plus key sheets/editors at 320×568 and 360×690 (63 tests) and
  fails on any `RenderFlex` overflow, kept as a permanent regression suite.
  Found and root-cause-fixed 11 genuine overflow bugs (missing
  `Expanded`/`Flexible` on Row children, a fixed-height audio card that
  didn't fit short screens, `childAspectRatio` grids that don't hold up
  across widths, fixed-width tip-sheet chips, etc.) plus 2 unrelated crash
  bugs the same testing surfaced (a `dispose()` using a detached `ref`, and
  `crossAxisAlignment.stretch` inside a `ListView` causing infinite-height
  constraints once a list actually had items)

**Migrate to Supabase: real auth, data-layer repositories, RLS (2026-07-27)**
- **Real authentication**: new `screens/auth/login_screen.dart` and
  `signup_screen.dart`, `auth_provider.dart` rewritten around Supabase Auth
  (email/password), `humanizeAuthError` (`utils/auth_error.dart`) rewrites
  raw Supabase error strings into readable copy. `app.dart` listens to the
  Supabase auth-state stream and syncs `currentUserProvider` from the
  `public.users` row on sign-in/out; `app_router.dart`'s redirect logic
  bridges the same stream into a `Listenable` to bounce signed-out users to
  `/login`
- **LocalStore mocks replaced with Supabase repositories**: new
  `services/{posts,comments,conversations,follows,marketplace,users}_repository.dart`.
  `feed_provider.dart`, `comments_provider.dart`, `follow_provider.dart`,
  `marketplace_provider.dart`, and `marketplace_account_provider.dart` now
  seed from the local mocks and then call `loadFromSupabase()` to replace
  them with live data once it arrives, writing through to the matching
  repository on create/update (failures are currently swallowed rather than
  surfaced to the user — flagged for a follow-up). `LitUser.fromSupabaseRow`
  added alongside the existing `fromJson` to map snake_case Postgres rows
  New `models/conversation.dart` + `providers/conversations_provider.dart`
  give messaging its own Supabase-backed model instead of local mock threads
- **Database**: `supabase/migrations/` adds ownership-scoped RLS policies for
  the marketplace and messaging tables; `.env`-based config
  (`SUPABASE_URL`/`SUPABASE_ANON_KEY`, see `.env.example`) loaded via
  `flutter_dotenv` and read by the new `services/supabase_service.dart`
- **Tests**: added `test/unit/models_test.dart` (`fromSupabaseRow` mapping,
  JSON round-trips), `test/unit/auth_error_and_book_test.dart`
  (`humanizeAuthError`), `test/unit/notifiers_test.dart` (provider behavior
  against the Supabase-backed notifiers, including offline-fallback when
  `loadFromSupabase` fails), `test/widget/login_screen_test.dart`, plus
  standalone coverage for the previously-untested `post_paginator.dart` and
  `rich_text.dart` utilities
- Deferred (flagged, not fixed): repository write failures in the
  provider `add`/`update` paths are caught and dropped instead of shown to
  the user (see `notifiers_test.dart` comment referencing "review finding
  H6")

Add new entries below, newest first, dated `YYYY-MM-DD`.
