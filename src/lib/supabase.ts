import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  throw new Error(
    'Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY: copia .env.example a .env.local y rellénalo.',
  )
}

// PKCE returns the OAuth code in the query string (?code=...), so it doesn't
// collide with the hash router. supabase-js exchanges it and strips it from the URL.
export const supabase = createClient(url, anonKey, {
  auth: {
    flowType: 'pkce',
    detectSessionInUrl: true,
    persistSession: true,
  },
})

// Where OAuth sends the user back: the app root, whatever BASE_PATH it's served from.
export const appUrl = new URL(import.meta.env.BASE_URL, window.location.origin).href
