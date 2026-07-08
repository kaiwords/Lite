# Requirements — Literature

> Reverse-documented from the current codebase. "Met" = observably true in
> the code today; everything else is a gap to close before a real launch.

## Functional Requirements

| # | Requirement | Status |
|---|---|---|
| F1 | Users can view a feed of posts across content categories | Met |
| F2 | Users can like, comment on, share, and favourite posts | Met (local only) |
| F3 | Posts can include audio | Met |
| F4 | Users can read full-length books in-app (paginated reader) | Met |
| F5 | Users can browse a marketplace of physical books, e-books, audiobooks | Met |
| F6 | Users can filter marketplace by type/genre/category | Met |
| F7 | Users can add listings to a cart and view purchase history | Met (local only, no real checkout/payment) |
| F8 | Creators can list their own work for sale (sell flow) | Met (local only) |
| F9 | Users can follow/unfollow other users | Met (local only) |
| F10 | Users can view and edit their own profile | Met (local only, single device-bound "current user") |
| F11 | Users can message other users 1:1 | Met (UI only — no real transport, see gaps) |
| F12 | Users can search | Met (UI present — verify against live mock data scope) |
| F13 | Users receive alerts/notifications (incl. marketplace-specific) | Met (UI only, no push, no server-generated events) |
| F14 | Users can switch theme (system/light/dark) | Met, persisted locally |
| F15 | User accounts persist across sessions | Partially met — persists per-device via `shared_preferences`, not per-account server-side |
| F16 | User accounts sync across devices | **Not met** — no backend |
| F17 | Real user authentication (sign up/login) | **Not met** |
| F18 | Real payments for marketplace purchases | **Not met** |
| F19 | Push notifications | **Not met** |
| F20 | Content moderation / reporting | **Not met** |

## Non-Functional Requirements

| # | Requirement | Status |
|---|---|---|
| N1 | App works fully offline (no network dependency) | Met — currently true by construction, since there is no network layer |
| N2 | Data survives app restarts | Met via `shared_preferences` |
| N3 | Data survives reinstall / device change | **Not met** — local-only storage |
| N4 | Scalable multi-user backend | **Not met** — no backend exists |
| N5 | Cross-platform (Android/iOS at minimum) | Met — Flutter targets both |
| N6 | Accessibility (screen readers, contrast, text scaling) | Not verified |
| N7 | Automated test coverage | Minimal — only Flutter's default `test/` scaffold present |

## Assumptions

- Single logical "current user" per device (no multi-account switching).
- Mock data (`mockUsers`, `mockPosts`, `mockListings`, `mockComments`,
  `mockBooks`) stands in for what a real backend would serve.

## Dependencies

- Flutter SDK ^3.10.7 and the packages listed in
  [`../mobile-app/README.md`](../mobile-app/README.md).
