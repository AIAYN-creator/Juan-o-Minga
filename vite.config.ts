import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig, loadEnv } from 'vite'

// BASE_PATH is the public path the app is served from:
// "/Juan-o-Minga/" on aiayn-creator.github.io/Juan-o-Minga, "/" on juanominga.com.
function normalizeBase(raw: string | undefined): string {
  const trimmed = (raw ?? '').trim().replace(/^\/+|\/+$/g, '')
  return trimmed ? `/${trimmed}/` : '/'
}

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    base: normalizeBase(env.BASE_PATH),
    plugins: [svelte()],
  }
})
