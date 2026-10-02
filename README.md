# Juan o Minga

¿Lo dijo uno de la charanga o un peñista? Tres frases al día. Un solo intento.

Juego web diario para la Peña Los Mingas y la Xaranga A Vorem. Cada día salen las mismas 3 frases para todo el mundo y hay que adivinar si la dijo alguien de la charanga (**AVOREM**) o un peñista (**PEÑISTA**). Tiene ranking público, buzón para proponer frases y un resultado para compartir por WhatsApp.

- **Web:** https://aiayn-creator.github.io/Juan-o-Minga/
- **Estreno:** viernes 2 de octubre de 2026 a las 18:30 (hora de Madrid), con la ronda #1.
- **Teaser:** [`brand/teaser-4x3.mp4`](brand/teaser-4x3.mp4), 19 s en formato tele antigua.
- **Stack:** Vite + Svelte 5 + TypeScript, una SPA estática en GitHub Pages, sobre Supabase: Postgres, Auth con Google y funciones RPC. No hay servidor propio.

## Cómo se juega

1. **Entra con Google y elige un apodo.** Es lo único que ven los demás.
2. **Cada día, 3 frases.** Las mismas para todo el mundo; el día cambia a medianoche, hora de Madrid. Para cada una, pulsa **AVOREM** o **PEÑISTA**. Solo hay un intento: la respuesta queda guardada y no se puede repetir, ni desde otro navegador.
3. **La revelación:** un rodillo de tragaperras dice quién la dijo y en qué contexto. Los peñistas nunca se nombran.
4. **El resultado:** aciertos del día, racha y estadísticas, y un botón para compartirlo por WhatsApp.
5. **El ranking** es público y ordena por % de aciertos. Se entra a partir de **3 días jugados**; antes, apareces en "Aspirantes".
6. **El buzón:** cualquiera con sesión puede proponer frases (hasta 10 al día). Llegan como pendientes y solo entran al juego si se aprueban.

Si cierras la web a mitad de partida, al volver sigues donde lo dejaste.

## Estado

**En producción.** Todo el alcance previsto está hecho:

| Parte | Estado |
|---|---|
| Esquema, RLS y RPCs (ronda diaria, respuestas, buzón, ranking y estadísticas) | ✅ Con tests |
| Login con Google, apodo, juego, revelación, resultado y compartir | ✅ |
| Ranking público (mínimo 3 días) y buzón de frases | ✅ |
| Marca, accesibilidad (axe sin incidencias) y móvil desde 320px | ✅ |
| Cuenta atrás hasta el estreno y [página de privacidad](https://aiayn-creator.github.io/Juan-o-Minga/privacidad.html) | ✅ |
| Supabase en producción (UE, París) y login de Google publicado | ✅ |
| Frases reales cargadas y teaser | ✅ |

Si faltan las variables de Supabase (por ejemplo en un fork), la web muestra la cuenta atrás con la fecha por defecto y, pasado el estreno, "El plató está en obras" en lugar del juego.

## Cómo funciona la seguridad

La anon key de Supabase es pública por diseño; toda la seguridad está en la base de datos:

- **Nadie lee las frases directamente.** `get_today_round()` solo devuelve el id y el texto de las frases sin responder. El bando, el autor y el contexto llegan en la misma llamada que registra la respuesta (`submit_answer()`).
- **Una respuesta por frase y día.** Lo impone la clave primaria de `answers`, así que no depende del navegador ni del dispositivo.
- **Los peñistas nunca se nombran:** ni en la base de datos (una restricción `CHECK` lo impide) ni en la revelación, que siempre dice "un peñista".
- **El buzón guarda las frases como pendientes.** No entran al juego hasta que el administrador las aprueba en Supabase.
- **El ranking solo muestra apodos.** El nombre y el correo de Google nunca salen de Supabase Auth.
- **Las tablas no se leen desde fuera.** Con la clave pública solo se puede leer la fecha de estreno (`app_config`) y llamar al ranking; todo lo demás pasa por funciones que comprueban la sesión. El esquema `private` y `auth` no están expuestos.
- **Solo se entra con Google.** El registro por email, teléfono y anónimo está desactivado.
- **Las frases reales nunca se commitean,** porque el repo es público. `supabase/seed.sql` solo lleva frases inventadas para desarrollo.

## Desarrollo local

```bash
npm install
cp .env.example .env.local   # y rellena las claves de Supabase
npm run dev
```

| Variable | Qué es |
|---|---|
| `VITE_SUPABASE_URL` | URL del proyecto de Supabase |
| `VITE_SUPABASE_ANON_KEY` | Anon key o publishable key: pública por diseño |
| `BASE_PATH` | Opcional. Ruta desde la que se sirve la web. En CI sale sola de la configuración de Pages |
| `SITE_URL` | Opcional. URL pública absoluta para las etiquetas de vista previa (`og:image`). En CI sale sola |

| Script | Qué hace |
|---|---|
| `npm run dev` | Servidor de desarrollo. `#/kit` enseña todos los componentes y `brand/preview.html` la marca |
| `npm run check` | Comprueba los tipos (svelte-check + tsc) |
| `npm run test:db` | Migraciones, RLS y RPCs sobre un Postgres en memoria ([PGlite](https://pglite.dev)), sin Docker |
| `npm run build` / `npm run preview` | Build de producción y previsualización |
| `npm run brand` | Regenera `og-image.jpg`, `apple-touch-icon.png` e `icon-512.png` desde `brand/*.svg` |

## Estructura

- `src/screens/` — pantallas: `Intro`, `Nickname` (onboarding), `Game`, `Result`, `Leaderboard`, `SuggestionBox`, y `Kit`, que solo existe en desarrollo.
- `src/lib/` — sesión (`session.svelte.ts`), ronda del día (`round.svelte.ts`), cuenta atrás (`launch.svelte.ts`), compartir (`share.ts`), router por hash, cliente de Supabase y hora de Madrid.
- `src/lib/ui/` — componentes del plató: marquesina, logo de neón, pulsadores, rodillo, contadores, bombillas, pantalla de la frase…
- `src/styles/` — tokens (paleta, tipografías, movimiento) y estilos globales.
- `public/` — archivos que se sirven tal cual: favicon, iconos, banner para compartir (estos tres, generados) y `privacidad.html`.
- `brand/` — la marca: SVG fuente del emblema, el icono y el banner, `build.mjs` (lo que ejecuta `npm run brand`), `preview.html` y el teaser en 4:3 (`teaser-4x3.mp4`).
- `supabase/migrations/` — esquema, RLS y RPCs. Se aplican en orden en el editor SQL de Supabase.
- `supabase/tests/` — tests SQL, su runner `run.mjs` (`npm run test:db`) y `_supabase_stub.sql`, que imita lo que trae un proyecto de Supabase (roles y `auth.uid()`).
- `supabase/seed.sql` — 12 frases **inventadas**, solo para proyectos de desarrollo.
- `.github/workflows/` — `test.yml` (tipos y tests en cada push) y `deploy.yml` (publicación en Pages).

En la raíz solo queda lo que las herramientas esperan encontrar ahí: `index.html` (entrada de Vite), `vite.config.ts`, los tres `tsconfig*.json` (app y config de Node, como en la plantilla oficial), `package.json`, `.env.example`, `LICENSE` y este README.

## Puesta en marcha (para montar una copia)

1. **Supabase y Google:** crear el proyecto, configurar el login con Google y las URLs de redirección, y dejar desactivados el registro por email y el anónimo. Después, ejecutar las migraciones de `supabase/migrations/` en orden en el *SQL Editor*. **Nunca `seed.sql` en producción.**
2. **Variables en GitHub:** en *Settings → Secrets and variables → Actions → Variables*, crear `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
3. **Fecha de estreno:** `launch_at` y `launch_date` en la tabla `app_config`. De `launch_date` sale el número de ronda "#N".
4. **Despliegue:** cada push a `main` compila y publica en GitHub Pages.

## Mantenimiento

- **Añadir frases:** en la tabla `phrases`, con `status = approved` y un `context` (cuándo y dónde se dijo). Los peñistas, siempre sin `author`. Cada día se eligen 3 empezando por las que nunca han salido; cuando se acaban, se repiten las más antiguas.
- **Moderar el buzón:** las propuestas llegan con `status = pending`. Basta con cambiarlo a `approved` o `rejected` en el editor de tablas, revisando antes que no nombren a ningún peñista.
- **Borrar una cuenta** (derecho de supresión): borrar el usuario en *Authentication → Users*; su perfil y sus respuestas se borran en cascada, y sus frases del buzón quedan sin remitente.

## Licencia

Todos los derechos reservados. El repositorio es público solo para poder servirlo con GitHub Pages: ver el código no da permiso para usarlo. Consulta [LICENSE](LICENSE).
