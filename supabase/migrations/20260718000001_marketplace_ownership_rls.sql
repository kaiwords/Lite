-- Applied to project iakggzyqbamynwxdfxxz on 2026-07-18 via MCP.
-- Marketplace ownership: server-stamped seller identity + owner-scoped writes.
-- seller_id defaults to auth.uid() so the client never has to (and never can)
-- choose its own identity. Existing seed rows keep NULL seller_id: publicly
-- readable, editable by no one.

alter table public.marketplace_listings
  add column if not exists seller_id text
    default (auth.uid())::text
    references public.users(id);

drop policy if exists "public write" on public.marketplace_listings;

create policy "own listings insert" on public.marketplace_listings
  for insert with check (seller_id = (auth.uid())::text);
create policy "own listings update" on public.marketplace_listings
  for update using (seller_id = (auth.uid())::text)
  with check (seller_id = (auth.uid())::text);
create policy "own listings delete" on public.marketplace_listings
  for delete using (seller_id = (auth.uid())::text);

-- Child rows (chapters/volumes) are writable only by the parent listing's seller.
drop policy if exists "public write" on public.ebook_chapters;

create policy "own listing chapters write" on public.ebook_chapters
  for all
  using (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_id and l.seller_id = (auth.uid())::text))
  with check (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_id and l.seller_id = (auth.uid())::text));

drop policy if exists "public write" on public.audio_volumes;

create policy "own listing volumes write" on public.audio_volumes
  for all
  using (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_id and l.seller_id = (auth.uid())::text))
  with check (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_id and l.seller_id = (auth.uid())::text));
