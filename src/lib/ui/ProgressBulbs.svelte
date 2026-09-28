<!--
  The 3 progress bulbs above the game screen. Each one is off, current
  (pulsing), right (green + check) or wrong (red + cross): never colour alone.
-->
<script lang="ts" module>
  export type BulbState = 'off' | 'current' | 'right' | 'wrong'
</script>

<script lang="ts">
  let { states }: { states: BulbState[] } = $props()

  const text: Record<BulbState, string> = {
    off: 'pendiente',
    current: 'en juego',
    right: 'acierto',
    wrong: 'fallo',
  }
</script>

<ol class="bulbs" aria-label="Progreso">
  {#each states as state, i (i)}
    <li class="bulb {state}">
      <span class="glass" aria-hidden="true">
        {#if state === 'right'}✓{:else if state === 'wrong'}✗{:else}{i + 1}{/if}
      </span>
      <span class="sr-only">Frase {i + 1}: {text[state]}</span>
    </li>
  {/each}
</ol>

<style>
  .bulbs {
    display: flex;
    justify-content: center;
    gap: var(--space-4);
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .bulb {
    display: grid;
    place-items: center;
    width: 2.75rem;
    aspect-ratio: 1;
    padding: 3px;
    border-radius: 50%;
    background: var(--gold-bezel);
    box-shadow: 0 0.3rem 0.6rem rgba(0, 0, 0, 0.5);
  }

  .glass {
    display: grid;
    place-items: center;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    font-family: var(--font-display);
    font-size: 1.05rem;
    line-height: 1;
    transition:
      background var(--dur-base) ease,
      box-shadow var(--dur-base) ease,
      color var(--dur-base) ease;
  }

  .off .glass {
    color: rgba(255, 216, 102, 0.45);
    background: radial-gradient(circle at 35% 30%, #4a1a22, #1c040d 75%);
    box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.6);
  }

  .current .glass {
    color: var(--ink-on-gold);
    background: radial-gradient(circle at 35% 30%, #fff, #fff1b8 40%, #f0b429 90%);
    box-shadow: 0 0 0.6rem 0.15rem rgba(255, 216, 102, 0.75);
    animation: pulse 1.1s ease-in-out infinite;
  }

  .right .glass,
  .wrong .glass {
    -webkit-text-stroke: 0.06em currentColor; /* ✓ / ✗ fallback glyphs, thickened */
  }

  .right .glass {
    color: #04260f;
    background: radial-gradient(circle at 35% 30%, #eafff2, var(--neon-green) 45%, #0d9a4a 95%);
    box-shadow: var(--glow-green);
  }

  .wrong .glass {
    color: #fff;
    background: radial-gradient(circle at 35% 30%, #ffd0d0, var(--alarm) 45%, #8a0808 95%);
    box-shadow: var(--glow-alarm);
  }

  @keyframes pulse {
    50% {
      box-shadow: 0 0 1.1rem 0.35rem rgba(255, 216, 102, 0.9);
      transform: scale(1.06);
    }
  }
</style>
