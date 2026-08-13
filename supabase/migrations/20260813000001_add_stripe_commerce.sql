-- Applied to project iakggzyqbamynwxdfxxz on 2026-08-13 via MCP.
-- Adds the real commerce backend behind Stripe Connect: canonical integer
-- pricing, a per-user Stripe identity table (buyer Customer + seller
-- Connect account), and orders/order_items to replace the local-only
-- Purchase/Sale state in marketplace_account_provider.dart. See
-- docs/database.md for the "Earnings/tips ... no payment system exists at
-- all" gap this closes, and CLAUDE.md for the swagger.yaml sync rule.

-- ── Canonical price in cents ────────────────────────────────────────────
-- `price` stays as-is (display string, e.g. "$12.99") for existing UI code;
-- `price_cents` becomes the source of truth for anything that touches
-- money (Stripe amounts must be integers in the smallest currency unit).
-- Backfilled by parsing the existing display string; new listings write
-- both going forward (see list_item_sheet.dart).
alter table public.marketplace_listings
  add column if not exists price_cents integer not null default 0;

update public.marketplace_listings
set price_cents = round(
  coalesce(nullif(regexp_replace(price, '[^0-9.]', '', 'g'), '')::numeric, 0) * 100
)::integer
where price_cents = 0;

-- ── Per-user Stripe identity ────────────────────────────────────────────
-- One row per user, populated lazily and server-side only (checkout
-- creates the buyer's stripe_customer_id; onboarding creates the seller's
-- stripe_connect_account_id). Deliberately not columns on public.users:
-- users' "own row update" RLS policy lets a signed-in user PATCH their own
-- row directly, which would let a client forge charges_enabled=true or
-- overwrite another flow's Stripe IDs. Splitting these into their own
-- table with no client write policy at all (service-role-only, same as
-- how public.users rows are "provisioned on signup" with no insert
-- policy) closes that off.
create table if not exists public.user_stripe_accounts (
  user_id text primary key references public.users(id),
  stripe_customer_id text,
  stripe_connect_account_id text,
  charges_enabled boolean not null default false,
  details_submitted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_stripe_accounts enable row level security;

create policy "own stripe account select" on public.user_stripe_accounts
  for select using (user_id = (auth.uid())::text);

-- ── Orders / order items ────────────────────────────────────────────────
-- Server-created only (the create-checkout Edge Function uses the service
-- role key, which bypasses RLS) so the authoritative price and seller
-- always come from the DB, never from client-submitted amounts. Clients
-- only ever read their own rows.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id text not null references public.users(id),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'refunded')),
  stripe_payment_intent_id text unique,
  amount_total_cents integer not null,
  currency text not null default 'usd',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders enable row level security;

create policy "own orders select" on public.orders
  for select using (buyer_id = (auth.uid())::text);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  listing_id text not null references public.marketplace_listings(id),
  -- Snapshot of the listing's seller/price at purchase time — protects
  -- order history if the listing is later edited, deleted, or re-listed.
  seller_id text not null references public.users(id),
  unit_price_cents integer not null,
  platform_fee_cents integer not null default 0,
  stripe_transfer_id text,
  transfer_status text not null default 'pending'
    check (transfer_status in ('pending', 'transferred', 'failed')),
  created_at timestamptz not null default now()
);

alter table public.order_items enable row level security;

create policy "buyer or seller select" on public.order_items
  for select using (
    seller_id = (auth.uid())::text
    or exists (
      select 1 from public.orders o
      where o.id = order_id and o.buyer_id = (auth.uid())::text
    )
  );

create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists order_items_seller_id_idx on public.order_items(seller_id);
