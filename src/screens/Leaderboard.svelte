<!--
  Public leaderboard (no login needed): arcade high-score board. Gold, silver
  and bronze podium, then the rest; the caller's row is highlighted. Players
  with under 5 days are listed apart as "aspirantes". Nicknames only.
-->
<script lang="ts">
  import { href } from '../lib/router.svelte'
  import { supabase } from '../lib/supabase'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Panel from '../lib/ui/Panel.svelte'

  type Row = {
    rank: number
    nickname: string
    days_played: number
    correct: number
    answered: number
    pct: number | null
    current_streak: number
    best_streak: number
    perfect_days: number
    qualified: boolean
    is_me: boolean
  }

  let rows = $state<Row[]>([])
  let status = $state<'loading' | 'ready' | 'error'>('loading')

  async function load() {
    status = 'loading'
    const { data, error } = await supabase.rpc('get_leaderboard')
    if (error) {
      status = 'error'
      return
    }
    rows = (data as Row[]) ?? []
    status = 'ready'
  }

  void load()

  const ranked = $derived(rows.filter((r) => r.qualified))
  const podium = $derived(ranked.slice(0, 3))
  const rest = $derived(ranked.slice(3))
  const aspirants = $derived(rows.filter((r) => !r.qualified))
  // Visual order on the podium: 2nd, 1st, 3rd
  const podiumOrder = $derived([podium[1], podium[0], podium[2]].filter(Boolean) as Row[])

  const pct = (r: Row) => (r.pct === null ? '—' : `${Math.round(r.pct)}%`)
  const medal = (r: Row) => (r === podium[0] ? 'gold' : r === podium[1] ? 'silver' : 'bronze')
</script>

<main class="page board">
  <header class="head">
    <p class="kicker">Salón de la fama</p>
    <h1 class="gold-text">Ranking</h1>
    <p class="sub">Por % de aciertos · mínimo 5 días jugados</p>
  </header>

  {#if status === 'loading'}
    <p class="note" aria-busy="true">Contando monedas…</p>
  {:else if status === 'error'}
    <p class="note error" role="alert">No hemos podido cargar el ranking.</p>
    <ArcadeButton onclick={load}>Reintentar</ArcadeButton>
  {:else if rows.length === 0}
    <Panel>
      <p class="note">Todavía no hay nadie en el marcador. ¡Estrénalo tú!</p>
    </Panel>
  {:else}
    {#if podium.length}
      <ol class="podium" aria-label="Podio">
        {#each podiumOrder as r (r.nickname)}
          <li class="step {medal(r)}" class:me={r.is_me}>
            <span class="crown" aria-hidden="true">{medal(r) === 'gold' ? '👑' : ''}</span>
            <span class="name">{r.nickname}</span>
            <span class="led pct">{pct(r)}</span>
            <span class="block">
              <span class="place">{r.rank}</span>
            </span>
          </li>
        {/each}
      </ol>
    {/if}

    {#if rest.length}
      {@render table(rest, 'Clasificación')}
    {/if}

    {#if aspirants.length}
      <section class="aspirants">
        <h2 class="gold-text">Aspirantes</h2>
        <p class="sub">Menos de 5 días jugados. Sigue viniendo y entras en el ranking.</p>
        {@render table(aspirants, 'Aspirantes')}
      </section>
    {/if}
  {/if}

  <nav class="back">
    <ArcadeButton variant="gold" href={href('/')}>Volver</ArcadeButton>
  </nav>
</main>

{#snippet table(list: Row[], caption: string)}
  <table class="scores">
    <caption class="sr-only">{caption}</caption>
    <thead>
      <tr>
        <th scope="col"><abbr title="Puesto">#</abbr></th>
        <th scope="col" class="nick">Apodo</th>
        <th scope="col">Aciertos</th>
        <th scope="col">Días</th>
        <th scope="col">Racha</th>
      </tr>
    </thead>
    <tbody>
      {#each list as r (r.nickname)}
        <tr class:me={r.is_me}>
          <td class="led">{r.rank}</td>
          <td class="nick">
            {r.nickname}
            {#if r.is_me}<span class="you">Tú</span>{/if}
          </td>
          <td class="led">{pct(r)}</td>
          <td class="led">{r.days_played}</td>
          <td class="led">{r.current_streak}{#if r.current_streak >= 3}<span aria-hidden="true">🔥</span>{/if}</td>
        </tr>
      {/each}
    </tbody>
  </table>
{/snippet}

<style>
  .board {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-6);
  }

  .head {
    display: grid;
    justify-items: center;
    gap: var(--space-2);
    text-align: center;
  }

  .kicker {
    font-family: var(--font-display);
    font-size: var(--text-xs);
    letter-spacing: 0.12em;
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  h1 {
    font-size: var(--text-2xl);
  }

  h2 {
    font-size: var(--text-lg);
    text-align: center;
  }

  .sub {
    font-size: var(--text-xs);
    color: var(--ink-mute);
    text-align: center;
  }

  .note {
    text-align: center;
    color: var(--ink-dim);
  }

  .error {
    color: var(--red-300);
  }

  /* ---- Podium ---- */
  .podium {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    align-items: end;
    gap: var(--space-2);
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .step {
    display: grid;
    justify-items: center;
    gap: var(--space-1);
    min-width: 0;
    text-align: center;
  }

  .crown {
    min-height: 1.4rem;
    font-size: 1.3rem;
  }

  /* Long nicknames get two lines on the podium, then an ellipsis */
  .name {
    display: -webkit-box;
    max-width: 100%;
    overflow: hidden;
    font-size: var(--text-sm);
    font-weight: 700;
    line-height: 1.2;
    overflow-wrap: anywhere;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
  }

  .pct {
    font-size: 1.25rem;
    color: var(--neon-green);
    text-shadow: 0 0 0.3em rgba(61, 255, 142, 0.6);
  }

  .block {
    display: grid;
    place-items: center;
    width: 100%;
    border-radius: var(--radius-sm) var(--radius-sm) 0 0;
    background: var(--metal);
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.6),
      inset 0 -4px 0 rgba(0, 0, 0, 0.25),
      0 0.6rem 1.2rem rgba(0, 0, 0, 0.5);
  }

  .place {
    font-family: var(--font-display);
    font-size: 2rem;
    color: var(--place-ink);
    text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
  }

  .gold .block { height: 7.5rem; }
  .silver .block { height: 5.5rem; }
  .bronze .block { height: 4.25rem; }

  .gold {
    --metal: var(--gold-metal);
    --place-ink: var(--ink-on-gold);
  }

  .silver {
    --metal: linear-gradient(180deg, #ffffff 0%, #d9dde3 35%, #8e97a3 55%, #e3e7ec 80%, #a9b1bb 100%);
    --place-ink: #2b3139;
  }

  .bronze {
    --metal: linear-gradient(180deg, #ffe0c2 0%, #d9894a 40%, #7a3f12 56%, #e0a06a 80%, #9a5420 100%);
    --place-ink: #3a1a04;
  }

  .step.me .name {
    color: var(--neon-cyan);
    text-shadow: var(--glow-cyan);
  }

  /* ---- Table ---- */
  .scores {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0 0.35rem;
    font-size: var(--text-sm);
  }

  th {
    padding: 0 var(--space-2);
    font-size: var(--text-xs);
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--ink-dim);
    text-align: right;
  }

  th abbr {
    text-decoration: none;
  }

  td {
    padding: var(--space-2);
    background: rgba(28, 4, 13, 0.85);
    text-align: right;
    white-space: nowrap;
  }

  td:first-child {
    border-radius: var(--radius-sm) 0 0 var(--radius-sm);
    color: var(--gold-300);
  }

  td:last-child {
    border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
  }

  td.led {
    font-size: 1.05rem;
  }

  .nick {
    width: 100%;
    max-width: 0; /* let the nickname column take the slack and ellipsize */
    overflow: hidden;
    text-align: left;
    text-overflow: ellipsis;
    font-weight: 600;
  }

  tr.me td {
    background: linear-gradient(90deg, rgba(47, 243, 255, 0.22), rgba(47, 243, 255, 0.08));
    box-shadow:
      inset 0 1px 0 rgba(47, 243, 255, 0.6),
      inset 0 -1px 0 rgba(47, 243, 255, 0.6);
  }

  .you {
    margin-left: var(--space-2);
    padding: 0.05em 0.45em;
    border-radius: var(--radius-pill);
    background: var(--neon-cyan);
    font-family: var(--font-display);
    font-size: 0.7rem;
    color: #002b30;
  }

  .aspirants {
    display: grid;
    gap: var(--space-2);
  }

  .back {
    display: flex;
    justify-content: center;
  }
</style>
