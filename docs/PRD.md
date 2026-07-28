# Product Requirements Document (PRD) — Literature

> Reverse-documented from the current codebase (no prior PRD existed). This
> describes what is actually built today, plus the gaps that a real PRD
> would need to close. Treat "Implemented" sections as ground truth and
> everything else as proposed/future.

## 1. Product Summary

Literature is a mobile app combining a social feed for written/audio
literary content with a marketplace for buying and selling books, e-books,
and audiobooks, plus an in-app book reader and audiobook player.

## 2. Target Users

- **Writers/creators** — post poems, stories, essays, jokes, novels, etc.,
  optionally as audio, and optionally sell longer works via the marketplace.
- **Readers/listeners** — browse a feed, follow creators, read/listen to
  content, buy books.

## 3. Implemented Features

### 3.1 Social Feed
- Feed of `Post`s across 12 content categories (poem, book, joke, novel,
  article, story, essay, haiku, biography, short story, script, lyrics)
- Like, comment, share, favourite actions
- Category filter chips / bottom sheet, feed filter row
- Full-screen post viewer
- Comments sheet with per-comment like

### 3.2 Audio
- Posts can carry an `audioUrl`
- Dedicated audio tab/screen and a standalone audiobook player screen

### 3.3 Book Reader
- Paginated in-app reader: cover → title page → introduction (roman
  numerals) → chapters (arabic numerals) → glossary → references → back
  cover
- A post can link to a `Book` (`bookId`) opened via `/reader/:id`

### 3.4 Marketplace
- Listings of three types: physical, e-book, audio — each with price,
  rating, review count, genre (12 genres), linked content category, and an
  optional link back to the originating post
- E-book source: uploaded PDF (`pdfFileName`) or in-app written content
  (`ebookContent`) — mutually exclusive
- Audiobook source: one or more uploaded audio files (`audioVolumes`, for
  multi-volume audiobooks)
- Marketplace hub, listing detail screen, cart, purchase history, "my
  listings" (sell flow), marketplace-specific notifications and messages
- Filter bar / filter sheet, marketplace badges on posts

### 3.5 Social graph & profile
- Follow/unfollow (real, synced to Supabase), followers/following counts
- User profile (own + other users' via `/user/:userId`)
- Editable profile (display name, bio) via edit-profile sheet
- Followers, Following, and Earned each open a dedicated full screen from
  the profile stats row (`/profile/followers`, `/profile/following`,
  `/profile/earnings`); the followers/following screen has search
- Per-creator `earnings` field — **display only, not real**: the Earnings
  screen's totals and tip history are generated mock data, see §4

### 3.6 Messaging
- Conversation list and 1:1 conversation screen (`/messages`,
  `/messages/:name`), now persisted to Supabase (not just local mocks) —
  but not live: a peer's message only shows up after a refresh/relaunch
- Separate marketplace messages screen for buyer/seller communication

### 3.7 Accounts
- Real email/password authentication via Supabase Auth (`/login`,
  `/signup`), session persistence, router-level redirect for signed-out
  users
- Real backend (Supabase Postgres, RLS-enabled) backs posts, comments,
  marketplace listings, conversations/messages, and follows — see
  [`database.md`](database.md) for what's real vs. still mocked

### 3.8 Other
- Search screen
- Alerts/notifications screen (+ marketplace-specific notifications)
- Settings screen (theme mode: system/light/dark, persisted)
- Bottom navigation, app bar, action sheets, share sheet

## 4. Explicitly Not Yet Implemented

See [out-of-scope.md](out-of-scope.md) for the full list — most importantly:
no payments/payouts, no push notifications, no content moderation/reporting,
no cloud file storage (uploaded audio/PDFs/covers aren't actually uploaded
anywhere), no live/real-time data delivery. Real backend, real
authentication, and real cross-device sync *do* now exist (Supabase,
shipped 2026-07) — see [database.md](database.md).

## 5. Non-Goals

See [out-of-scope.md](out-of-scope.md).

## 6. Open Product Questions

- Is web a real target or mobile-only for the foreseeable future?
- What's the monetization model for the platform itself (take-rate on
  marketplace sales? subscriptions?) — not modeled anywhere in the code yet.
- Is content moderation/reporting required before any public launch? —
  more pressing now than when this question was first written: posts,
  comments, listings, and messages are real, persisted, multi-user data in
  Supabase, not just on-device mocks.
