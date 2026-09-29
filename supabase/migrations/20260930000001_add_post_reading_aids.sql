-- NOT YET APPLIED to project iakggzyqbamynwxdfxxz — run via `supabase db push`
-- or the dashboard SQL editor.
-- Reading aids the writer can switch on for a post: a tappable contents
-- page in the reader (only meaningful with post_pages rows), and printed
-- page numbers (numbered automatically, 1, 2, 3…). Both default off so
-- existing posts read exactly as before.

alter table public.posts
  add column show_table_of_contents boolean not null default false,
  add column show_page_numbers boolean not null default false;
