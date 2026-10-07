<!--
  Intro: the TV-show set. Marquee with the slot-machine emblem and the neon
  logo, one giant call to action, and the way to the ranking, the suggestion
  box and the rules. If today's round is done: the day's score and a countdown.
  Before launch: a big countdown to opening night instead of the game.
  Each new release shows its what's-new panel here once per player (profile)
  or per browser (no session); never during a game.
-->
<script lang="ts">
  import mark from '../../brand/mark.svg'
  import { href } from '../lib/router.svelte'
  import { launch } from '../lib/launch.svelte'
  import { round, verdictFor } from '../lib/round.svelte'
  import { session } from '../lib/session.svelte'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Countdown from '../lib/ui/Countdown.svelte'
  import HowToPlay from '../lib/ui/HowToPlay.svelte'
  import LaunchCountdown from '../lib/ui/LaunchCountdown.svelte'
  import Marquee from '../lib/ui/Marquee.svelte'
  import NeonLogo from '../lib/ui/NeonLogo.svelte'
  import WhatsNew from '../lib/ui/WhatsNew.svelte'
  import { isNewer, latest, localSeen, rememberSeen } from '../lib/news'
  import Reel, { type ReelItem } from '../lib/ui/Reel.svelte'

  const marks: ReelItem[] = [
    { label: '✓', tone: 'green' },
    { label: '✗', tone: 'alarm' },
  ]

  let howTo: HowToPlay
  let whatsNew: WhatsNew
  let newsChecked = false

  // What's new, once per version: the profile remembers it across devices, the
  // browser remembers it without a session (and hands it to the profile on login).
  $effect(() => {
    const status = session.status
    if (newsChecked || !whatsNew || (status !== 'anon' && status !== 'ready')) return
    newsChecked = true
    const local = localSeen()
    let seen = local
    if (status === 'ready' && session.profile) {
      const remote = session.profile.news_seen
      if (local && isNewer(local, remote)) void session.markNewsSeen(local)
      else seen = remote
    }
    if (!isNewer(latest.version, seen)) return
    whatsNew.open()
    rememberSeen(latest.version)
    if (status === 'ready') void session.markNewsSeen(latest.version)
  })

  void launch.load()

  const prelaunch = $derived(launch.open === false)

  // Once the game is open and the player is known, load today's round to know
  // if they already played. Also fires when the countdown reaches zero.
  $effect(() => {
    if (session.status === 'ready' && launch.open && round.status === 'idle') void round.load()
    if (session.status === 'anon' && round.status !== 'idle') round.reset()
  })

  const cta = $derived.by(() => {
    if (session.status !== 'ready') return null
    if (round.finished) return null
    return round.answered > 0 ? 'Continuar' : 'Jugar'
  })

  const verdict = $derived(verdictFor(round.correct))
</script>

<main class="page intro">
  <Marquee>
    <div class="stage">
      <img class="emblem" src={mark} alt="" width="180" height="180" />
      <NeonLogo />
      <p class="tagline">¿Lo dijo uno de la charanga o un peñista?</p>

      {#if prelaunch && launch.at}
        <LaunchCountdown ms={launch.msLeft} at={launch.at} />
        {#if session.status === 'anon'}
          <ArcadeButton size="lg" block onclick={() => session.signIn()}>Reserva tu apodo</ArcadeButton>
          <p class="fine">Entra con Google y elige ya el apodo que saldrá en el ranking. Nunca se verá tu cuenta.</p>
        {:else if session.profile}
          <p class="fine">Apodo reservado: <strong class="nick">{session.profile.nickname}</strong>. Nos vemos en el estreno.</p>
        {/if}
      {:else if session.status === 'anon'}
        <ArcadeButton size="lg" block onclick={() => session.signIn()}>Entrar con Google</ArcadeButton>
        <p class="fine">Solo para saber quién eres. En el ranking saldrá el apodo que elijas, nunca tu cuenta.</p>
      {:else if launch.open === null}
        <p class="fine" aria-busy="true">Calentando los rodillos…</p>
      {:else if cta}
        <ArcadeButton size="xl" href={href('/jugar')}>{cta}</ArcadeButton>
        {#if round.number}<p class="fine">Juan o Minga #{round.number}</p>{/if}
      {:else if round.finished}
        <div class="done">
          <p class="kicker">Tu marcador de hoy · #{round.number}</p>
          <div class="reels">
            {#each round.rows as row (row.position)}
              <Reel items={marks} target={row.is_correct ? 0 : 1} size="sm" ariaLabel="Frase {row.position}" />
            {/each}
          </div>
          <p class="verdict gold-text">{verdict}</p>
          <ArcadeButton variant="green" href={href('/resultado')}>Ver resultado</ArcadeButton>
          <Countdown ondone={() => round.load()} />
        </div>
      {:else if round.status === 'error'}
        <p class="error" role="alert">{round.error}</p>
      {:else}
        <p class="fine" aria-busy="true">Calentando los rodillos…</p>
      {/if}

      {#if session.error}<p class="error" role="alert">{session.error}</p>{/if}
    </div>
  </Marquee>

  <nav class="links" aria-label="Más">
    <ArcadeButton variant="red" href={href('/ranking')}>Ranking</ArcadeButton>
    {#if session.status === 'ready'}
      <ArcadeButton variant="blue" href={href('/buzon')}>Buzón</ArcadeButton>
    {/if}
    <ArcadeButton variant="gold" onclick={() => howTo.open()}>¿Cómo se juega?</ArcadeButton>
  </nav>

  <p class="legal">
    <a href={href('/novedades')}>Novedades · v{latest.version}</a> · <a href="privacidad.html">Privacidad</a>
  </p>

  {#if session.status === 'ready'}
    <p class="who">
      Concursante: <strong>{session.profile?.nickname}</strong> ·
      <button class="link" type="button" onclick={() => session.signOut()}>Salir</button>
    </p>
  {/if}
</main>

<HowToPlay bind:this={howTo} />
<WhatsNew bind:this={whatsNew} canSnitch={session.status === 'ready'} />

<style>
  .intro {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-6);
    padding-top: var(--space-6);
  }

  .stage {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    justify-items: center;
    gap: var(--space-4);
    padding: var(--space-5) var(--space-4) var(--space-6);
    text-align: center;
  }

  .emblem {
    width: min(46vw, 11rem);
    height: auto;
    margin-bottom: calc(-1 * var(--space-2));
    filter: drop-shadow(0 0.6rem 1rem rgba(0, 0, 0, 0.55));
    animation: sway 3.2s ease-in-out infinite;
  }

  @keyframes sway {
    0%, 100% { transform: rotate(-2deg); }
    50% { transform: rotate(2deg) translateY(-3px); }
  }

  @media (prefers-reduced-motion: reduce) {
    .emblem { animation: none; }
  }

  .tagline {
    max-width: 18rem;
    font-weight: 600;
    color: var(--ink-dim);
  }

  .fine {
    max-width: 18rem;
    font-size: var(--text-xs);
    color: var(--ink-mute);
  }

  .done {
    display: grid;
    justify-items: center;
    gap: var(--space-3);
    width: 100%;
  }

  .kicker {
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--ink-dim);
  }

  .reels {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-2);
    width: min(100%, 15rem);
  }

  .verdict {
    font-family: var(--font-display);
    font-size: var(--text-lg);
  }

  .nick {
    color: var(--ink);
  }

  .error {
    font-weight: 600;
    color: var(--red-300);
  }

  .links {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: var(--space-5) var(--space-3);
  }

  .legal {
    font-size: var(--text-xs);
    text-align: center;
  }

  .legal a {
    color: var(--ink-mute);
  }

  .who {
    font-size: var(--text-sm);
    text-align: center;
    color: var(--ink-mute);
  }

  .who strong {
    color: var(--ink);
  }

  .link {
    padding: 0;
    border: 0;
    background: none;
    color: var(--gold-300);
    text-decoration: underline;
    text-underline-offset: 0.2em;
    cursor: pointer;
  }
</style>
