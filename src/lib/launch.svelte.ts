// Launch gate on the client: when the curtain rises (app_config.launch_at).
// Only for the countdown and to avoid pointless calls. The server refuses the
// round before launch_at anyway ('not_launched').

import { supabase } from './supabase'

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
    this.status = 'loading'
    const { data, error } = await supabase.from('app_config').select('launch_at').single()
    if (error || !data) {
      // Unknown: behave as open and let the server have the last word.
      this.status = 'error'
      this.at = new Date(0)
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
