# Out of Scope

Explicitly **not** part of the current build. Listed so future work doesn't
assume any of this silently exists.

## Backend / Infrastructure

> **Updated 2026-07-27**: a real Supabase backend (Postgres + Auth + RLS)
> shipped in July 2026 — see [`database.md`](database.md) for what's
> actually there now. The items below are what's *still* true.

- No dedicated API server (the app talks to Supabase directly — no
  bespoke backend of our own; see [`../web-app`](../web-app))
- No cloud file storage for uploaded covers/PDFs/audio — files picked via
  `file_picker` are read locally and never uploaded anywhere, so feed audio
  still points at demo URLs rather than real user uploads
- No real-time transport — data is fetched once per provider init, not
  pushed live; a second device/session needs a refresh/relaunch to see new
  data
- No account recovery flow (password reset, etc.) beyond basic
  email/password sign-in and sign-up

## Commerce
- No real payment processing (no Stripe/PayPal/etc. integration) — cart and
  "purchases" are locally stored records only, nothing is actually charged
- No tipping/earnings system of any kind — `earnings_screen.dart`'s totals
  and tip history are entirely generated mock data, not a real balance;
  there is no payout mechanism because there is nothing real to pay out
- No order fulfillment for physical books (shipping, tracking, inventory)
- No refunds/disputes handling

## Trust & Safety
- No content moderation (automated or manual)
- No reporting/flagging of posts, users, or listings
- No blocking/muting of users
- No spam/abuse detection

## Notifications & Messaging
- No push notifications (alerts screen shows local/mock data only)
- No live/real-time delivery for messages — conversations and messages are
  now persisted in Supabase (not just local mocks), but a peer's new
  message only appears after a refresh/relaunch, not pushed live
- No email notifications

## Platform
- No dedicated web frontend product (Flutter's `web/` build target exists
  but is unmaintained scaffolding, not a shipped experience)
- No admin/back-office tooling
- No analytics/telemetry instrumentation

## Product
- No multi-account support per device
- No internationalization/localization (English only)
- No offline-conflict resolution — a write made while offline is retried
  once (and now tells the user if it fails, see `sync_feedback.dart`), but
  there's no merge/reconciliation logic if the same record changed on the
  server in the meantime
- No recommendation/ranking algorithm for the feed (chronological/mock order
  only)

If any of the above becomes in-scope, move it out of this file and into
[`PRD.md`](PRD.md) / [`requirements.md`](requirements.md).
