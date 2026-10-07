<!--
  "¿Te sabes una mejor? Chívate": the nudge to the suggestion box on the result
  screen, with the progress toward the next streak shield (🛡️) once the
  player's stats are in.
-->
<script lang="ts">
  import { href } from '../router.svelte'
  import ArcadeButton from './ArcadeButton.svelte'

  let { shields, progress }: { shields?: number; progress?: number } = $props()

  const next = $derived(
    shields === undefined || progress === undefined
      ? ''
      : shields >= 2
        ? '🛡️🛡️ Protectores al máximo'
        : `${progress} de 3 frases aprobadas para tu próximo 🛡️`,
  )
</script>

<section class="snitch" aria-labelledby="snitch-title">
  <h2 id="snitch-title">¿Te sabes una mejor?</h2>
  <p>Mándala al buzón y que la sufra toda la peña.</p>
  <ArcadeButton variant="blue" size="lg" block href={href('/buzon')}>Chívate 🤫</ArcadeButton>
  {#if next}<p class="next">{next}</p>{/if}
</section>

<style>
  .snitch {
    display: grid;
    justify-items: center;
    gap: var(--space-3);
    padding: var(--space-5) var(--space-4);
    border-radius: var(--radius-md);
    background: rgba(28, 4, 13, 0.85);
    box-shadow:
      inset 0 0 0 2px rgba(255, 47, 214, 0.75),
      0 0 1.2rem rgba(255, 47, 214, 0.35);
    text-align: center;
  }

  h2 {
    font-family: var(--font-display);
    font-size: var(--text-lg);
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  p {
    color: var(--ink-dim);
  }

  .next {
    font-size: var(--text-sm);
    font-weight: 700;
    color: var(--ink);
  }
</style>
