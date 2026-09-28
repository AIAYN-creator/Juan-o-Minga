<!--
  LED scoreboard number whose digits roll like odometer wheels up to `value`.
  Rolls from 0 on mount and between values after that.
  Reduced motion: digits change in place.
-->
<script lang="ts">
  import { onMount } from 'svelte'

  let {
    value,
    minDigits = 1,
    suffix = '',
    tone = 'gold',
  }: {
    value: number
    minDigits?: number
    suffix?: string
    tone?: 'gold' | 'green' | 'cyan' | 'alarm'
  } = $props()

  let mounted = $state(false)
  onMount(() => {
    // Next frame, so the first paint shows zeros and the roll is visible.
    requestAnimationFrame(() => (mounted = true))
  })

  const shown = $derived(mounted ? Math.max(0, Math.round(value)) : 0)
  const width = $derived(Math.max(minDigits, String(Math.max(0, Math.round(value))).length))
  const digits = $derived(String(shown).padStart(width, '0').split('').map(Number))
</script>

<span class="number {tone}" aria-label="{Math.round(value)}{suffix}" role="img">
  {#each digits as d, i (width - i)}
    <span class="cell" aria-hidden="true">
      <span class="wheel" style:transform="translateY(-{d * 10}%)" style:transition-delay="{(width - 1 - i) * 70}ms">
        {#each [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as n (n)}
          <span class="digit">{n}</span>
        {/each}
      </span>
    </span>
  {/each}
  {#if suffix}<span class="suffix" aria-hidden="true">{suffix}</span>{/if}
</span>

<style>
  .number {
    display: inline-flex;
    align-items: stretch;
    gap: 0.08em;
    font-family: var(--font-led);
    font-weight: 900;
    line-height: 1;
    font-variant-numeric: tabular-nums;
    color: var(--c);
    text-shadow: 0 0 0.25em var(--c-glow);
  }

  .cell {
    position: relative;
    display: inline-block;
    height: 1.1em;
    width: 0.78em;
    overflow: hidden;
    border-radius: 0.12em;
    background: linear-gradient(180deg, #050102, #1a0508 50%, #050102);
    box-shadow: inset 0 0 0 1px rgba(255, 216, 102, 0.18);
  }

  .wheel {
    display: flex;
    flex-direction: column;
    transition: transform 700ms var(--ease-reel);
  }

  .digit {
    display: grid;
    place-items: center;
    height: 1.1em;
  }

  .suffix {
    align-self: center;
    margin-left: 0.08em;
    font-size: 0.7em;
  }

  .gold { --c: var(--gold-300); --c-glow: rgba(255, 216, 102, 0.7); }
  .green { --c: var(--neon-green); --c-glow: rgba(61, 255, 142, 0.7); }
  .cyan { --c: var(--neon-cyan); --c-glow: rgba(47, 243, 255, 0.7); }
  .alarm { --c: #ff5a5a; --c-glow: var(--alarm-glow); }
</style>
