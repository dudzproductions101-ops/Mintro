import { createClient } from '@supabase/supabase-js';
import { env } from './env.js';

/**
 * Server-side Supabase client using the SERVICE ROLE key.
 *
 * This client bypasses Row Level Security entirely. It must NEVER be
 * exposed to the Flutter app — it exists only inside this API so that
 * privileged operations (awarding XP/coins, completing lessons, claiming
 * quests, league rotation) can be enforced server-side regardless of RLS.
 */
export const supabaseAdmin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});
