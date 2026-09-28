<!--
  Onboarding after the first Google login: pick the nickname shown on the
  leaderboard. Styled as the contestant's contract: "firme aquí, concursante".
-->
<script lang="ts">
  import { navigate } from '../lib/router.svelte'
  import { NICKNAME_MAX, session, validateNickname } from '../lib/session.svelte'
  import ArcadeButton from '../lib/ui/ArcadeButton.svelte'

  let nickname = $state('')
  let error = $state<string | null>(null)
  let saving = $state(false)
  let signed = $state(false)
  let touched = $state(false)

  const length = $derived(Array.from(nickname.trim()).length)
  const liveError = $derived(touched ? validateNickname(nickname) : null)

  async function submit(event: SubmitEvent) {
    event.preventDefault()
    touched = true
    error = validateNickname(nickname)
    if (error) return
    saving = true
    error = await session.createProfile(nickname)
    saving = false
    if (error) return
    signed = true
    setTimeout(() => navigate('/'), 900)
  }
</script>

<main class="page">
  <form class="contract" onsubmit={submit} novalidate>
    <p class="kicker">Contrato de concursante</p>
    <h1>Firme aquí, concursante</h1>
    <p class="terms">
      Elige tu apodo. Es lo único que verá el resto en el ranking: ni tu nombre ni tu correo salen de aquí.
    </p>

    <label class="field" for="nickname">
      <span class="sr-only">Apodo</span>
      <span class="x" aria-hidden="true">✗</span>
      <input
        id="nickname"
        name="nickname"
        type="text"
        bind:value={nickname}
        onblur={() => (touched = nickname.length > 0)}
        maxlength={NICKNAME_MAX + 5}
        autocomplete="nickname"
        autocapitalize="off"
        spellcheck="false"
        placeholder="Tu apodo"
        aria-invalid={Boolean(error ?? liveError)}
        aria-describedby="nickname-help"
        disabled={saving || signed}
      />
    </label>

    <p id="nickname-help" class="help" class:bad={error ?? liveError} aria-live="polite">
      {#if error ?? liveError}
        {error ?? liveError}
      {:else}
        De 3 a {NICKNAME_MAX} caracteres · <span class="count">{length}/{NICKNAME_MAX}</span>
      {/if}
    </p>

    <ArcadeButton type="submit" size="lg" block disabled={saving || signed}>
      {saving ? 'Firmando…' : '¡Firmar!'}
    </ArcadeButton>

    {#if signed}
      <div class="stamp fx-pop-in" role="status">¡Fichado!</div>
    {/if}
  </form>
</main>

<style>
  .page {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    min-height: 100dvh;
    align-content: center;
  }

  .contract {
    position: relative;
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-4);
    padding: var(--space-6) var(--space-5) var(--space-6);
    border-radius: var(--radius-md);
    /* Aged paper on the velvet stage */
    background:
      radial-gradient(ellipse at 20% 10%, rgba(255, 255, 255, 0.55), transparent 55%),
      linear-gradient(180deg, #fff6df, #f3e2b8);
    color: #3b1d00;
    box-shadow:
      inset 0 0 0 1px rgba(122, 74, 6, 0.35),
      inset 0 0 0 6px #fff6df,
      inset 0 0 0 7px rgba(207, 143, 18, 0.55),
      0 1rem 2.5rem rgba(0, 0, 0, 0.6);
    transform: rotate(-0.6deg);
  }

  .kicker {
    font-family: var(--font-display);
    font-size: var(--text-xs);
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--red-600);
    text-align: center;
  }

  h1 {
    font-size: var(--text-xl);
    text-align: center;
    color: #3b1d00;
    text-shadow: 0 2px 0 var(--gold-300);
  }

  .terms {
    font-size: var(--text-sm);
    text-align: center;
    color: #5c3a12;
  }

  .field {
    display: flex;
    align-items: flex-end;
    gap: var(--space-2);
    margin-top: var(--space-4);
    border-bottom: 2px solid #3b1d00;
  }

  .x {
    font-size: 1.6rem;
    line-height: 1.3;
    color: var(--red-600);
  }

  input {
    flex: 1;
    width: 100%;
    min-width: 0;
    padding: var(--space-2) 0;
    border: 0;
    background: transparent;
    font-family: var(--font-body);
    font-size: 1.75rem;
    font-style: italic;
    font-weight: 600;
    color: #1f2a8a; /* ballpoint blue */
    outline: none;
  }

  input::placeholder {
    color: rgba(59, 29, 0, 0.3);
  }

  .field:focus-within {
    border-bottom-color: var(--blue-600);
    box-shadow: 0 2px 0 0 var(--blue-600);
  }

  .help {
    min-height: 1.5em;
    font-size: var(--text-sm);
    color: #5c3a12;
  }

  .help.bad {
    font-weight: 600;
    color: var(--red-600);
  }

  .count {
    font-variant-numeric: tabular-nums;
  }

  .stamp {
    position: absolute;
    right: 1rem;
    bottom: 5.5rem;
    padding: 0.35rem 0.9rem;
    border: 4px solid var(--red-600);
    border-radius: var(--radius-sm);
    font-family: var(--font-display);
    font-size: 1.6rem;
    color: var(--red-600);
    transform: rotate(-12deg);
    mix-blend-mode: multiply;
    opacity: 0.9;
  }
</style>
