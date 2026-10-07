<!--
  What's-new panel: the latest release notes inside the bulb marquee. Native
  <dialog> like HowToPlay (focus trap, Esc, backdrop). Intro.svelte decides
  when it opens and marks the version as seen at that moment.
-->
<script lang="ts">
  import { latest } from '../news'
  import { navigate } from '../router.svelte'
  import ArcadeButton from './ArcadeButton.svelte'
  import Marquee from './Marquee.svelte'
  import ReleaseNotes from './ReleaseNotes.svelte'

  let { canSnitch = false }: { canSnitch?: boolean } = $props()

  let dialog: HTMLDialogElement
  let opened = $state(false)

  export function open() {
    opened = true
    dialog.showModal()
  }

  function close() {
    dialog.close()
  }

  function snitch() {
    close()
    navigate('/buzon')
  }
</script>

<dialog
  bind:this={dialog}
  aria-labelledby="news-title"
  onclick={(e) => e.target === dialog && close()}
>
  <Marquee band={16} spacing={20} chase={false}>
    <div class="card">
      <p class="kicker">Novedades</p>
      <h2 id="news-title" class="gold-text">{latest.title}</h2>
      {#if opened}<ReleaseNotes release={latest} pop />{/if}
      <div class="actions">
        <ArcadeButton size="lg" block onclick={close}>¡A jugar!</ArcadeButton>
        {#if canSnitch}
          <ArcadeButton variant="blue" block onclick={snitch}>Chivarme ya</ArcadeButton>
        {/if}
      </div>
    </div>
  </Marquee>
</dialog>

<style>
  dialog {
    width: min(100% - 1.5rem, 28rem);
    max-height: calc(100dvh - 1.5rem);
    padding: 0;
    border: 0;
    background: transparent;
    color: var(--ink);
  }

  dialog::backdrop {
    background: rgba(15, 1, 7, 0.8);
    backdrop-filter: blur(3px);
  }

  dialog[open] {
    animation: fx-pop-in var(--dur-base) var(--ease-pop);
  }

  .card {
    display: grid;
    gap: var(--space-4);
    padding: var(--space-5) var(--space-4);
    text-align: center;
  }

  .kicker {
    font-family: var(--font-display);
    font-size: var(--text-md);
    letter-spacing: 0.14em;
    color: #ffe6fa;
    text-shadow: var(--glow-magenta);
  }

  h2 {
    font-size: var(--text-xl);
    line-height: 1.1;
  }

  .actions {
    display: grid;
    gap: var(--space-3);
    margin-top: var(--space-2);
  }
</style>
