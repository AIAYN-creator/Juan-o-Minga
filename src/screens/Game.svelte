<!--
  The game: today's phrase on the studio screen, two giant buzzers, 3 progress
  bulbs. Pressing a buzzer locks the answer in: the slot reel spins while the
  server judges it, lands on AVOREM or PEÑISTA, then the sign says ¡CORRECTO!
  (coins) or ¡INCORRECTO! (red flash + shake) with who said it and when.
  Resumes wherever the player left off.
-->
<script lang="ts">
  import { celebrate } from '../lib/fx/confetti'
  import { href, navigate } from '../lib/router.svelte'
  import { round, type Side } from '../lib/round.svelte'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Buzzer from '../lib/ui/Buzzer.svelte'
  import ProgressBulbs, { type BulbState } from '../lib/ui/ProgressBulbs.svelte'
  import Reel, { type ReelItem } from '../lib/ui/Reel.svelte'
  import StageScreen from '../lib/ui/StageScreen.svelte'

  const sides: ReelItem[] = [
    { label: 'AVOREM', tone: 'red' },
    { label: 'PEÑISTA', tone: 'blue' },
  ]
  const sideIndex: Record<Side, number> = { charanga: 0, penista: 1 }

  type Phase = 'ask' | 'spinning' | 'revealed'

  let phase = $state<Phase>('ask')
  /** Position on screen. Stays put during the reveal; SIGUIENTE moves it on. */
  let position = $state<number | null>(null)
  let choice = $state<Side | null>(null)
  let target = $state<number | null>(null)
  let landed = $state(false)
  let error = $state<string | null>(null)
  let shaking = $state(false)
  let flash = $state(false)
  let nextButton = $state<HTMLElement | null>(null)

  if (round.status === 'idle' || round.status === 'error') void round.load()

  // Pick up where the player left off (and after a reload triggered by an error).
  $effect(() => {
    if (round.status !== 'ready' || phase !== 'ask') return
    if (round.finished && position === null) navigate('/resultado')
    else if (position === null || round.rows.find((r) => r.position === position)?.answered)
      position = round.current?.position ?? null
  })

  const row = $derived(round.rows.find((r) => r.position === position) ?? null)
  const isLast = $derived(round.rows.filter((r) => !r.answered).length === 0)

  const bulbs = $derived<BulbState[]>(
    round.rows.map((r) =>
      r.answered && !(r.position === position && phase !== 'revealed')
        ? r.is_correct
          ? 'right'
          : 'wrong'
        : r.position === position
          ? 'current'
          : 'off',
    ),
  )

  async function press(side: Side) {
    if (phase !== 'ask' || !row) return
    error = null
    choice = side
    phase = 'spinning'
    target = null
    landed = false
    const failure = await round.submit(row.position, side)
    if (failure) {
      error = failure
      phase = 'ask'
      choice = null
      return
    }
    target = sideIndex[row.side as Side]
  }

  function onLanded() {
    landed = true
    phase = 'revealed'
    if (row?.is_correct) {
      celebrate()
    } else {
      shaking = true
      flash = true
      setTimeout(() => (flash = false), 600)
    }
    setTimeout(() => nextButton?.querySelector('button')?.focus(), 50)
  }

  function next() {
    phase = 'ask'
    choice = null
    target = null
    landed = false
    if (isLast) {
      navigate('/resultado')
      return
    }
    position = round.current?.position ?? null
  }
</script>

<main class="page game" class:fx-shake={shaking} onanimationend={() => (shaking = false)} inert={phase !== 'ask'}>
  <h1 class="sr-only">Juan o Minga{round.number ? ` #${round.number}` : ''}: ¿quién lo dijo?</h1>
  <header class="top">
    <a class="back" href={href('/')}>‹ Plató</a>
    {#if round.number}<p class="num led">#{round.number}</p>{/if}
  </header>

  {#if round.status === 'loading' && !row}
    <p class="note" aria-busy="true">Calentando los rodillos…</p>
  {:else if round.status === 'error'}
    <p class="note error" role="alert">{round.error}</p>
    <ArcadeButton onclick={() => round.load()}>Reintentar</ArcadeButton>
  {:else if row}
    <ProgressBulbs states={bulbs} />

    <StageScreen caption="FRASE {row.position} DE 3" text={row.text} />

    <p class="question">¿Quién lo dijo?</p>

    <div class="buzzers">
      <Buzzer
        label="AVOREM"
        variant="red"
        latched={choice === 'charanga'}
        disabled={phase !== 'ask'}
        onclick={() => press('charanga')}
      />
      <Buzzer
        label="PEÑISTA"
        variant="blue"
        latched={choice === 'penista'}
        disabled={phase !== 'ask'}
        onclick={() => press('penista')}
      />
    </div>

    {#if error}<p class="note error" role="alert">{error}</p>{/if}
  {/if}
</main>

{#if phase !== 'ask' && row}
  <div class="sheet-backdrop">
    <div class="sheet" role="dialog" aria-modal="true" aria-labelledby="reveal-title">
      <h2 id="reveal-title" class="sr-only">Resultado de la frase {row.position}</h2>
      <p class="sheet-kicker">Lo dijo…</p>
      <Reel items={sides} spinning={phase === 'spinning'} {target} onlanded={onLanded} size="lg" ariaLabel="Lo dijo" />

      {#if landed}
        <p class="verdict fx-pop-in" class:right={row.is_correct} class:wrong={!row.is_correct} role="status">
          <span aria-hidden="true">{row.is_correct ? '✓' : '✗'}</span>
          {row.is_correct ? '¡CORRECTO!' : '¡INCORRECTO!'}
        </p>
        <p class="who">
          Esto lo dijo <strong>{row.author_display}</strong>
          {#if row.context}<span class="ctx"> — {row.context}</span>{/if}
        </p>
        <div bind:this={nextButton} class="next">
          <ArcadeButton variant="green" size="lg" block onclick={next}>
            {isLast ? 'Ver resultado' : 'Siguiente'}
          </ArcadeButton>
        </div>
      {/if}
    </div>
  </div>
{/if}

{#if flash}<div class="red-flash" aria-hidden="true"></div>{/if}

<style>
  .game {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-5);
    padding-top: var(--space-3);
  }

  .top {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .back {
    font-weight: 600;
    text-decoration: none;
  }

  .num {
    font-size: 1.25rem;
    color: var(--gold-300);
    text-shadow: 0 0 0.3em rgba(255, 216, 102, 0.6);
  }

  .note {
    text-align: center;
    color: var(--ink-dim);
  }

  .error {
    font-weight: 600;
    color: var(--red-300);
  }

  .question {
    margin-bottom: calc(-1 * var(--space-2));
    font-family: var(--font-display);
    font-size: var(--text-lg);
    text-align: center;
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  .buzzers {
    display: flex;
    justify-content: space-around;
    gap: var(--space-3);
  }

  /* ---- Reveal sheet ---- */
  .sheet-backdrop {
    position: fixed;
    inset: 0;
    z-index: 800;
    display: grid;
    align-items: end;
    justify-items: center;
    padding: var(--gutter);
    background: rgba(15, 1, 7, 0.55);
    animation: fade-in var(--dur-fast) ease-out;
  }

  .sheet {
    display: grid;
    gap: var(--space-4);
    width: min(100%, var(--content-max));
    padding: var(--space-5) var(--space-4);
    border-radius: var(--radius-lg);
    text-align: center;
    background:
      radial-gradient(ellipse at 50% 0%, rgba(255, 216, 102, 0.16), transparent 55%),
      linear-gradient(180deg, var(--velvet-700), var(--velvet-900));
    box-shadow:
      inset 0 0 0 2px var(--gold-500),
      inset 0 0 0 6px var(--velvet-900),
      inset 0 0 0 7px rgba(240, 180, 41, 0.4),
      0 -0.5rem 3rem rgba(0, 0, 0, 0.7);
    animation: slide-up var(--dur-base) var(--ease-out);
  }

  .sheet-kicker {
    font-family: var(--font-display);
    font-size: var(--text-sm);
    letter-spacing: 0.1em;
    color: var(--ink-dim);
  }

  .verdict {
    font-family: var(--font-display);
    font-size: var(--text-2xl);
    line-height: 1;
  }

  .verdict.right {
    color: #eafff2;
    text-shadow: var(--glow-green), 0 3px 0 var(--felt-800);
  }

  .verdict.wrong {
    color: #fff0f0;
    text-shadow: var(--glow-alarm), 0 3px 0 #5a0000;
  }

  .who {
    color: var(--ink-dim);
  }

  .who strong {
    color: var(--ink);
  }

  .next {
    outline: none;
  }

  .red-flash {
    position: fixed;
    inset: 0;
    z-index: 900;
    pointer-events: none;
    background: radial-gradient(ellipse at center, rgba(255, 43, 43, 0.1), rgba(255, 43, 43, 0.5));
    animation: flash 560ms ease-out forwards;
  }

  @keyframes flash {
    0%, 40% { opacity: 1; }
    20%, 60% { opacity: 0.3; }
    100% { opacity: 0; }
  }

  @keyframes slide-up {
    from { transform: translateY(40%); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }
</style>
