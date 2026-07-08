# Web App

**Status: Not started.** Planned for the future — no code lives here yet.

No dedicated web app exists in this repo. The Flutter app in
[`mobile-app`](../mobile-app) is technically capable of compiling to web via
`flutter build web` (the `web/` directory inside `mobile-app/` is Flutter's
own web build target, not a separate application), but no one has built or
shipped a browser-facing experience.

## Plan

- **Backend: Supabase** (see [`../docs/database.md`](../docs/database.md)) —
  chosen over Firebase because the data model (users, posts, comments,
  marketplace listings, purchases, follows) is genuinely relational and
  benefits from real joins/constraints, and a single Postgres schema can
  serve both this web app and the Flutter mobile app identically.
- One Supabase project per environment (dev/prod), with both the mobile and
  web clients registered against the same project so auth/users/data are
  shared — not a project per platform.

## Options still open

- **Ship the existing Flutter codebase to web** — fastest path, reuses all
  screens/providers/models as-is, but Flutter-for-web has known trade-offs
  (bundle size, SEO, text selection/accessibility quirks).
- **Dedicated web app** (e.g. Next.js/React) — better for SEO, marketing
  pages, and web-native UX, but means re-implementing the UI layer and
  duplicating business logic that currently lives only in the Flutter app.

## Stack

_Not decided yet beyond the backend choice above — no code in this folder._
