<!--
  Casino marquee: a gold frame lined with light bulbs that chase around the edge.
  Bulbs are laid out from the frame's measured size, so it works at any width.
  Reduced motion: all bulbs stay lit, no chase.
-->
<script lang="ts">
  import type { Snippet } from 'svelte'
  import { motion } from '../motion.svelte'

  let {
    children,
    spacing = 22,
    band = 22,
    chase = true,
  }: {
    children: Snippet
    /** Target distance between bulb centres, in px. */
    spacing?: number
    /** Width of the gold band that holds the bulbs, in px. */
    band?: number
    /** Chase animation on/off (e.g. off for a calmer frame). */
    chase?: boolean
  } = $props()

  let width = $state(0)
  let height = $state(0)

  // Bulb centres, walking clockwise along a rectangle centred in the band.
  // Each edge is split evenly on its own, so every corner gets a bulb.
  const bulbs = $derived.by(() => {
    const d = band / 2
    const w = width - 2 * d
    const h = height - 2 * d
    if (w <= 0 || h <= 0) return []
    const nw = Math.max(1, Math.round(w / spacing))
    const nh = Math.max(1, Math.round(h / spacing))
    const points: { x: number; y: number }[] = []
    for (let i = 0; i < nw; i++) points.push({ x: (i * w) / nw, y: 0 })
    for (let i = 0; i < nh; i++) points.push({ x: w, y: (i * h) / nh })
    for (let i = 0; i < nw; i++) points.push({ x: w - (i * w) / nw, y: h })
    for (let i = 0; i < nh; i++) points.push({ x: 0, y: h - (i * h) / nh })
    return points.map((p) => ({ x: p.x + d, y: p.y + d }))
  })

  const animated = $derived(chase && !motion.reduced)
</script>

<div
  class="marquee"
  class:animated
  style:--band="{band}px"
  bind:clientWidth={width}
  bind:clientHeight={height}
>
  {#each bulbs as bulb, i (i)}
    <span class="bulb" style:left="{bulb.x}px" style:top="{bulb.y}px" style:--phase={i % 3}></span>
  {/each}
  <div class="inner">
    {@render children()}
  </div>
</div>

<style>
  .marquee {
    position: relative;
    padding: var(--band);
    border-radius: var(--radius-lg);
    background: var(--gold-bezel);
    box-shadow:
      inset 0 0 0 2px rgba(255, 241, 184, 0.7),
      inset 0 0 0 4px rgba(122, 74, 6, 0.6),
      0 0.75rem 2rem rgba(0, 0, 0, 0.6),
      var(--glow-gold);
  }

  .inner {
    position: relative;
    border-radius: calc(var(--radius-lg) - 0.5rem);
    background:
      radial-gradient(ellipse at 50% 0%, rgba(255, 216, 102, 0.12), transparent 60%),
      linear-gradient(180deg, var(--velvet-700), var(--velvet-900));
    box-shadow:
      inset 0 0 0 2px var(--gold-800),
      inset 0 0.5rem 1.5rem rgba(0, 0, 0, 0.65);
    overflow: hidden;
  }

  .bulb {
    --size: 10px;
    position: absolute;
    width: var(--size);
    height: var(--size);
    margin: calc(var(--size) / -2) 0 0 calc(var(--size) / -2);
    border-radius: 50%;
    background: radial-gradient(circle at 35% 30%, #fff 0 18%, #fff3c4 40%, #ffc93c 75%, #c98a10 100%);
    box-shadow:
      0 0 0 1.5px rgba(59, 29, 0, 0.55),
      0 0 6px 2px rgba(255, 226, 138, 0.9),
      0 0 14px 4px rgba(255, 200, 60, 0.45);
    pointer-events: none;
  }

  .animated .bulb {
    animation: chase 780ms steps(1, end) infinite;
    animation-delay: calc(var(--phase) * -260ms);
  }

  /* One lit, two dimmed, shifting every 260ms: the classic chase */
  @keyframes chase {
    0% {
      background: radial-gradient(circle at 35% 30%, #fff 0 18%, #fff3c4 40%, #ffc93c 75%, #c98a10 100%);
      box-shadow:
        0 0 0 1.5px rgba(59, 29, 0, 0.55),
        0 0 6px 2px rgba(255, 226, 138, 0.9),
        0 0 14px 4px rgba(255, 200, 60, 0.45);
    }
    33.333% {
      background: radial-gradient(circle at 35% 30%, #d9a55a 0 15%, #8a5412 60%, #4a2a04 100%);
      box-shadow: 0 0 0 1.5px rgba(59, 29, 0, 0.55);
    }
  }
</style>
