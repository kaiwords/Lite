-- Adds book-metadata fields to marketplace_listings for the "List a Book"
-- sheet: description was already a column, but ISBN/publisher/publication
-- date (Physical + E-Book listings) and condition/edition (Physical
-- listings only) are new. "Quantity available" reuses the pre-existing
-- (legacy, previously never read/written) qty column instead of adding a
-- duplicate. All nullable — existing rows and Audio-only listings simply
-- leave them unset. RLS already covers this: "own row insert/update" on
-- public.marketplace_listings has no column restriction, so no policy
-- change is needed.

alter table public.marketplace_listings
  add column if not exists isbn text,
  add column if not exists publisher text,
  add column if not exists publication_date date,
  add column if not exists condition text,
  add column if not exists edition text;
