-- Adds the "Free" / "Swap" section to the marketplace (underneath the
-- existing All/Physical/E-Book/Audio format filter): a Physical listing
-- can be offered as a normal Sale, given away for free, or offered as a
-- swap for another book (swap_wanted_for is optional free text — blank
-- means "open to offers"). E-Book/Audio listings stay Sale-only.
--
-- Claiming a Free/Swap listing reuses the pre-existing (legacy,
-- previously-unwritten) is_sold_out column instead of adding a duplicate
-- — see docs/database.md and the claim-listing Edge Function, which is
-- what actually sets it true once someone claims the listing.

alter table public.marketplace_listings
  add column if not exists offer text not null default 'sale',
  add column if not exists swap_wanted_for text;
