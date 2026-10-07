<!--
  "Cómo se juega" modal. Native <dialog>: focus trap, Esc to close and
  backdrop for free. Open it with bind:this + .open().
-->
<script lang="ts">
  import ArcadeButton from './ArcadeButton.svelte'

  let dialog: HTMLDialogElement

  export function open() {
    dialog.showModal()
  }

  function close() {
    dialog.close()
  }
</script>

<dialog bind:this={dialog} aria-labelledby="how-title" onclick={(e) => e.target === dialog && close()}>
  <div class="card">
    <h2 id="how-title" class="gold-text">Cómo se juega</h2>
    <ol>
      <li><strong>3 frases al día.</strong> Las mismas para todo el mundo.</li>
      <li>
        <strong>Adivina quién la dijo:</strong> alguien de la charanga
        (<span class="avorem">AVOREM</span>) o un peñista cualquiera
        (<span class="penista">PEÑISTA</span>).
      </li>
      <li><strong>Un solo intento.</strong> Lo pulsado, pulsado está.</li>
      <li>Tras cada respuesta verás quién lo dijo y cuándo.</li>
      <li><strong>Vuelve mañana</strong> a medianoche: frases nuevas.</li>
      <li>
        <strong>Chívate en el buzón:</strong> cada 3 frases tuyas aprobadas ganas un 🛡️ protector
        (hasta 2) que salva tu racha si un día no juegas. Quien más frases cuela lleva el
        📣 Megáfono de oro.
      </li>
    </ol>
    <ArcadeButton block onclick={close}>¡Entendido!</ArcadeButton>
  </div>
</dialog>

<style>
  dialog {
    width: min(100% - 2rem, 26rem);
    padding: 0;
    border: 0;
    background: transparent;
    color: var(--ink);
  }

  dialog::backdrop {
    background: rgba(15, 1, 7, 0.78);
    backdrop-filter: blur(3px);
  }

  dialog[open] {
    animation: fx-pop-in var(--dur-base) var(--ease-pop);
  }

  .card {
    display: grid;
    gap: var(--space-5);
    padding: var(--space-6) var(--space-5) var(--space-5);
    border-radius: var(--radius-lg);
    background:
      radial-gradient(ellipse at 50% 0%, rgba(255, 216, 102, 0.14), transparent 55%),
      linear-gradient(180deg, var(--velvet-700), var(--velvet-900));
    box-shadow:
      inset 0 0 0 2px var(--gold-500),
      inset 0 0 0 6px var(--velvet-900),
      inset 0 0 0 7px rgba(240, 180, 41, 0.4),
      0 1.5rem 3rem rgba(0, 0, 0, 0.7);
  }

  h2 {
    font-size: var(--text-xl);
    text-align: center;
  }

  ol {
    display: grid;
    gap: var(--space-3);
    margin: 0;
    padding-left: 1.4rem;
  }

  li::marker {
    font-family: var(--font-display);
    color: var(--gold-300);
  }

  .avorem,
  .penista {
    font-family: var(--font-display);
    font-size: 0.9em;
  }

  .avorem {
    color: var(--red-300);
  }

  .penista {
    color: var(--blue-300);
  }
</style>
