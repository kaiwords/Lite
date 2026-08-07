import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';

// Persisted next to the credentials file (outside the repo) so re-runs and
// later phases don't recreate Supabase Auth users that already exist.
function mapPath(envFile) {
  return path.join(path.dirname(envFile), 'uid-map.json');
}

export function loadUidMap(envFile) {
  const file = mapPath(envFile);
  if (!existsSync(file)) return {};
  return JSON.parse(readFileSync(file, 'utf8'));
}

export function saveUidMap(envFile, map) {
  writeFileSync(mapPath(envFile), JSON.stringify(map, null, 2));
}
