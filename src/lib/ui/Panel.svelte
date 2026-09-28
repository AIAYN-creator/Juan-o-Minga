<!--
  Gold-trimmed velvet panel for secondary content: stats, forms, leaderboard.
-->
<script lang="ts">
  import type { Snippet } from 'svelte'

  let { children, title }: { children: Snippet; title?: string } = $props()
</script>

<section class="panel">
  {#if title}<h2 class="title gold-text">{title}</h2>{/if}
  {@render children()}
</section>

<style>
  .panel {
    padding: var(--space-5) var(--space-4);
    border-radius: var(--radius-lg);
    background:
      radial-gradient(ellipse at 50% 0%, rgba(255, 216, 102, 0.1), transparent 55%),
      linear-gradient(180deg, rgba(82, 16, 36, 0.92), rgba(28, 4, 13, 0.95));
    box-shadow:
      inset 0 0 0 1.5px var(--gold-500),
      inset 0 0 0 4px rgba(28, 4, 13, 0.9),
      inset 0 0 0 5px rgba(240, 180, 41, 0.35),
      0 0.75rem 2rem rgba(0, 0, 0, 0.55);
  }

  .title {
    margin-bottom: var(--space-4);
    font-size: var(--text-lg);
    text-align: center;
  }
</style>
