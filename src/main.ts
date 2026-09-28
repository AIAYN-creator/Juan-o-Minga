import { mount } from 'svelte'

// Self-hosted fonts (no Google Fonts request, no third-party tracking).
import '@fontsource/bungee/latin-400.css'
import '@fontsource/monoton/latin-400.css'
import '@fontsource-variable/rubik/wght.css'
import '@fontsource/doto/latin-900.css'

import './styles/tokens.css'
import './styles/global.css'
import App from './App.svelte'

const app = mount(App, {
  target: document.getElementById('app')!,
})

export default app
