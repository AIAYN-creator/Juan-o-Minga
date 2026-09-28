import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

/** Set when the build has no Supabase settings: App shows it instead of a blank page. */
export const configError: string | null =
  url && anonKey
    ? null
    : 'Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY: copia .env.example a .env.local y rellénalo (o crea las variables del repo en GitHub).'

// PKCE returns the OAuth code in the query string (?code=...), so it doesn't
// collide with the hash router. supabase-js exchanges it and strips it from the URL.
// With no settings the client points nowhere; configError stops the app first.
export const supabase = createClient(url || 'http://supabase.invalid', anonKey || 'missing', {
  auth: {
    flowType: 'pkce',
    detectSessionInUrl: true,
    persistSession: true,
  },
})

// Where OAuth sends the user back: the app root, whatever BASE_PATH it's served from.
export const appUrl = new URL(import.meta.env.BASE_URL, window.location.origin).href
