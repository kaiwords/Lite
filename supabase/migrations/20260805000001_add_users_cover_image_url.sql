-- Applied to project iakggzyqbamynwxdfxxz on 2026-08-05 via MCP.
-- Lets users set a cover photo (in addition to the existing avatar_url),
-- edited from the profile screen. RLS already covers this: "own row
-- update" on public.users has no column restriction, so no policy change
-- is needed.

alter table public.users
  add column if not exists cover_image_url text;
