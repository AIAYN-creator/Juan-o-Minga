// Reactive prefers-reduced-motion flag, for components that animate from JS
// (reel, rolling numbers, confetti, type-on). CSS-only animations use the media
// query in global.css instead.

const query = window.matchMedia('(prefers-reduced-motion: reduce)')

class Motion {
  reduced = $state(query.matches)

  constructor() {
    query.addEventListener('change', (e) => {
      this.reduced = e.matches
    })
  }
}

export const motion = new Motion()
