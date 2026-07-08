# Out of Scope

Explicitly **not** part of the current build. Listed so future work doesn't
assume any of this silently exists.

## Backend / Infrastructure
- No API server of any kind (see [`../web-app`](../web-app))
- No real database (see [`database.md`](database.md))
- No authentication/authorization (no login, no sessions, no password
  handling, no OAuth)
- No cross-device or cross-account data sync
- No cloud file storage for uploaded covers/PDFs/audio (files picked via
  `file_picker` are read locally and never uploaded anywhere)

## Commerce
- No real payment processing (no Stripe/PayPal/etc. integration) — cart and
  "purchases" are locally stored records only, nothing is actually charged
- No payout mechanism for creator `earnings`
- No order fulfillment for physical books (shipping, tracking, inventory)
- No refunds/disputes handling

## Trust & Safety
- No content moderation (automated or manual)
- No reporting/flagging of posts, users, or listings
- No blocking/muting of users
- No spam/abuse detection

## Notifications & Messaging
- No push notifications (alerts screen shows local/mock data only)
- No real-time messaging transport (no websockets, no message delivery
  guarantees) — conversation screens exist but aren't backed by a live
  channel
- No email notifications

## Platform
- No dedicated web frontend product (Flutter's `web/` build target exists
  but is unmaintained scaffolding, not a shipped experience)
- No admin/back-office tooling
- No analytics/telemetry instrumentation

## Product
- No multi-account support per device
- No internationalization/localization (English only)
- No offline-conflict resolution (not applicable while there's no sync)
- No recommendation/ranking algorithm for the feed (chronological/mock order
  only)

If any of the above becomes in-scope, move it out of this file and into
[`PRD.md`](PRD.md) / [`requirements.md`](requirements.md).
