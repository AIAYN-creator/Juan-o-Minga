<!--
  Big pre-launch countdown: days, hours, minutes, seconds on LED flip panels.
  Screen readers get the opening date once instead of a ticking clock.
-->
<script lang="ts">
  let { ms, at }: { ms: number; at: Date } = $props()

  const total = $derived(Math.ceil(ms / 1000))
  const units = $derived([
    { value: Math.floor(total / 86400), label: 'días' },
    { value: Math.floor((total % 86400) / 3600), label: 'horas' },
    { value: Math.floor((total % 3600) / 60), label: 'min' },
    { value: total % 60, label: 'seg' },
  ])

  const when = $derived(
    new Intl.DateTimeFormat('es-ES', {
      timeZone: 'Europe/Madrid',
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      hour: '2-digit',
      minute: '2-digit',
    }).format(at),
  )
</script>

<div class="launch">
  <p class="kicker">El telón se abre en</p>
  <div class="panels" aria-hidden="true">
    {#each units as u (u.label)}
      <div class="unit">
        <span class="panel led">{String(u.value).padStart(2, '0')}</span>
        <span class="label">{u.label}</span>
      </div>
    {/each}
  </div>
  <p class="when">{when}</p>
</div>

<style>
  .launch {
    display: grid;
    justify-items: center;
    gap: var(--space-3);
    width: 100%;
  }

  .kicker {
    font-family: var(--font-display);
    font-size: var(--text-sm);
    letter-spacing: 0.08em;
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  .panels {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: var(--space-2);
    width: min(100%, 18rem);
  }

  .unit {
    display: grid;
    justify-items: center;
    gap: var(--space-1);
  }

  .panel {
    position: relative;
    display: grid;
    place-items: center;
    width: 100%;
    padding: 0.2em 0;
    border-radius: var(--radius-sm);
    background: linear-gradient(180deg, #120206 0 49%, #050102 51% 100%);
    box-shadow:
      inset 0 0 0 1px rgba(255, 216, 102, 0.3),
      0 0.3rem 0.6rem rgba(0, 0, 0, 0.5);
    font-size: clamp(1.6rem, 8vw, 2.2rem);
    color: var(--gold-300);
    text-shadow: 0 0 0.3em rgba(255, 216, 102, 0.75);
  }

  /* flip-panel hinge */
  .panel::after {
    content: '';
    position: absolute;
    inset: 50% 0 auto;
    height: 1px;
    background: rgba(0, 0, 0, 0.8);
  }

  .label {
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .when {
    font-weight: 700;
    color: var(--ink);
  }

  .when::first-letter {
    text-transform: uppercase;
  }
</style>
