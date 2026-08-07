import { config } from 'dotenv';
import path from 'node:path';

// Credentials live outside the repo entirely (see README) — this only ever
// reads a path the caller passes in, never a file checked into git.
export function loadEnv() {
  const arg = process.argv.find((a) => a.startsWith('--env-file='));
  const envFile = arg ? arg.slice('--env-file='.length) : process.env.MIGRATION_ENV_FILE;
  if (!envFile) {
    throw new Error(
      'Missing credentials file. Pass --env-file=<path> or set MIGRATION_ENV_FILE, ' +
        'pointing at the local text file with SUPABASE_URL, SUPABASE_SERVICE_KEY, ' +
        'FIREBASE_SERVICE_ACCOUNT_PATH.',
    );
  }
  const resolvedEnvFile = path.resolve(envFile);
  config({ path: resolvedEnvFile });

  const required = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'FIREBASE_SERVICE_ACCOUNT_PATH'];
  const missing = required.filter((k) => !process.env[k]);
  if (missing.length) {
    throw new Error(`Missing required keys in ${resolvedEnvFile}: ${missing.join(', ')}`);
  }

  return {
    envFile: resolvedEnvFile,
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY,
    firebaseServiceAccountPath: path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH),
  };
}

export function isCommit() {
  return process.argv.includes('--commit');
}
