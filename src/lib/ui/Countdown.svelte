<!--
  LED countdown to the next round (midnight, Madrid time). Calls ondone when
  it reaches zero so the screen can load the new round.
-->
<script lang="ts">
  import { onDestroy } from 'svelte'
  import { formatCountdown, msUntilNextRound } from '../time'

  let { label = 'Próxima ronda en', ondone }: { label?: string; ondone?: () => void } = $props()

  let ms = $state(msUntilNextRound())
  let fired = false

  const timer = setInterval(() => {
    ms = msUntilNextRound()
    if (ms <= 1000 && !fired) {
      fired = true
      setTimeout(() => ondone?.(), 1500)
    }
  }, 1000)

  onDestroy(() => clearInterval(timer))
</script>

<p class="countdown">
  <span class="label">{label}</span>
  <span class="led time" role="timer" aria-live="off">{formatCountdown(ms)}</span>
</p>

<style>
  .countdown {
    display: grid;
    justify-items: center;
    gap: var(--space-1);
  }

  .label {
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .time {
    padding: 0.15em 0.45em;
    border-radius: var(--radius-sm);
    background: #050102;
    box-shadow: inset 0 0 0 1px rgba(255, 216, 102, 0.25);
    font-size: 1.75rem;
    letter-spacing: 0.06em;
    color: var(--gold-300);
    text-shadow: 0 0 0.3em rgba(255, 216, 102, 0.7);
  }
</style>
