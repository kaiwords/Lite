-- Applied to project iakggzyqbamynwxdfxxz on 2026-08-03 via MCP.
-- Multi-page posts: a post can have additional authored pages beyond its
-- main title/content, each with its own optional title (writer decides per
-- page whether to keep showing a title or not). Ownership follows the
-- parent post's author, same pattern as ebook_chapters -> marketplace_listings.

create table public.post_pages (
  id uuid primary key default gen_random_uuid(),
  post_id text not null references public.posts(id) on delete cascade,
  position integer not null,
  title text,
  content text not null
);

create index post_pages_post_id_idx on public.post_pages(post_id);

alter table public.post_pages enable row level security;

create policy "public read" on public.post_pages
  for select using (true);

create policy "own post pages write" on public.post_pages
  for all
  using (exists (
    select 1 from public.posts p
    where p.id = post_id and p.author_id = (auth.uid())::text))
  with check (exists (
    select 1 from public.posts p
    where p.id = post_id and p.author_id = (auth.uid())::text));
