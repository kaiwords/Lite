# Business Requirements Document (BRD) — Literature

> Reverse-documented from the current codebase (no prior BRD existed). Update
> this as real business decisions are made — right now it reflects what the
> app implies about the intended business, not a signed-off strategy.

## 1. Business Problem

Writers (poets, novelists, essayists, short-story authors) lack a single
platform that combines social discovery (an audience that reads and reacts
to their work) with direct monetization (selling books, e-books, and
audiobooks to that same audience).

## 2. Business Objective

Build a social-first literature platform where:

- Readers discover written and audio content through a social feed.
- Writers build a following and earn money by selling their work directly
  (physical books, e-books, audiobooks) inside the same app.
- The app captures both the "content consumption" loop (feed, reading,
  listening) and the "commerce" loop (marketplace, purchases) in one product.

## 3. Stakeholders

| Role | Interest |
|---|---|
| Writers / creators | Audience growth, earnings (see `LitUser.earnings`) |
| Readers / listeners | Discovery, reading/listening experience |
| Platform owner | Marketplace transaction volume, engagement |

## 4. Success Indicators (candidates — not yet instrumented)

- Posts created / read / liked / shared per user
- Marketplace listings created and sold
- Follower growth per creator
- Retention of readers returning to the feed

## 5. Constraints

- Single-developer / early-stage project; real backend and real accounts
  now exist (Supabase, since 2026-07), but still no payment processor and
  no content moderation (see [`out-of-scope.md`](out-of-scope.md)).
- Must work as a mobile-first experience; web is aspirational, not committed.

## 6. Related documents

- [PRD.md](PRD.md) — product-level detail
- [requirements.md](requirements.md) — functional/non-functional requirements
- [out-of-scope.md](out-of-scope.md)
- [database.md](database.md)
