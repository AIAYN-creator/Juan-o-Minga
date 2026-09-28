<!--
  JUAN O MINGA in neon tubes: two cyan words, a magenta "o" in between,
  one letter that flickers like a tired sign. Reduced motion: no flicker.
-->
<script lang="ts">
  let { size = 'lg' }: { size?: 'md' | 'lg' } = $props()
</script>

<h1 class="logo {size}" aria-label="Juan o Minga">
  <span class="word" aria-hidden="true">JUAN</span>
  <span class="o" aria-hidden="true">o</span>
  <span class="word" aria-hidden="true">MIN<span class="flicker">G</span>A</span>
</h1>

<style>
  .logo {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.02em;
    margin: 0;
    font-family: var(--font-neon);
    font-weight: 400;
    line-height: 0.92;
    text-align: center;
    user-select: none;
  }

  .lg {
    font-size: clamp(2.75rem, 14vw, 5rem);
  }

  .md {
    font-size: clamp(2rem, 10vw, 3rem);
  }

  .word {
    color: #e6feff;
    letter-spacing: 0.04em;
    text-shadow:
      0 0 2px #fff,
      0 0 0.08em var(--neon-cyan),
      0 0 0.2em var(--neon-cyan),
      0 0 0.45em rgba(47, 243, 255, 0.6),
      0 0 0.9em rgba(47, 243, 255, 0.35);
  }

  .o {
    font-family: var(--font-display);
    font-size: 0.5em;
    line-height: 1;
    color: #ffe6fa;
    transform: rotate(-8deg);
    text-shadow:
      0 0 2px #fff,
      0 0 0.12em var(--neon-magenta),
      0 0 0.3em var(--neon-magenta),
      0 0 0.7em rgba(255, 47, 214, 0.5);
  }

  .flicker {
    animation: flicker 4.2s linear infinite;
  }

  @keyframes flicker {
    0%, 18%, 22%, 25%, 53%, 57%, 100% {
      opacity: 1;
    }
    20%, 24%, 55% {
      opacity: 0.25;
      text-shadow: none;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .flicker {
      animation: none;
    }
  }
</style>
