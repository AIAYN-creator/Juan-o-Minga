<!--
  One release's notes: optional intro, then each novelty with its icon. Shared
  by the what's-new panel (items pop in one after another) and #/novedades.
-->
<script lang="ts">
  import type { Release } from '../news'

  let { release, pop = false }: { release: Release; pop?: boolean } = $props()
</script>

{#if release.intro}
  <p class="intro">
    {#each release.intro as part, i (i)}{#if typeof part === 'string'}{part}{:else}<strong>{part.strong}</strong>{/if}{/each}
  </p>
{/if}
<ul class="items">
  {#each release.items as item, i (item.title)}
    <li class:fx-pop-in={pop} style:animation-delay={pop ? `${150 + i * 120}ms` : null}>
      <span class="icon" aria-hidden="true">{item.icon}</span>
      <span><strong>{item.title}</strong> {item.text}</span>
    </li>
  {/each}
</ul>

<style>
  .intro {
    color: var(--ink-dim);
    text-align: center;
  }

  .intro strong {
    color: var(--gold-300);
  }

  .items {
    display: grid;
    gap: var(--space-3);
    margin: 0;
    padding: 0;
    list-style: none;
  }

  li {
    display: grid;
    grid-template-columns: 2rem minmax(0, 1fr);
    align-items: start;
    gap: var(--space-2);
    text-align: left;
  }

  .icon {
    font-size: 1.5rem;
    line-height: 1.2;
    text-align: center;
  }

  li strong {
    color: var(--ink);
  }
</style>
