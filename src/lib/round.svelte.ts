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

/** The line under the day's score. */
export function verdictFor(correct: number): string {
  if (correct === 3) return '¡PLENO!'
  if (correct === 2) return '2 de 3, no está mal'
  if (correct === 1) return '1 de 3, algo es algo'
  return '0 de 3, eres más de pueblo que nosotros'
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
          : error.message === 'not_launched'
            ? 'Todavía no ha empezado el concurso. ¡Paciencia!'
            : 'No hemos podido cargar la ronda de hoy.'
      return
    }
    this.rows = (data as RoundRow[]) ?? []
    this.status = 'ready'
  }

  /** First unanswered row, or null when the day is done. */
  readonly current = $derived(this.rows.find((r) => !r.answered) ?? null)

  /**
   * Answers one position. The server records it and returns the verdict with
   * the reveal; the row is updated in place. Returns an error message or null.
   */
  async submit(position: number, choice: Side): Promise<string | null> {
    const row = this.rows.find((r) => r.position === position)
    if (!row || row.answered) return 'Esa frase ya está respondida.'

    const { data, error } = await supabase
      .rpc('submit_answer', { p_position: position, p_choice: choice, p_round_date: row.round_date })
      .single()

    if (error) {
      if (error.message === 'already_answered' || error.message === 'round_over') {
        // Answered in another tab, or midnight passed: the server is the truth.
        await this.load()
        return error.message === 'round_over'
          ? 'Se acabó la ronda de ayer: aquí tienes la de hoy.'
          : 'Esa frase ya la habías respondido.'
      }
      return 'No hemos podido registrar tu respuesta. Prueba otra vez.'
    }

    const reveal = data as Pick<RoundRow, 'is_correct' | 'side' | 'author_display' | 'context'>
    Object.assign(row, { ...reveal, answered: true, choice })
    return null
  }

  reset() {
    this.rows = []
    this.status = 'idle'
    this.error = null
  }
}

export const round = new Round()
