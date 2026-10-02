// The WhatsApp-able result: "Juan o Minga #N 🎰 x/3", one 🟢/🔴 per phrase in
// order, and the link to the game. Shared with the native share sheet on
// phones, copied to the clipboard elsewhere.

// Wherever the app is actually served (github.io subpath today), never a
// hard-coded domain: a link we don't own would send players to a stranger.
const siteLink = (): string => new URL(import.meta.env.BASE_URL, location.origin).href

export function shareText(roundNumber: number, results: boolean[]): string {
  const correct = results.filter(Boolean).length
  const emojis = results.map((ok) => (ok ? '🟢' : '🔴')).join('')
  return `Juan o Minga #${roundNumber} 🎰 ${correct}/3\n${emojis}\n${siteLink()}`
}

export type ShareOutcome = 'shared' | 'copied' | 'cancelled' | 'failed'

export async function shareResult(text: string): Promise<ShareOutcome> {
  const phone = window.matchMedia('(pointer: coarse)').matches
  if (phone && typeof navigator.share === 'function') {
    try {
      await navigator.share({ text })
      return 'shared'
    } catch (e) {
      if (e instanceof DOMException && e.name === 'AbortError') return 'cancelled'
      // Fall through to the clipboard.
    }
  }
  try {
    await navigator.clipboard.writeText(text)
    return 'copied'
  } catch {
    return 'failed'
  }
}
