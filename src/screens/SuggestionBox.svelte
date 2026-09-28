<!--
  Suggestion box: send a phrase for the jury (the admin) to approve.
  Author only for AVOREM; peñistas are never named. Goes through
  submit_phrase(), which always stores it as pending.
-->
<script lang="ts">
  import { href } from '../lib/router.svelte'
  import type { Side } from '../lib/round.svelte'
  import { supabase } from '../lib/supabase'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'

  const TEXT_MAX = 280
  const AUTHOR_MAX = 60

  let text = $state('')
  let side = $state<Side | null>(null)
  let author = $state('')
  let context = $state('')
  let sending = $state(false)
  let error = $state<string | null>(null)
  let sent = $state(false)

  const messages: Record<string, string> = {
    daily_limit: 'Ya has mandado 10 frases hoy. El jurado también descansa: vuelve mañana.',
    no_profile: 'Antes de nada, elige tu apodo.',
    not_authenticated: 'Se ha perdido la sesión. Vuelve a entrar.',
    invalid_text: `La frase tiene que tener entre 1 y ${TEXT_MAX} caracteres.`,
    invalid_context: 'Cuéntanos cuándo y dónde lo dijo.',
    invalid_side: '¿Charanga o peñista? Elige uno.',
    invalid_author: `El autor, como mucho ${AUTHOR_MAX} caracteres.`,
  }

  function validate(): string | null {
    if (!text.trim()) return 'Falta la frase, que es lo importante.'
    if (text.trim().length > TEXT_MAX) return messages.invalid_text
    if (!side) return messages.invalid_side
    if (!context.trim()) return messages.invalid_context
    if (context.trim().length > TEXT_MAX) return 'El contexto, como mucho 280 caracteres.'
    if (author.trim().length > AUTHOR_MAX) return messages.invalid_author
    return null
  }

  async function submit(event: SubmitEvent) {
    event.preventDefault()
    error = validate()
    if (error) return
    sending = true
    const { error: rpcError } = await supabase.rpc('submit_phrase', {
      p_text: text.trim(),
      p_side: side,
      // Never send an author for a peñista, even if one was typed before switching.
      p_author: side === 'charanga' && author.trim() ? author.trim() : null,
      p_context: context.trim(),
    })
    sending = false
    if (rpcError) {
      error = messages[rpcError.message] ?? 'No se ha podido enviar. Prueba otra vez.'
      return
    }
    sent = true
  }

  function another() {
    text = ''
    side = null
    author = ''
    context = ''
    error = null
    sent = false
  }
</script>

<main class="page box">
  <header class="head">
    <p class="kicker">Buzón de sugerencias</p>
    <h1 class="gold-text">¿Tienes una frase?</h1>
    <p class="sub">Mándala al jurado. Si la aprueba, un día saldrá en el juego.</p>
  </header>

  {#if sent}
    <section class="sent" role="status">
      <div class="stamp" aria-hidden="true">
        <span>RECIBIDA</span>
        <small>Juan o Minga</small>
      </div>
      <p class="sent-text">Tu frase está en manos del jurado.</p>
      <div class="actions">
        <ArcadeButton variant="blue" onclick={another}>Enviar otra</ArcadeButton>
        <ArcadeButton variant="gold" href={href('/')}>Volver</ArcadeButton>
      </div>
    </section>
  {:else}
    <p class="rule" role="note">
      <span class="inner">
        <span aria-hidden="true">⚠️</span>
        <strong>Nada de nombres ni apodos de peñistas.</strong> Si lo dijo un peñista, se queda en "un peñista".
      </span>
    </p>

    <form class="form" onsubmit={submit} novalidate>
      <label class="field">
        <span class="label">La frase</span>
        <textarea bind:value={text} rows="3" maxlength={TEXT_MAX + 20} placeholder="«Esta noche no bebo…»" required></textarea>
        <span class="count" class:over={text.trim().length > TEXT_MAX}>{text.trim().length}/{TEXT_MAX}</span>
      </label>

      <fieldset class="field">
        <legend class="label">¿Quién la dijo?</legend>
        <div class="sides">
          <label class="side avorem" class:on={side === 'charanga'}>
            <input type="radio" name="side" value="charanga" bind:group={side} />
            <span>AVOREM</span>
          </label>
          <label class="side penista" class:on={side === 'penista'}>
            <input type="radio" name="side" value="penista" bind:group={side} />
            <span>PEÑISTA</span>
          </label>
        </div>
      </fieldset>

      {#if side === 'charanga'}
        <label class="field">
          <span class="label">Autor <em>(opcional, solo si le parece bien)</em></span>
          <input type="text" bind:value={author} maxlength={AUTHOR_MAX + 10} autocomplete="off" placeholder="El del bombo" />
        </label>
      {/if}

      <label class="field">
        <span class="label">¿Cuándo y dónde lo dijo?</span>
        <textarea bind:value={context} rows="2" maxlength={TEXT_MAX + 20} placeholder="En la verbena del sábado, a las tantas" required></textarea>
      </label>

      {#if error}<p class="error" role="alert">{error}</p>{/if}

      <ArcadeButton type="submit" size="lg" block disabled={sending}>
        {sending ? 'Enviando…' : 'Al buzón'}
      </ArcadeButton>
    </form>

    <nav class="back">
      <a href={href('/')}>Volver al inicio</a>
    </nav>
  {/if}
</main>

<style>
  .box {
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
    color: #d9fdff;
    text-shadow: var(--glow-cyan);
  }

  h1 {
    font-size: var(--text-xl);
  }

  .sub {
    font-size: var(--text-sm);
    color: var(--ink-dim);
  }

  /* Caution-tape frame around a dark sign, so the text never sits on the stripes */
  .rule {
    padding: 6px;
    border-radius: var(--radius-md);
    background: repeating-linear-gradient(-45deg, #ffc400 0 12px, #1c040d 12px 24px);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.4);
  }

  .rule .inner {
    display: block;
    padding: var(--space-3) var(--space-4);
    border-radius: calc(var(--radius-md) - 4px);
    background: #1c040d;
    font-size: var(--text-sm);
    color: var(--ink);
  }

  .rule strong {
    color: #ffc400;
  }

  .form {
    display: grid;
    gap: var(--space-4);
    padding: var(--space-5) var(--space-4);
    border-radius: var(--radius-lg);
    background: linear-gradient(180deg, rgba(82, 16, 36, 0.92), rgba(28, 4, 13, 0.95));
    box-shadow:
      inset 0 0 0 1.5px var(--gold-500),
      0 0.75rem 2rem rgba(0, 0, 0, 0.55);
  }

  .field {
    display: grid;
    gap: var(--space-2);
    margin: 0;
    padding: 0;
    border: 0;
    min-width: 0;
  }

  .label {
    font-family: var(--font-display);
    font-size: var(--text-sm);
    color: var(--gold-300);
  }

  .label em {
    font-family: var(--font-body);
    font-size: var(--text-xs);
    font-style: normal;
    color: var(--ink-mute);
  }

  textarea,
  input[type='text'] {
    width: 100%;
    padding: var(--space-3);
    border: 0;
    border-radius: var(--radius-sm);
    background: #fffaf0;
    color: #2a1405;
    font: inherit;
    font-size: 1rem; /* 16px: no iOS zoom on focus */
    resize: vertical;
    box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.25);
  }

  textarea:focus,
  input[type='text']:focus {
    outline: 3px solid var(--neon-cyan);
    outline-offset: 2px;
  }

  .count {
    justify-self: end;
    font-size: var(--text-xs);
    color: var(--ink-mute);
    font-variant-numeric: tabular-nums;
  }

  .count.over {
    color: var(--red-300);
    font-weight: 700;
  }

  .sides {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-3);
  }

  .side {
    position: relative;
    display: grid;
    place-items: center;
    min-height: 3.25rem;
    border-radius: var(--radius-pill);
    font-family: var(--font-display);
    color: #fff;
    background: var(--c);
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.4),
      0 5px 0 var(--rim);
    opacity: 0.55;
    cursor: pointer;
    transition:
      transform var(--dur-instant) ease-out,
      opacity var(--dur-fast) ease-out,
      box-shadow var(--dur-instant) ease-out;
  }

  .side input {
    position: absolute;
    opacity: 0;
    pointer-events: none;
  }

  .side.on {
    opacity: 1;
    transform: translateY(3px);
    box-shadow:
      inset 0 2px 0 rgba(255, 255, 255, 0.4),
      0 2px 0 var(--rim),
      0 0 1rem var(--glow);
  }

  .side:has(input:focus-visible) {
    outline: 3px solid var(--neon-cyan);
    outline-offset: 3px;
  }

  .side.on span::before {
    content: '✓ ';
  }

  .avorem {
    --c: linear-gradient(180deg, #ff8a98, var(--red-500));
    --rim: var(--red-800);
    --glow: rgba(238, 27, 58, 0.6);
  }

  .penista {
    --c: linear-gradient(180deg, #a6d6ff, var(--blue-500));
    --rim: var(--blue-800);
    --glow: rgba(31, 123, 255, 0.6);
  }

  .error {
    font-weight: 600;
    color: var(--red-300);
  }

  .back {
    text-align: center;
  }

  /* ---- Sent ---- */
  .sent {
    display: grid;
    justify-items: center;
    gap: var(--space-5);
    padding: var(--space-6) var(--space-4);
    text-align: center;
  }

  .stamp {
    display: grid;
    place-items: center;
    width: 11rem;
    aspect-ratio: 1;
    border: 6px double var(--red-500);
    border-radius: 50%;
    color: var(--red-500);
    font-family: var(--font-display);
    transform: rotate(-14deg);
    animation: stamp 480ms var(--ease-pop) both;
    text-shadow: 0 0 0.4rem rgba(238, 27, 58, 0.5);
  }

  .stamp span {
    font-size: 1.6rem;
    line-height: 1;
  }

  .stamp small {
    margin-top: -2.5rem;
    font-size: 0.7rem;
    letter-spacing: 0.1em;
  }

  @keyframes stamp {
    0% { opacity: 0; transform: rotate(-14deg) scale(2.2); }
    60% { opacity: 1; transform: rotate(-14deg) scale(0.92); }
    100% { transform: rotate(-14deg) scale(1); }
  }

  .sent-text {
    font-family: var(--font-display);
    font-size: var(--text-lg);
    color: var(--ink);
  }

  .actions {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: var(--space-3);
  }
</style>
