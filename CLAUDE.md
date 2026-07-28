# Project instructions — Literature

## Keep `docs/swagger.yaml` in sync with the backend

`docs/swagger.yaml` documents the real, live Supabase backend surface:
one CRUD path per `public` table (matching `mobile-app/lib/services/
*_repository.dart`) plus the Supabase Auth endpoints, generated from the
actual live schema (`information_schema.columns` / `pg_policies`) rather
than hand-guessed.

**Whenever the backend's API surface changes, update `docs/swagger.yaml` in
the same piece of work** — don't let it drift the way `docs/database.md`,
`docs/out-of-scope.md`, `docs/PRD.md`, `docs/requirements.md`, and both
READMEs all did after the original Supabase migration shipped without a
docs update (fixed 2026-07-27, see `docs/tasks-completed.md`). Concretely,
update it when:

- A new table, column, or RLS policy is added or changed in
  `supabase/migrations/` (or applied directly to the project) — re-query
  `information_schema.columns` and `pg_policies` for the affected table(s)
  rather than guessing at the shape.
- A new `services/*_repository.dart` method is added that calls a
  Supabase table/RPC/Edge Function not already documented.
- A Supabase Edge Function is added (none exist yet — `swagger.yaml`'s
  Auth/table paths are the entire current backend surface).

If a schema change is significant, also check whether
`docs/database.md`'s "What's real vs. still mocked" section needs
updating alongside it.
