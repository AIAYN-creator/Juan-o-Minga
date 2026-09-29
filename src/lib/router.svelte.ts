// Hash routing (#/ranking): works on GitHub Pages under a subpath with no
// server-side fallback, and keeps working unchanged on juanominga.com.

// '/kit' is the design-system showroom; App only renders it in dev builds.
export const routes = ['/', '/jugar', '/resultado', '/ranking', '/buzon', '/apodo', '/kit'] as const
export type Route = (typeof routes)[number]

function parse(hash: string): Route {
  const path = hash.replace(/^#/, '') || '/'
  return (routes as readonly string[]).includes(path) ? (path as Route) : '/'
}

class Router {
  current = $state<Route>(parse(window.location.hash))

  constructor() {
    window.addEventListener('hashchange', () => {
      this.current = parse(window.location.hash)
    })
  }
}

export const router = new Router()

export function href(route: Route): string {
  return `#${route}`
}

export function navigate(route: Route): void {
  window.location.hash = route
}

/** Like navigate, but replaces the history entry: for guards, so Back doesn't bounce. */
export function redirect(route: Route): void {
  window.history.replaceState(window.history.state, '', `#${route}`)
  router.current = route
}
