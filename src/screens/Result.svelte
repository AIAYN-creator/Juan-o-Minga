<!--
  Final score, slot-machine style: three big reels land one after another on
  ✓ or ✗, then the verdict (jackpot coins on a PLENO), COMPARTIR, the nudge to
  the suggestion box (with the streak-shield progress), the countdown to the
  next round and the player's own stats.
-->
<script lang="ts">
  import { celebrate } from '../lib/fx/confetti'
  import { href, navigate } from '../lib/router.svelte'
  import { round, verdictFor } from '../lib/round.svelte'
  import { shareResult, shareText } from '../lib/share'
  import { supabase } from '../lib/supabase'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Countdown from '../lib/ui/Countdown.svelte'
  import Marquee from '../lib/ui/Marquee.svelte'
  import Panel from '../lib/ui/Panel.svelte'
  import Reel, { type ReelItem } from '../lib/ui/Reel.svelte'
  import RollingNumber from '../lib/ui/RollingNumber.svelte'
  import SnitchCard from '../lib/ui/SnitchCard.svelte'

  type Stats = {
    days_played: number
    correct: number
    answered: number
    pct: number | null
    current_streak: number
    best_streak: number
    perfect_days: number
    dist_0: number
    dist_1: number
    dist_2: number
    dist_3: number
    approved_phrases: number
    top_contributor: boolean
    shields: number
    shield_progress: number
    shield_saved_today: boolean
  }

  const marks: ReelItem[] = [
    { label: '✓', tone: 'green' },
    { label: '✗', tone: 'alarm' },
  ]

  let targets = $state<(number | null)[]>([null, null, null])
  let landedCount = $state(0)
  let toast = $state<string | null>(null)
  let stats = $state<Stats | null>(null)
  let started = false

  if (round.status === 'idle' || round.status === 'error') void round.load()

  // Only a finished day has a result. Otherwise, back to the game.
  $effect(() => {
    if (round.status !== 'ready') return
    if (!round.finished) {
      navigate('/jugar')
      return
    }
    if (started) return
    started = true
    // Reels land one after another, like a real machine.
    round.rows.forEach((r, i) => setTimeout(() => (targets[i] = r.is_correct ? 0 : 1), 250 + i * 380))
    void loadStats()
  })

  async function loadStats() {
    const { data } = await supabase.rpc('get_my_stats').single()
    if (data) stats = data as Stats
  }

  function onLanded() {
    landedCount++
    if (landedCount === 3 && round.correct === 3) celebrate()
  }

  const done = $derived(landedCount === 3)
  const results = $derived(round.rows.map((r) => Boolean(r.is_correct)))
  const text = $derived(round.number ? shareText(round.number, results) : '')

  const dist = $derived(
    stats ? [stats.dist_0, stats.dist_1, stats.dist_2, stats.dist_3] : [0, 0, 0, 0],
  )
  const distMax = $derived(Math.max(1, ...dist))

  const shieldIcons = (n: number) => '🛡️'.repeat(n)
  const shieldLeft = (n: number) => (n === 0 ? 'No te quedan más.' : n === 1 ? 'Te queda 1.' : `Te quedan ${n}.`)

  async function share() {
    const outcome = await shareResult(text)
    toast =
      outcome === 'copied'
        ? '¡Copiado! Pégalo en el grupo.'
        : outcome === 'failed'
          ? 'No se ha podido copiar. Mantén pulsado el texto de abajo.'
          : null
    if (toast) setTimeout(() => (toast = null), 2600)
  }
</script>

<main class="page result">
  <h1 class="kicker">Juan o Minga #{round.number ?? ''}</h1>

  <Marquee band={18} spacing={20}>
    <div class="machine">
      <div class="reels">
        {#each [0, 1, 2] as i (i)}
          <Reel
            items={marks}
            spinning={targets[i] === null}
            target={targets[i]}
            onlanded={onLanded}
            size="lg"
            ariaLabel="Frase {i + 1}"
          />
        {/each}
      </div>
      <p class="score" class:show={done}>
        <span class="led big">{round.correct}/3</span>
        <span class="verdict gold-text">{verdictFor(round.correct)}</span>
      </p>
    </div>
  </Marquee>

  <div class="share">
    <ArcadeButton size="xl" block onclick={share} disabled={!text}>Compartir</ArcadeButton>
    <pre class="preview" aria-label="Texto para compartir">{text}</pre>
    {#if toast}<p class="toast fx-pop-in" role="status">{toast}</p>{/if}
  </div>

  {#if stats?.shield_saved_today}
    <p class="saved fx-pop-in" role="status">
      🛡️ Tu protector ha salvado tu racha de {stats.current_streak} días. {shieldLeft(stats.shields)}
    </p>
  {/if}

  {#if stats?.top_contributor}
    <p class="megaphone fx-pop-in"><span aria-hidden="true">📣</span> Megáfono de oro: eres el mayor chivato de la peña</p>
  {/if}

  <SnitchCard shields={stats?.shields} progress={stats?.shield_progress} />

  <Countdown ondone={() => navigate('/')} />

  <Panel title="Tus números">
    {#if stats}
      <dl class="stats">
        <div><dt>Días</dt><dd><RollingNumber value={stats.days_played} /></dd></div>
        <div><dt>Aciertos</dt><dd><RollingNumber value={stats.pct ?? 0} suffix="%" tone="green" /></dd></div>
        <div><dt>Racha</dt><dd><RollingNumber value={stats.current_streak} tone="cyan" /></dd></div>
        <div><dt>Mejor racha</dt><dd><RollingNumber value={stats.best_streak} tone="cyan" /></dd></div>
        <div><dt>Plenos</dt><dd><RollingNumber value={stats.perfect_days} /></dd></div>
        <div>
          <dt>Protectores</dt>
          <dd class="shields" aria-label="{stats.shields} protectores de racha">{stats.shields ? shieldIcons(stats.shields) : '—'}</dd>
        </div>
      </dl>
      <p class="dist-title">Cómo acaban tus días</p>
      <ol class="dist">
        {#each dist as n, k (k)}
          <li class:today={k === round.correct}>
            <span class="dist-label">{k}/3</span>
            <span class="bar" style:width="{Math.max(8, (n / distMax) * 100)}%"><span class="led">{n}</span></span>
          </li>
        {/each}
      </ol>
    {:else}
      <p class="loading">Contando fichas…</p>
    {/if}
  </Panel>

  <nav class="links">
    <ArcadeButton variant="red" href={href('/ranking')}>Ranking</ArcadeButton>
    <ArcadeButton variant="gold" href={href('/')}>Plató</ArcadeButton>
  </nav>
</main>

<style>
  .result {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-5);
  }

  .kicker {
    font-family: var(--font-display);
    font-size: var(--text-sm);
    letter-spacing: 0.1em;
    text-align: center;
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  .machine {
    display: grid;
    gap: var(--space-4);
    padding: var(--space-5) var(--space-3);
  }

  .reels {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: var(--space-2);
  }

  .score {
    display: grid;
    justify-items: center;
    gap: var(--space-2);
    text-align: center;
    opacity: 0;
    transform: scale(0.8);
    transition:
      opacity var(--dur-base) ease-out,
      transform var(--dur-base) var(--ease-pop);
  }

  .score.show {
    opacity: 1;
    transform: none;
  }

  .big {
    font-size: 3rem;
    line-height: 1;
    color: var(--gold-300);
    text-shadow: 0 0 0.3em rgba(255, 216, 102, 0.75);
  }

  .verdict {
    font-family: var(--font-display);
    font-size: var(--text-lg);
  }

  .share {
    display: grid;
    justify-items: center;
    gap: var(--space-3);
  }

  .preview {
    margin: 0;
    padding: var(--space-3) var(--space-4);
    border-radius: var(--radius-md);
    background: rgba(28, 4, 13, 0.85);
    box-shadow: inset 0 0 0 1px rgba(255, 216, 102, 0.25);
    font-family: var(--font-body);
    font-size: var(--text-sm);
    line-height: 1.5;
    text-align: center;
    color: var(--ink-dim);
    white-space: pre-wrap;
    user-select: all;
  }

  .toast {
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-pill);
    background: var(--felt-600);
    box-shadow: var(--glow-green);
    font-weight: 700;
    color: #fff;
  }

  .saved,
  .megaphone {
    justify-self: center;
    padding: var(--space-2) var(--space-4);
    border-radius: var(--radius-pill);
    font-weight: 700;
    text-align: center;
  }

  .saved {
    background: rgba(47, 243, 255, 0.15);
    box-shadow: inset 0 0 0 1px rgba(47, 243, 255, 0.6), var(--glow-cyan);
    color: #e6feff;
  }

  .megaphone {
    background: var(--gold-metal);
    color: var(--ink-on-gold);
  }

  .shields {
    font-size: 1.4rem;
  }

  .stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(5.5rem, 1fr));
    gap: var(--space-4) var(--space-2);
    margin: 0 0 var(--space-5);
    text-align: center;
  }

  .stats dt {
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .stats dd {
    margin: var(--space-2) 0 0;
    font-size: 1.6rem;
  }

  .dist-title {
    margin-bottom: var(--space-2);
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .dist {
    display: grid;
    gap: var(--space-2);
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .dist li {
    display: grid;
    grid-template-columns: 2.5rem 1fr;
    align-items: center;
    gap: var(--space-2);
  }

  .dist-label {
    font-family: var(--font-display);
    font-size: var(--text-sm);
    color: var(--ink-dim);
  }

  .bar {
    display: flex;
    justify-content: flex-end;
    min-width: 1.8rem;
    padding: 0.1rem 0.45rem;
    border-radius: var(--radius-sm);
    background: rgba(255, 255, 255, 0.12);
    font-size: 0.95rem;
    transition: width var(--dur-slow) var(--ease-out);
  }

  .today .bar {
    background: linear-gradient(90deg, var(--felt-600), #19b35c);
    box-shadow: var(--glow-green);
  }

  .today .dist-label {
    color: var(--neon-green);
  }

  .loading {
    text-align: center;
    color: var(--ink-dim);
  }

  .links {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: var(--space-3);
  }
</style>
