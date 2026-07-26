-- Applied to project iakggzyqbamynwxdfxxz on 2026-07-18 via MCP.
-- Messaging privacy: conversations/messages were world-readable and
-- world-writable ("public read" + "public write" USING(true)). Scope both to
-- the conversation owner, with identity stamped server-side via defaults.
-- Existing seed rows (NULL owner_id) become invisible to clients.

alter table public.conversations
  add column if not exists owner_id text
    default (auth.uid())::text
    references public.users(id);

drop policy if exists "public read" on public.conversations;
drop policy if exists "public write" on public.conversations;

create policy "own conversations select" on public.conversations
  for select using (owner_id = (auth.uid())::text);
create policy "own conversations insert" on public.conversations
  for insert with check (owner_id = (auth.uid())::text);
create policy "own conversations update" on public.conversations
  for update using (owner_id = (auth.uid())::text)
  with check (owner_id = (auth.uid())::text);
create policy "own conversations delete" on public.conversations
  for delete using (owner_id = (auth.uid())::text);

alter table public.messages
  add column if not exists sender_id text
    default (auth.uid())::text;

drop policy if exists "public read" on public.messages;
drop policy if exists "public write" on public.messages;

create policy "own conversation messages" on public.messages
  for all
  using (exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.owner_id = (auth.uid())::text))
  with check (exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.owner_id = (auth.uid())::text));
