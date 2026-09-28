// Day boundary: midnight in Europe/Madrid, whatever the player's timezone.

const madridParts = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Europe/Madrid',
  hour12: false,
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
})

/** Milliseconds until the next round (next midnight in Madrid). */
export function msUntilNextRound(now = new Date()): number {
  const parts = Object.fromEntries(madridParts.formatToParts(now).map((p) => [p.type, p.value]))
  const elapsed = (Number(parts.hour) % 24) * 3600 + Number(parts.minute) * 60 + Number(parts.second)
  // DST days are 23/25h long, but the next midnight is what matters and the
  // error is at most an hour on two nights a year; the countdown re-syncs anyway.
  return Math.max(0, (86400 - elapsed) * 1000 - now.getMilliseconds())
}

export function formatCountdown(ms: number): string {
  const total = Math.ceil(ms / 1000)
  const h = Math.floor(total / 3600)
  const m = Math.floor((total % 3600) / 60)
  const s = total % 60
  return [h, m, s].map((n) => String(n).padStart(2, '0')).join(':')
}
