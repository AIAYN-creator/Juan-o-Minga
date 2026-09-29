// Launch gate on the client: when the curtain rises (app_config.launch_at).
// Only for the countdown and to avoid pointless calls. The server refuses the
// round before launch_at anyway ('not_launched').

import { configError, supabase } from './supabase'

/**
 * Opening night as shipped. app_config.launch_at in the database wins; this is
 * the fallback so the countdown still shows when Supabase isn't reachable or
 * configured yet. Keep it in sync with the launch_gate migration.
 */
export const DEFAULT_LAUNCH_AT = new Date('2026-10-02T18:30:00+02:00')

class Launch {
  at = $state<Date | null>(null)
  now = $state(Date.now())
  status = $state<'idle' | 'loading' | 'ready' | 'error'>('idle')

  /** null while unknown; true once the game is open. */
  readonly open = $derived(this.at === null ? null : this.now >= this.at.getTime())
  readonly msLeft = $derived(this.at === null ? 0 : Math.max(0, this.at.getTime() - this.now))

  #timer: ReturnType<typeof setInterval> | null = null

  async load() {
    if (this.status === 'loading' || this.status === 'ready') return
    if (configError) {
      this.status = 'error'
      this.at = DEFAULT_LAUNCH_AT
      this.#tick()
      return
    }
    this.status = 'loading'
    const { data, error } = await supabase.from('app_config').select('launch_at').single()
    if (error || !data) {
      // Unreachable: fall back to the shipped date; the server still decides.
      this.status = 'error'
      this.at = DEFAULT_LAUNCH_AT
      this.#tick()
      return
    }
    this.at = new Date((data as { launch_at: string }).launch_at)
    this.status = 'ready'
    this.#tick()
  }

  // Tick every second only while the countdown matters.
  #tick() {
    if (this.#timer) return
    this.#timer = setInterval(() => {
      this.now = Date.now()
      if (this.open && this.#timer) {
        clearInterval(this.#timer)
        this.#timer = null
      }
    }, 1000)
  }
}

export const launch = new Launch()
