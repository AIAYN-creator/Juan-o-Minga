// Today's round as the server sends it (get_today_round). Unanswered rows carry
// only id + text: the answer key never reaches the client before answering.

import { supabase } from './supabase'

export type Side = 'charanga' | 'penista'

export type RoundRow = {
  round_date: string
  round_number: number
  position: number
  phrase_id: string
  text: string
  answered: boolean
  choice: Side | null
  is_correct: boolean | null
  side: Side | null
  author_display: string | null
  context: string | null
}

class Round {
  rows = $state<RoundRow[]>([])
  status = $state<'idle' | 'loading' | 'ready' | 'error'>('idle')
  error = $state<string | null>(null)

  readonly number = $derived(this.rows[0]?.round_number ?? null)
  readonly answered = $derived(this.rows.filter((r) => r.answered).length)
  readonly correct = $derived(this.rows.filter((r) => r.is_correct).length)
  readonly finished = $derived(this.rows.length === 3 && this.answered === 3)

  async load() {
    this.status = 'loading'
    this.error = null
    const { data, error } = await supabase.rpc('get_today_round')
    if (error) {
      this.status = 'error'
      this.error =
        error.message === 'not_enough_phrases'
          ? 'Hoy el jurado no ha preparado frases. Vuelve más tarde.'
          : 'No hemos podido cargar la ronda de hoy.'
      return
    }
    this.rows = (data as RoundRow[]) ?? []
    this.status = 'ready'
  }

  reset() {
    this.rows = []
    this.status = 'idle'
    this.error = null
  }
}

export const round = new Round()
