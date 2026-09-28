// Who is playing: Supabase session + their profile (nickname).
//
// status:
//   loading         still reading the session / profile
//   anon            not logged in
//   needs-nickname  logged in with Google, no profile yet -> onboarding
//   ready           logged in with a nickname

import type { User } from '@supabase/supabase-js'
import { appUrl, configError, supabase } from './supabase'

export type Profile = { id: string; nickname: string }
export type SessionStatus = 'loading' | 'anon' | 'needs-nickname' | 'ready'

export const NICKNAME_MIN = 3
export const NICKNAME_MAX = 20

/** Same rules as the profiles table constraints. Returns an error message or null. */
export function validateNickname(raw: string): string | null {
  const nickname = raw.trim()
  const length = Array.from(nickname).length
  if (length < NICKNAME_MIN) return `Mínimo ${NICKNAME_MIN} caracteres, que esto no es un DNI.`
  if (length > NICKNAME_MAX) return `Máximo ${NICKNAME_MAX} caracteres, que no cabe en el marcador.`
  // eslint-disable-next-line no-control-regex
  if (/[\u0000-\u001f\u007f]/.test(nickname)) return 'Ese apodo lleva caracteres raros.'
  return null
}

class Session {
  status = $state<SessionStatus>('loading')
  user = $state<User | null>(null)
  profile = $state<Profile | null>(null)
  /** Problem coming back from Google or loading the profile, shown on the intro. */
  error = $state<string | null>(null)

  #started = false

  start() {
    if (this.#started || configError) return
    this.#started = true
    this.#readOAuthError()

    supabase.auth.onAuthStateChange((_event, session) => {
      const user = session?.user ?? null
      if (user?.id === this.user?.id && this.status !== 'loading') return
      this.user = user
      // Don't await Supabase calls inside this callback (supabase-js can deadlock).
      setTimeout(() => void this.#loadProfile(), 0)
    })
  }

  async signIn() {
    this.error = null
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: appUrl },
    })
    if (error) this.error = 'No hemos podido abrir el login de Google. Prueba otra vez.'
  }

  async signOut() {
    await supabase.auth.signOut()
    this.user = null
    this.profile = null
    this.status = 'anon'
  }

  /** Onboarding: create the profile. Returns an error message or null. */
  async createProfile(raw: string): Promise<string | null> {
    const invalid = validateNickname(raw)
    if (invalid) return invalid
    if (!this.user) return 'Se ha perdido la sesión. Vuelve a entrar con Google.'

    const { data, error } = await supabase
      .from('profiles')
      .insert({ id: this.user.id, nickname: raw.trim() })
      .select('id, nickname')
      .single()

    if (error) {
      if (error.code === '23505') {
        // Unique violation: either the nickname is taken, or this user already has a
        // profile (e.g. signed in twice in two tabs). Reload to tell them apart.
        await this.#loadProfile()
        if (this.profile) return null
        return 'Ese apodo ya está pillado. Sé original.'
      }
      if (error.code === '23514') return 'Ese apodo no cumple las normas del concurso.'
      return 'No hemos podido guardar tu apodo. Prueba otra vez.'
    }

    this.profile = data as Profile
    this.status = 'ready'
    return null
  }

  async #loadProfile() {
    if (!this.user) {
      this.profile = null
      this.status = 'anon'
      return
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('id, nickname')
      .eq('id', this.user.id)
      .maybeSingle()
    if (error) {
      this.error = 'No hemos podido cargar tu perfil. Recarga la página.'
      this.status = 'anon'
      return
    }
    this.profile = (data as Profile | null) ?? null
    this.status = this.profile ? 'ready' : 'needs-nickname'
  }

  // Google/Supabase report a failed or cancelled login as ?error=...&error_description=...
  #readOAuthError() {
    const url = new URL(window.location.href)
    const error = url.searchParams.get('error')
    if (!error) return
    this.error =
      error === 'access_denied'
        ? 'Has cancelado el login. Cuando quieras, aquí seguimos.'
        : 'El login con Google ha fallado. Prueba otra vez.'
    for (const key of ['error', 'error_code', 'error_description']) url.searchParams.delete(key)
    window.history.replaceState(window.history.state, '', url.toString())
  }
}

export const session = new Session()
