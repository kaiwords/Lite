-- Adds shipping/fulfillment support for Physical listings:
--   - marketplace_listings.shipping_methods: which of Pickup/Delivery/Meetup
--     the seller supports, set in the List a Book sheet. Empty means the
--     listing predates this field.
--   - order_items.shipping_method/meetup_place/meetup_confirmed: the
--     buyer's choice at checkout (validated server-side in
--     stripe-create-checkout) and, for Meetup, the seller's confirmation of
--     the buyer's suggested place/time (flipped by supabase/functions/
--     confirm-meetup, from the Sales tab).
-- RLS already covers marketplace_listings ("own row insert/update" has no
-- column restriction). order_items has no direct write policy for
-- authenticated users — all writes to it go through Edge Functions using
-- the service role, so no policy change is needed there either.

alter table public.marketplace_listings
  add column if not exists shipping_methods text[] not null default '{}';

alter table public.order_items
  add column if not exists shipping_method text,
  add column if not exists meetup_place text,
  add column if not exists meetup_confirmed boolean not null default false;
