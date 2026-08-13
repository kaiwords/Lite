-- Adds cover_color to marketplace_listings for the new "Cover" step in the
-- List a Book sheet: a designed cover's accent color (ARGB int), used to
-- render the book-reader cover page and listing tiles when the seller
-- didn't pick a photo. (cover_image_url already exists as of
-- 20260807000001 and is now actually written to, via that same step, for
-- the first time.) Both null falls back to the existing genre-derived
-- color. RLS already covers this: "own row insert/update" on
-- public.marketplace_listings has no column restriction, so no policy
-- change is needed.

alter table public.marketplace_listings
  add column if not exists cover_color integer;
