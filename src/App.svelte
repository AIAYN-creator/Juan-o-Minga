<script lang="ts">
  import { redirect, router, type Route } from './lib/router.svelte'
  import { session } from './lib/session.svelte'
  import { configError } from './lib/supabase'
  import ArcadeButton from './lib/ui/ArcadeButton.svelte'
  import Nickname from './screens/Nickname.svelte'
  import Placeholder from './screens/Placeholder.svelte'

  // Each screen replaces its placeholder in its own card (intro, game-flow, ...).
  const titles: Record<Route, string> = {
    '/': 'Juan o Minga',
    '/jugar': 'Jugar',
    '/ranking': 'Ranking',
    '/buzon': 'Buzón',
    '/apodo': 'Elige apodo',
    '/kit': 'Juan o Minga',
  }

  // Routes that need a player with a nickname.
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
</script>

{#if isKit}
  {#await import('./screens/Kit.svelte') then Kit}
    <Kit.default />
  {/await}
{:else if configError}
  <main class="page notice">
    <h1 class="gold-text">Falta configuración</h1>
    <p>{configError}</p>
  </main>
{:else if session.status === 'loading'}
  <main class="page notice" aria-busy="true">
    <p class="neon-cyan loading">Encendiendo el plató…</p>
  </main>
{:else if router.current === '/apodo'}
  <Nickname />
{:else}
  <!-- Temporary login controls until the intro card builds the real screen -->
  <Placeholder title={titles[router.current]}>
    {#if router.current === '/'}
      <div class="auth">
        {#if session.error}<p class="error" role="alert">{session.error}</p>{/if}
        {#if session.status === 'ready'}
          <p>Hola, <strong>{session.profile?.nickname}</strong></p>
          <ArcadeButton variant="red" onclick={() => session.signOut()}>Salir</ArcadeButton>
        {:else}
          <ArcadeButton size="lg" onclick={() => session.signIn()}>Entrar con Google</ArcadeButton>
        {/if}
      </div>
    {/if}
  </Placeholder>
{/if}

<style>
  .notice {
    display: grid;
    gap: var(--space-4);
    min-height: 100dvh;
    align-content: center;
    text-align: center;
  }

  .loading {
    font-family: var(--font-display);
    font-size: var(--text-lg);
  }

  .auth {
    display: grid;
    justify-items: center;
    gap: var(--space-4);
    margin-block: var(--space-4);
  }

  .error {
    color: var(--red-300);
    font-weight: 600;
  }
</style>
