<script lang="ts">
  import mark from '../brand/mark.svg'
  import { redirect, router, type Route } from './lib/router.svelte'
  import { session } from './lib/session.svelte'
  import { configError } from './lib/supabase'
  import NeonLogo from './lib/ui/NeonLogo.svelte'
  import Game from './screens/Game.svelte'
  import Intro from './screens/Intro.svelte'
  import Leaderboard from './screens/Leaderboard.svelte'
  import Nickname from './screens/Nickname.svelte'
  import SuggestionBox from './screens/SuggestionBox.svelte'

  // Routes that need a player with a nickname. The ranking is public.
  const playerOnly: Route[] = ['/jugar', '/buzon']

  const isKit = $derived(import.meta.env.DEV && router.current === '/kit')

  session.start()

  // Guards: no nickname -> onboarding; onboarding only while it's needed;
  // playing and the suggestion box need a player.
  $effect(() => {
    if (isKit) return
    const { status } = session
    const route = router.current
    if (status === 'needs-nickname' && route !== '/apodo') redirect('/apodo')
    else if (status !== 'needs-nickname' && status !== 'loading' && route === '/apodo') redirect('/')
    else if (status === 'anon' && playerOnly.includes(route)) redirect('/')
  })

  // Each screen starts at the top.
  $effect(() => {
    void router.current
    window.scrollTo(0, 0)
  })
</script>

{#if isKit}
  {#await import('./screens/Kit.svelte') then Kit}
    <Kit.default />
  {/await}
{:else if configError}
  <main class="page notice">
    <img src={mark} alt="" width="140" height="140" />
    <NeonLogo size="md" />
    <p>El plató está en obras. Vuelve en un rato.</p>
    {#if import.meta.env.DEV}<p class="dev">{configError}</p>{/if}
  </main>
{:else if session.status === 'loading'}
  <main class="page notice" aria-busy="true">
    <img class="spin" src={mark} alt="" width="120" height="120" />
    <p class="neon-cyan loading">Encendiendo el plató…</p>
  </main>
{:else if router.current === '/apodo'}
  <Nickname />
{:else if router.current === '/ranking'}
  <Leaderboard />
{:else if router.current === '/buzon'}
  <SuggestionBox />
{:else if router.current === '/jugar'}
  <Game />
{:else}
  <Intro />
{/if}

<style>
  .notice {
    display: grid;
    justify-items: center;
    gap: var(--space-4);
    min-height: 100dvh;
    align-content: center;
    text-align: center;
  }

  .loading {
    font-family: var(--font-display);
    font-size: var(--text-lg);
  }

  .dev {
    font-size: var(--text-xs);
    color: var(--ink-mute);
  }

  .spin {
    animation: wobble 900ms ease-in-out infinite alternate;
  }

  @keyframes wobble {
    from { transform: rotate(-4deg) scale(0.97); }
    to { transform: rotate(4deg) scale(1.03); }
  }
</style>
