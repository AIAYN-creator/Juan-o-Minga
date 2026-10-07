<!--
  Dev-only showroom for the design system (#/kit). Not included in production
  builds. Every signature component, wired up so it can be tried by hand.
-->
<script lang="ts">
  import { celebrate } from '../lib/fx/confetti'
  import { motion } from '../lib/motion.svelte'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Buzzer from '../lib/ui/Buzzer.svelte'
  import Marquee from '../lib/ui/Marquee.svelte'
  import NeonLogo from '../lib/ui/NeonLogo.svelte'
  import Panel from '../lib/ui/Panel.svelte'
  import ProgressBulbs, { type BulbState } from '../lib/ui/ProgressBulbs.svelte'
  import Reel, { type ReelItem } from '../lib/ui/Reel.svelte'
  import RollingNumber from '../lib/ui/RollingNumber.svelte'
  import SnitchCard from '../lib/ui/SnitchCard.svelte'
  import StageScreen from '../lib/ui/StageScreen.svelte'

  const sides: ReelItem[] = [
    { label: 'AVOREM', tone: 'red' },
    { label: 'PEÑISTA', tone: 'blue' },
  ]
  const marks: ReelItem[] = [
    { label: '✓', tone: 'green' },
    { label: '✗', tone: 'alarm' },
  ]
  const phrases = [
    'Yo es que el pasodoble lo toco mejor con dos cubatas',
    '¿Alguien ha visto mi trompeta? La dejé en la barra',
    'Esta noche no bebo, que mañana madrugo',
  ]

  let round = $state(0)
  let bulbs = $state<BulbState[]>(['current', 'off', 'off'])
  let choice = $state<number | null>(null)
  let spinning = $state(false)
  let target = $state<number | null>(null)
  let verdict = $state<'right' | 'wrong' | null>(null)
  let shaking = $state(false)
  let finalTargets = $state<(number | null)[]>([null, null, null])
  let stats = $state({ pct: 0, days: 0, streak: 0 })

  function press(side: number) {
    if (choice !== null) return
    choice = side
    spinning = true
    // Fake server latency, then the answer.
    setTimeout(() => (target = Math.random() < 0.5 ? 0 : 1), 250)
  }

  function landed(side: number) {
    spinning = false
    const ok = side === choice
    verdict = ok ? 'right' : 'wrong'
    bulbs[round] = ok ? 'right' : 'wrong'
    if (ok) celebrate()
    else shaking = true
  }

  function next() {
    round = (round + 1) % 3
    if (round === 0) bulbs = ['current', 'off', 'off']
    else bulbs[round] = 'current'
    choice = null
    target = null
    verdict = null
  }

  function spinFinal() {
    finalTargets = [null, null, null]
    setTimeout(() => (finalTargets = [0, 1, 0]), 50)
  }
</script>

<main class="page kit" class:fx-shake={shaking} onanimationend={() => (shaking = false)}>
  <p class="note">
    Kit de diseño (solo en desarrollo) ·
    <label><input type="checkbox" bind:checked={motion.reduced} /> movimiento reducido (JS)</label>
  </p>

  <Marquee>
    <div class="intro">
      <NeonLogo />
      <p class="tagline">¿Lo dijo uno de la charanga o un peñista?</p>
      <ArcadeButton size="xl" onclick={() => celebrate()}>Jugar</ArcadeButton>
    </div>
  </Marquee>

  <section class="game">
    <ProgressBulbs states={bulbs} />
    <StageScreen caption="FRASE {round + 1} DE 3" text={phrases[round]} />

    <div class="buzzers">
      <Buzzer label="AVOREM" variant="red" latched={choice === 0} disabled={choice !== null} onclick={() => press(0)} />
      <Buzzer label="PEÑISTA" variant="blue" latched={choice === 1} disabled={choice !== null} onclick={() => press(1)} />
    </div>

    {#if choice !== null}
      <div class="reveal">
        <Reel items={sides} {spinning} {target} onlanded={landed} size="lg" ariaLabel="Lo dijo" />
        {#if verdict}
          <p class="verdict fx-pop-in {verdict}" role="status">
            {verdict === 'right' ? '¡CORRECTO!' : '¡INCORRECTO!'}
          </p>
          <p class="who">Esto lo dijo <strong>un peñista</strong> — en la verbena de 2019</p>
          <ArcadeButton variant="green" size="lg" block onclick={next}>Siguiente</ArcadeButton>
        {/if}
      </div>
    {/if}
  </section>

  {#if verdict === 'wrong'}<div class="red-flash" aria-hidden="true"></div>{/if}

  <Panel title="Marcador final">
    <div class="final">
      {#each finalTargets as t, i (i)}
        <Reel items={marks} target={t} size="sm" ariaLabel="Frase {i + 1}" />
      {/each}
    </div>
    <p class="score gold-text">2 DE 3</p>
    <ArcadeButton variant="gold" block onclick={spinFinal}>Girar marcador</ArcadeButton>
  </Panel>

  <Panel title="Estadísticas">
    <dl class="stats">
      <div><dt>Aciertos</dt><dd><RollingNumber value={stats.pct} minDigits={2} suffix="%" tone="green" /></dd></div>
      <div><dt>Días</dt><dd><RollingNumber value={stats.days} minDigits={2} /></dd></div>
      <div><dt>Racha</dt><dd><RollingNumber value={stats.streak} tone="cyan" /></dd></div>
    </dl>
    <ArcadeButton
      variant="blue"
      block
      onclick={() => (stats = { pct: Math.round(Math.random() * 100), days: Math.round(Math.random() * 60), streak: Math.round(Math.random() * 12) })}
    >
      Cambiar números
    </ArcadeButton>
  </Panel>

  <SnitchCard shields={0} progress={1} />
  <SnitchCard shields={2} progress={0} />

  <Panel title="Botones">
    <div class="buttons">
      <ArcadeButton variant="gold">Compartir</ArcadeButton>
      <ArcadeButton variant="red">Ranking</ArcadeButton>
      <ArcadeButton variant="blue">Buzón</ArcadeButton>
      <ArcadeButton variant="green">Siguiente</ArcadeButton>
      <ArcadeButton disabled>Desactivado</ArcadeButton>
    </div>
  </Panel>
</main>

<style>
  .kit {
    display: grid;
    gap: var(--space-6);
  }

  .note {
    font-size: var(--text-xs);
    color: var(--ink-mute);
    text-align: center;
  }

  .intro {
    display: grid;
    justify-items: center;
    gap: var(--space-4);
    padding: var(--space-6) var(--space-4) var(--space-6);
  }

  .tagline {
    font-weight: 600;
    color: var(--ink-dim);
    text-align: center;
  }

  .game {
    display: grid;
    gap: var(--space-6);
  }

  .buzzers {
    display: flex;
    justify-content: space-around;
    gap: var(--space-3);
  }

  .reveal {
    display: grid;
    gap: var(--space-4);
    text-align: center;
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

  .red-flash {
    position: fixed;
    inset: 0;
    pointer-events: none;
    background: radial-gradient(ellipse at center, rgba(255, 43, 43, 0.1), rgba(255, 43, 43, 0.45));
    animation: flash 520ms ease-out forwards;
    z-index: 900;
  }

  @keyframes flash {
    0%, 40% { opacity: 1; }
    20%, 60% { opacity: 0.3; }
    100% { opacity: 0; }
  }

  .final {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-3);
    margin-bottom: var(--space-4);
  }

  .score {
    margin-bottom: var(--space-4);
    font-family: var(--font-display);
    font-size: var(--text-xl);
    text-align: center;
  }

  .stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-3);
    margin: 0 0 var(--space-5);
    text-align: center;
  }

  .stats dt {
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .stats dd {
    margin: var(--space-2) 0 0;
    font-size: 2rem;
  }

  .buttons {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: var(--space-5) var(--space-3);
    padding-bottom: var(--space-2);
  }
</style>
