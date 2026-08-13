-- Seller-entered details for two of the three shipping_methods (added
-- earlier the same day, see 20260813120001_add_shipping_methods.sql):
-- Delivery needs nothing extra, but Pickup needs where/how to reach the
-- seller, and Meetup needs a general meeting area. Collected in the List a
-- Book sheet, required (client-side) whenever the corresponding method is
-- checked. RLS already covers this: "own row insert/update" on
-- public.marketplace_listings has no column restriction, so no policy
-- change is needed.

alter table public.marketplace_listings
  add column if not exists pickup_location text,
  add column if not exists pickup_phone text,
  add column if not exists meetup_location text;
