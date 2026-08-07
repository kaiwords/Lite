import { createClient } from '@supabase/supabase-js';

export function supabaseAdmin(url, serviceKey) {
  return createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
