<script lang="ts">
  import type { Snippet } from 'svelte'
  import { href } from '../lib/router.svelte'

  let { title, children }: { title: string; children?: Snippet } = $props()
</script>

<main class="page">
  <h1 class="gold-text">{title}</h1>
  <p>En obras. Vuelve pronto, concursante.</p>
  {@render children?.()}
  <nav>
    <a href={href('/')}>Inicio</a>
    <a href={href('/jugar')}>Jugar</a>
    <a href={href('/ranking')}>Ranking</a>
    <a href={href('/buzon')}>Buzón</a>
  </nav>
</main>

<style>
  main {
    display: grid;
    gap: var(--space-4);
    text-align: center;
  }

  h1 {
    font-size: var(--text-2xl);
  }

  nav {
    display: flex;
    gap: var(--space-4);
    justify-content: center;
    flex-wrap: wrap;
  }
</style>
