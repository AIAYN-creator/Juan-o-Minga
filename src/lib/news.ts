// Release notes: the one source for the "what's new" panel, the #/novedades
// screen and the version link on the intro. Newest first. Adding a release here
// shows the panel once more to everyone (see Intro.svelte).

export type Part = string | { strong: string }
export type NewsItem = { icon: string; title: string; text: string }
export type Release = {
  version: string
  date: string // YYYY-MM-DD, Madrid
  title: string
  intro?: Part[]
  items: NewsItem[]
}

export const releases: Release[] = [
  {
    version: '2.0.0',
    date: '2026-10-07',
    title: 'Juan o Minga v.2.0.0',
    intro: [
      'Ahora ofrecemos ',
      { strong: 'recompensas' },
      ' por enviar frases al ',
      { strong: 'buzón' },
      ' (y que se aprueben...). Sigue capado a 10 como máximo al día por usuario...',
    ],
    items: [
      { icon: '🤫', title: 'Chívate.', text: 'Al acabar la partida, manda tu frase al buzón. Que la sufra toda la peña.' },
      {
        icon: '🛡️',
        title: 'Protectores de racha.',
        text: 'Cada 3 frases tuyas aprobadas, un protector (hasta 2). Si un día no juegas, salva tu racha.',
      },
      {
        icon: '📣',
        title: 'Megáfono de oro.',
        text: 'Para el mayor chivato de la peña, al lado de su apodo en el ranking.',
      },
    ],
  },
  {
    version: '1.0.0',
    date: '2026-10-02',
    title: 'El estreno',
    items: [
      { icon: '🎰', title: '3 frases al día.', text: 'Las mismas para todo el mundo. ¿Charanga o peñista? Un solo intento.' },
      { icon: '🏆', title: 'Ranking.', text: 'Por % de aciertos, a partir de 3 días jugados, con rachas y plenos.' },
      { icon: '📮', title: 'Buzón.', text: 'Propón frases; el jurado decide cuáles entran al juego.' },
      { icon: '⏳', title: 'Cuenta atrás.', text: 'Hasta el estreno del viernes 2 de octubre a las 18:30.' },
    ],
  },
]

export const latest = releases[0]

/** Is version a newer than b? (null = nothing seen) */
export function isNewer(a: string, b: string | null): boolean {
  if (!b) return true
  const pa = a.split('.').map(Number)
  const pb = b.split('.').map(Number)
  for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] > pb[i]
  return false
}

// Without a session the panel is remembered per browser.
const KEY = 'juanominga:news-seen'

export function localSeen(): string | null {
  try {
    return localStorage.getItem(KEY)
  } catch {
    return null
  }
}

export function rememberSeen(version: string): void {
  try {
    if (isNewer(version, localSeen())) localStorage.setItem(KEY, version)
  } catch {
    // private mode or blocked storage: it may show again, no harm done
  }
}

export function formatDate(date: string): string {
  return new Date(`${date}T12:00:00`).toLocaleDateString('es-ES', { day: 'numeric', month: 'long', year: 'numeric' })
}
