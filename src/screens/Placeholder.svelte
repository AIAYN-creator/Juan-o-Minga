<script lang="ts">
  import { href } from '../lib/router.svelte'

  let { title }: { title: string } = $props()
</script>

<main>
  <h1>{title}</h1>
  <p>En obras. Vuelve pronto, concursante.</p>
  <nav>
    <a href={href('/')}>Inicio</a>
    <a href={href('/jugar')}>Jugar</a>
    <a href={href('/ranking')}>Ranking</a>
    <a href={href('/buzon')}>Buzón</a>
  </nav>
</main>

<style>
  main {
    padding: 2rem 1rem;
    text-align: center;
  }

  nav {
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
  }
</style>
