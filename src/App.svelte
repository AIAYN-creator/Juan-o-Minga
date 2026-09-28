<script lang="ts">
  import { router, type Route } from './lib/router.svelte'
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
</script>

{#if import.meta.env.DEV && router.current === '/kit'}
  {#await import('./screens/Kit.svelte') then Kit}
    <Kit.default />
  {/await}
{:else}
  <Placeholder title={titles[router.current]} />
{/if}
