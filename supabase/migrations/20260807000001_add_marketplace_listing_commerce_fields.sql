-- Applied to project iakggzyqbamynwxdfxxz on 2026-08-07 via MCP.
-- Adds columns needed to carry over real commerce data (cover image, stock,
-- timestamps) from the legacy Firebase migration -- see
-- scripts/firebase-migration/. RLS already covers these: existing "own row"
-- policies on marketplace_listings key off seller_id, unaffected by adding
-- nullable/defaulted columns.

alter table public.marketplace_listings
  add column if not exists cover_image_url text,
  add column if not exists qty integer,
  add column if not exists is_sold_out boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();
