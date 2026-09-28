<!--
  Giant game-show buzzer: a glossy dome in a gold housing that sinks when hit.
  `latched` keeps it pressed down (the contestant's locked-in answer).
-->
<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements'

  let {
    label,
    variant = 'red',
    latched = false,
    ...rest
  }: {
    label: string
    variant?: 'red' | 'blue'
    latched?: boolean
  } & HTMLButtonAttributes = $props()
</script>

<button
  class="buzzer {variant}"
  class:latched
  type="button"
  aria-pressed={latched}
  ontouchstart={() => {}}
  {...rest}
>
  <span class="housing">
    <span class="dome">
      <span class="label">{label}</span>
    </span>
  </span>
</button>

<style>
  .buzzer {
    --depth: 10px;
    --size: min(40vw, 9.5rem);
    display: inline-grid;
    place-items: center;
    padding: 0;
    border: 0;
    background: none;
    cursor: pointer;
    user-select: none;
    -webkit-user-select: none;
    touch-action: manipulation;
    border-radius: 50%;
  }

  .buzzer:focus-visible {
    outline-offset: 6px;
    border-radius: 50%;
  }

  /* Gold ring the dome sits in */
  .housing {
    display: grid;
    place-items: center;
    width: var(--size);
    aspect-ratio: 1;
    border-radius: 50%;
    padding: 0.6rem 0.6rem calc(0.6rem + var(--depth));
    background:
      radial-gradient(circle at 50% 40%, rgba(0, 0, 0, 0.55) 0 58%, transparent 60%),
      var(--gold-bezel);
    box-shadow:
      inset 0 2px 0 rgba(255, 241, 184, 0.8),
      inset 0 -3px 0 rgba(122, 74, 6, 0.8),
      0 0.75rem 1.5rem rgba(0, 0, 0, 0.6);
  }

  .dome {
    display: grid;
    place-items: center;
    width: 100%;
    aspect-ratio: 1;
    border-radius: 50%;
    background: radial-gradient(circle at 38% 28%, var(--hi) 0%, var(--base) 42%, var(--lo) 78%, var(--rim) 100%);
    box-shadow:
      inset 0 -0.4rem 0.8rem rgba(0, 0, 0, 0.3),
      0 var(--depth) 0 var(--rim),
      0 calc(var(--depth) + 0.3rem) 0.5rem rgba(0, 0, 0, 0.55);
    transform: translateY(0);
    transition:
      transform var(--dur-instant) ease-out,
      box-shadow var(--dur-instant) ease-out;
    position: relative;
    overflow: hidden;
  }

  /* Specular highlight */
  .dome::before {
    content: '';
    position: absolute;
    top: 9%;
    left: 20%;
    width: 60%;
    height: 34%;
    border-radius: 50%;
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.75), rgba(255, 255, 255, 0));
    pointer-events: none;
  }

  .label {
    position: relative;
    font-family: var(--font-display);
    font-size: clamp(0.95rem, 4.6vw, 1.2rem);
    letter-spacing: 0.02em;
    color: #fff;
    text-shadow:
      0 2px 0 var(--rim),
      0 0 0.6rem rgba(0, 0, 0, 0.35);
  }

  .buzzer:hover .dome {
    filter: brightness(1.08);
  }

  .buzzer:active:not(:disabled) .dome,
  .latched .dome {
    transform: translateY(calc(var(--depth) - 2px));
    box-shadow:
      inset 0 -0.3rem 0.6rem rgba(0, 0, 0, 0.35),
      0 2px 0 var(--rim),
      0 0.25rem 0.35rem rgba(0, 0, 0, 0.5);
  }

  .latched .dome {
    filter: brightness(1.15) saturate(1.1);
  }

  .latched .housing {
    box-shadow:
      inset 0 2px 0 rgba(255, 241, 184, 0.8),
      inset 0 -3px 0 rgba(122, 74, 6, 0.8),
      0 0 1.25rem 0.25rem var(--glow),
      0 0.75rem 1.5rem rgba(0, 0, 0, 0.6);
  }

  .buzzer:disabled {
    cursor: default;
  }

  .buzzer:disabled:not(.latched) .dome {
    filter: grayscale(0.6) brightness(0.6);
  }

  .red {
    --hi: #ffb3bd;
    --base: var(--red-500);
    --lo: var(--red-600);
    --rim: var(--red-800);
    --glow: rgba(238, 27, 58, 0.7);
  }

  .blue {
    --hi: #cde8ff;
    --base: var(--blue-500);
    --lo: var(--blue-600);
    --rim: var(--blue-800);
    --glow: rgba(31, 123, 255, 0.7);
  }
</style>
