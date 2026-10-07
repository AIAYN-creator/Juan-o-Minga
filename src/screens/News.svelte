<!--
  #/novedades: the release notes of every version, newest first. Public.
-->
<script lang="ts">
  import { formatDate, releases } from '../lib/news'
  import { href } from '../lib/router.svelte'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'
  import Panel from '../lib/ui/Panel.svelte'
  import ReleaseNotes from '../lib/ui/ReleaseNotes.svelte'
</script>

<main class="page news">
  <header class="head">
    <p class="kicker">Notas de la versión</p>
    <h1 class="gold-text">Novedades</h1>
  </header>

  {#each releases as release (release.version)}
    <Panel>
      <article class="release">
        <h2>
          {#if !release.title.includes(release.version)}<span class="version led">v{release.version}</span>{/if}
          <span class="title">{release.title}</span>
        </h2>
        <p class="date"><time datetime={release.date}>{formatDate(release.date)}</time></p>
        <ReleaseNotes {release} />
      </article>
    </Panel>
  {/each}

  <nav class="back">
    <ArcadeButton variant="gold" href={href('/')}>Volver</ArcadeButton>
  </nav>
</main>

<style>
  .news {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-5);
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

  .release {
    display: grid;
    gap: var(--space-3);
  }

  h2 {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: center;
    gap: var(--space-2);
    font-size: var(--text-lg);
    text-align: center;
  }

  .version {
    color: var(--gold-300);
    text-shadow: 0 0 0.3em rgba(255, 216, 102, 0.7);
  }

  .date {
    margin-top: calc(-1 * var(--space-2));
    font-size: var(--text-xs);
    color: var(--ink-mute);
    text-align: center;
  }

  .back {
    display: flex;
    justify-content: center;
  }
</style>
