-- Meetup now asks for a contact phone number too, same as Pickup already
-- does — required in the List a Book sheet when 'meetup' is checked in
-- shipping_methods. Shown to buyers only once they own the listing (or
-- it's their own), same gating as pickup_phone. RLS already covers this:
-- "own row insert/update" on public.marketplace_listings has no column
-- restriction, so no policy change is needed.

alter table public.marketplace_listings
  add column if not exists meetup_phone text;
