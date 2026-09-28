<!--
  Slot-machine reel. `spinning` starts a free spin (e.g. while the server
  answers); setting `target` decelerates and lands on items[target] with a
  small bounce, then calls onlanded. Set target directly to spin-and-land in
  one go. Reduced motion: jumps straight to the result.
-->
<script lang="ts" module>
  export type ReelItem = { label: string; tone?: 'red' | 'blue' | 'green' | 'alarm' | 'gold' }
</script>

<script lang="ts">
  import { onDestroy, untrack } from 'svelte'
  import { motion } from '../motion.svelte'

  let {
    items,
    spinning = false,
    target = null,
    onlanded,
    size = 'md',
    ariaLabel = 'Rodillo',
  }: {
    items: ReelItem[]
    spinning?: boolean
    target?: number | null
    onlanded?: (index: number) => void
    size?: 'sm' | 'md' | 'lg'
    ariaLabel?: string
  } = $props()

  const SPIN_SPEED = 20 // items per second

  // Position in item units: item k sits centred in the window when pos === k.
  let pos = $state(0)
  let speed = $state(0)
  let landed = $state<number | null>(null)

  let mode: 'idle' | 'spin' | 'land' = 'idle'
  let raf = 0
  let lastT = 0
  let landFrom = 0
  let landTo = 0
  let landStart = 0
  let landDur = 0
  let landIndex = 0

  const mod = (a: number, n: number) => ((a % n) + n) % n

  function easeOutBack(u: number): number {
    const c1 = 1.3
    const c3 = c1 + 1
    return 1 + c3 * (u - 1) ** 3 + c1 * (u - 1) ** 2
  }

  function frame(t: number) {
    const dt = lastT ? (t - lastT) / 1000 : 0
    lastT = t
    if (mode === 'spin') {
      pos += SPIN_SPEED * dt
      speed = SPIN_SPEED
    } else if (mode === 'land') {
      const u = Math.min(1, (t - landStart) / landDur)
      const prev = pos
      pos = landFrom + (landTo - landFrom) * easeOutBack(u)
      speed = dt ? Math.abs(pos - prev) / dt : speed
      if (u >= 1) {
        finish()
        return
      }
    }
    raf = requestAnimationFrame(frame)
  }

  function run() {
    if (raf) return
    lastT = 0
    raf = requestAnimationFrame(frame)
  }

  function finish() {
    cancelAnimationFrame(raf)
    raf = 0
    mode = 'idle'
    pos = landTo
    speed = 0
    landed = landIndex
    onlanded?.(landIndex)
  }

  function land(index: number) {
    const n = items.length
    landIndex = index
    if (motion.reduced) {
      landTo = mod(index, n)
      finish()
      return
    }
    // Travel far enough to read as a spin, then stop exactly on the target.
    const minTravel = mode === 'spin' ? 3 : 2 * n + 2
    let to = Math.ceil(pos + minTravel)
    to += mod(index - to, n)
    landFrom = pos
    landTo = to
    landStart = performance.now()
    landDur = Math.min(1000, Math.max(520, ((4.3 * (to - pos)) / SPIN_SPEED) * 1000))
    mode = 'land'
    run()
  }

  $effect(() => {
    const t = target
    const s = spinning
    untrack(() => {
      if (t !== null && t !== landed && mode !== 'land') {
        land(t)
      } else if (s && t === null && mode === 'idle' && !motion.reduced) {
        landed = null
        mode = 'spin'
        run()
      }
    })
  })

  onDestroy(() => cancelAnimationFrame(raf))

  const visible = $derived.by(() => {
    const base = Math.floor(pos)
    return [base - 1, base, base + 1, base + 2]
  })

  const blur = $derived(Math.min(3, speed / 7))
  const landedItem = $derived(landed === null ? null : items[mod(landed, items.length)])
</script>

<div class="reel {size}" role="img" aria-label={landedItem ? `${ariaLabel}: ${landedItem.label}` : ariaLabel}>
  <div class="window">
    <div class="strip" style:filter={blur > 0.2 ? `blur(${blur}px)` : undefined}>
      {#if motion.reduced && spinning && landed === null}
        <!-- No spin to hide behind: never show a symbol that isn't the result -->
        <span class="item gold">?</span>
      {:else}
        {#each visible as k (k)}
          {@const item = items[mod(k, items.length)]}
          <span class="item {item.tone ?? 'gold'}" style:transform="translateY({(k - pos) * 100}%)">
            {item.label}
          </span>
        {/each}
      {/if}
    </div>
    <span class="payline" aria-hidden="true"></span>
  </div>
  <span class="sr-only" aria-live="polite">{landedItem?.label ?? ''}</span>
</div>

<style>
  .reel {
    --h: 4.25rem;
    padding: 0.35rem;
    border-radius: var(--radius-md);
    background: var(--gold-bezel);
    box-shadow:
      inset 0 1px 0 rgba(255, 241, 184, 0.8),
      0 0.5rem 1.25rem rgba(0, 0, 0, 0.55);
  }

  .sm {
    --h: 2.75rem;
    padding: 0.25rem;
  }

  .lg {
    --h: 5.5rem;
  }

  .window {
    position: relative;
    height: var(--h);
    overflow: hidden;
    border-radius: calc(var(--radius-md) - 0.3rem);
    background: linear-gradient(180deg, #d9d0c0 0%, #fffdf6 30%, #fffdf6 70%, #d9d0c0 100%);
    box-shadow: inset 0 0 0 2px rgba(59, 29, 0, 0.6);
  }

  /* Cylinder shading over the strip */
  .window::after {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(
      180deg,
      rgba(20, 5, 0, 0.55) 0%,
      rgba(20, 5, 0, 0) 28%,
      rgba(20, 5, 0, 0) 72%,
      rgba(20, 5, 0, 0.55) 100%
    );
    pointer-events: none;
  }

  .strip {
    position: absolute;
    inset: 0;
  }

  .item {
    position: absolute;
    inset: 0;
    display: grid;
    place-items: center;
    font-family: var(--font-display);
    font-size: calc(var(--h) * 0.36);
    line-height: 1;
    letter-spacing: 0.02em;
    white-space: nowrap;
    will-change: transform;
  }

  .sm .item {
    font-size: calc(var(--h) * 0.5);
  }

  .item.gold { color: var(--gold-800); }
  .item.red { color: var(--red-600); }
  .item.blue { color: var(--blue-600); }
  .item.green { color: var(--felt-600); }
  .item.alarm { color: #d10f0f; }

  /* ✓ / ✗ come from a fallback font: thicken them to match Bungee's weight */
  .item.green,
  .item.alarm {
    -webkit-text-stroke: 0.07em currentColor;
  }

  .payline {
    position: absolute;
    inset: 50% 0 auto;
    height: 2px;
    margin-top: -1px;
    background: linear-gradient(90deg, transparent, rgba(238, 27, 58, 0.35) 15%, rgba(238, 27, 58, 0.35) 85%, transparent);
    pointer-events: none;
    z-index: 1;
  }
</style>
