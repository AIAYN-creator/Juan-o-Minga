<!--
  The big studio screen the phrase appears on. The text switches on letter by
  letter (whole thing in well under a second, however long the phrase), and is
  announced to screen readers in one go. Reduced motion: plain fade-in.
-->
<script lang="ts">
  import { motion } from '../motion.svelte'

  let {
    text,
    caption,
  }: {
    text: string
    /** Small label above the text, e.g. "FRASE 2 DE 3". */
    caption?: string
  } = $props()

  const MAX_TOTAL_MS = 850
  const chars = $derived(Array.from(text))
  const step = $derived(Math.min(32, MAX_TOTAL_MS / Math.max(1, chars.length)))
</script>

<figure class="screen">
  {#if caption}<figcaption class="caption">{caption}</figcaption>{/if}
  <blockquote class="text" aria-label={text}>
    {#key text}
      {#if motion.reduced}
        <span class="fade" aria-hidden="true">«{text}»</span>
      {:else}
        <span aria-hidden="true">
          <span class="ch" style:animation-delay="0ms">«</span>{#each chars as ch, i (i)}<span
              class="ch"
              style:animation-delay="{Math.round((i + 1) * step)}ms">{ch}</span
            >{/each}<span class="ch" style:animation-delay="{Math.round((chars.length + 1) * step)}ms">»</span>
        </span>
      {/if}
    {/key}
  </blockquote>
</figure>

<style>
  .screen {
    position: relative;
    margin: 0;
    padding: 0.6rem;
    border-radius: var(--radius-lg);
    background: var(--gold-bezel);
    box-shadow:
      inset 0 1px 0 rgba(255, 241, 184, 0.8),
      0 1rem 2.5rem rgba(0, 0, 0, 0.65),
      0 0 2.5rem rgba(47, 243, 255, 0.12);
  }

  .caption {
    position: absolute;
    top: 0;
    left: 50%;
    transform: translate(-50%, -50%);
    padding: 0.3rem 0.85rem;
    border-radius: var(--radius-pill);
    background: var(--red-500);
    box-shadow:
      0 0 0 2px var(--gold-300),
      0 0.25rem 0.5rem rgba(0, 0, 0, 0.5);
    font-family: var(--font-display);
    font-size: var(--text-xs);
    letter-spacing: 0.06em;
    color: #fff;
    white-space: nowrap;
    z-index: 1;
  }

  .text {
    position: relative;
    display: grid;
    place-items: center;
    min-height: 11.5rem;
    margin: 0;
    padding: var(--space-6) var(--space-4) var(--space-5);
    border-radius: calc(var(--radius-lg) - 0.45rem);
    /* Dark CRT glass with scanlines and a soft cyan bloom */
    background:
      repeating-linear-gradient(0deg, rgba(0, 0, 0, 0.18) 0 1px, transparent 1px 3px),
      radial-gradient(ellipse at 50% 40%, #0e2a3a 0%, #071019 60%, #030609 100%);
    box-shadow:
      inset 0 0 0 2px rgba(0, 0, 0, 0.8),
      inset 0 0 2.5rem rgba(47, 243, 255, 0.12);
    font-family: var(--font-body);
    font-size: clamp(1.3rem, 5.6vw, 1.75rem);
    font-weight: 700;
    line-height: 1.3;
    text-align: center;
    text-wrap: balance;
    color: #f2feff;
    text-shadow:
      0 0 0.35rem rgba(47, 243, 255, 0.55),
      0 0 1.2rem rgba(47, 243, 255, 0.25);
    overflow-wrap: anywhere;
  }

  /* Glass reflection */
  .text::after {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: linear-gradient(160deg, rgba(255, 255, 255, 0.09) 0%, rgba(255, 255, 255, 0) 38%);
    pointer-events: none;
  }

  .ch {
    opacity: 0;
    animation: switch-on 140ms ease-out forwards;
  }

  @keyframes switch-on {
    0% {
      opacity: 0;
      color: #fff;
      text-shadow: 0 0 0.8rem #fff;
    }
    60% {
      opacity: 1;
      color: #fff;
    }
    100% {
      opacity: 1;
    }
  }

  .fade {
    animation: fade 250ms ease both;
  }

  @keyframes fade {
    from { opacity: 0; }
    to { opacity: 1; }
  }
</style>
