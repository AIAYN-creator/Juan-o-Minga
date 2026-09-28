<!--
  Chunky 3D arcade button for calls to action (JUGAR, SIGUIENTE, COMPARTIR...).
  Sits on a coloured rim and physically sinks when pressed.
  Renders an <a> when given href, a <button> otherwise.
-->
<script lang="ts">
  import type { Snippet } from 'svelte'
  import type { HTMLButtonAttributes } from 'svelte/elements'

  type Variant = 'gold' | 'red' | 'blue' | 'green'

  let {
    children,
    variant = 'gold',
    size = 'md',
    block = false,
    href,
    ...rest
  }: {
    children: Snippet
    variant?: Variant
    size?: 'md' | 'lg' | 'xl'
    block?: boolean
    href?: string
  } & HTMLButtonAttributes = $props()
</script>

{#if href}
  <a class="btn {variant} {size}" class:block {href}>
    <span class="label">{@render children()}</span>
  </a>
{:else}
  <!-- ontouchstart: lets iOS Safari apply :active on tap -->
  <button class="btn {variant} {size}" class:block type="button" ontouchstart={() => {}} {...rest}>
    <span class="label">{@render children()}</span>
  </button>
{/if}

<style>
  .btn {
    --depth: 7px;
    position: relative;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-height: 3rem;
    padding: 0.7em 1.6em 0.75em;
    border: 0;
    border-radius: var(--radius-pill);
    font-family: var(--font-display);
    font-size: var(--text-md);
    letter-spacing: 0.04em;
    text-decoration: none;
    text-transform: uppercase;
    white-space: nowrap;
    color: var(--fg);
    background: linear-gradient(180deg, var(--hi) 0%, var(--base) 55%, var(--lo) 100%);
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.55),
      inset 0 -3px 0 rgba(0, 0, 0, 0.18),
      0 var(--depth) 0 var(--rim),
      0 calc(var(--depth) + 0.5rem) 1.25rem rgba(0, 0, 0, 0.55);
    transform: translateY(0);
    transition:
      transform var(--dur-instant) ease-out,
      box-shadow var(--dur-instant) ease-out,
      filter var(--dur-fast) ease-out;
    cursor: pointer;
    user-select: none;
    -webkit-user-select: none;
    touch-action: manipulation;
  }

  /* Glossy highlight on the top half */
  .btn::before {
    content: '';
    position: absolute;
    inset: 3px 10% 52% 10%;
    border-radius: var(--radius-pill);
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.55), rgba(255, 255, 255, 0));
    pointer-events: none;
  }

  .label {
    position: relative;
    text-shadow: var(--label-shadow);
  }

  .btn:hover {
    filter: brightness(1.08) saturate(1.05);
  }

  .btn:active:not(:disabled) {
    transform: translateY(calc(var(--depth) - 2px));
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.4),
      inset 0 -2px 0 rgba(0, 0, 0, 0.2),
      0 2px 0 var(--rim),
      0 0.4rem 0.6rem rgba(0, 0, 0, 0.5);
  }

  .btn:disabled {
    cursor: not-allowed;
    filter: grayscale(0.7) brightness(0.7);
  }

  .block {
    display: flex;
    width: 100%;
  }

  .lg {
    --depth: 9px;
    min-height: 3.75rem;
    font-size: var(--text-lg);
  }

  .xl {
    --depth: 11px;
    min-height: 4.75rem;
    font-size: clamp(1.75rem, 8vw, 2.25rem);
    padding-inline: 2em;
  }

  .gold {
    --hi: #fff4c2;
    --base: var(--gold-500);
    --lo: var(--gold-600);
    --rim: var(--gold-800);
    --fg: var(--ink-on-gold);
    --label-shadow: 0 1px 0 rgba(255, 244, 194, 0.7);
  }

  .red {
    --hi: #ff8a98;
    --base: var(--red-500);
    --lo: var(--red-600);
    --rim: var(--red-800);
    --fg: #fff;
    --label-shadow: 0 2px 0 rgba(110, 6, 22, 0.7);
  }

  .blue {
    --hi: #a6d6ff;
    --base: var(--blue-500);
    --lo: var(--blue-600);
    --rim: var(--blue-800);
    --fg: #fff;
    --label-shadow: 0 2px 0 rgba(6, 40, 107, 0.7);
  }

  .green {
    --hi: #9dffc6;
    --base: #19b35c;
    --lo: var(--felt-600);
    --rim: var(--felt-800);
    --fg: #fff;
    --label-shadow: 0 2px 0 rgba(6, 66, 34, 0.7);
  }
</style>
