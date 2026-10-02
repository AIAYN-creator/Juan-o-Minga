import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig, loadEnv, type Plugin } from 'vite'

// BASE_PATH is the public path the app is served from:
// "/Juan-o-Minga/" on aiayn-creator.github.io/Juan-o-Minga, "/" on a custom domain.
function normalizeBase(raw: string | undefined): string {
  const trimmed = (raw ?? '').trim().replace(/^\/+|\/+$/g, '')
  return trimmed ? `/${trimmed}/` : '/'
}

// Link previews need absolute URLs (og:image, og:url). SITE_URL is the public
// root, e.g. https://aiayn-creator.github.io/Juan-o-Minga/; CI takes it from the Pages settings.
function siteUrl(url: string): Plugin {
  return {
    name: 'site-url',
    transformIndexHtml: (html) => html.replaceAll('__SITE_URL__', url),
  }
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const base = normalizeBase(env.BASE_PATH)
  const url = (env.SITE_URL || `http://localhost:5173${base}`).replace(/\/?$/, '/')
  return {
    base,
    plugins: [svelte(), siteUrl(url)],
  }
})
