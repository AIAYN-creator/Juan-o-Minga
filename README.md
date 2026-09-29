# Juan o Minga

¿Lo dijo uno de la charanga o un peñista? Tres frases al día. Un solo intento.

Juego web diario para la Peña Los Mingas y la Xaranga A Vorem. Cada día salen las mismas 3 frases para todo el mundo y hay que adivinar si la dijo alguien de la charanga (**AVOREM**) o un peñista (**PEÑISTA**). Tiene ranking público, buzón para proponer frases y un resultado para compartir por WhatsApp.

- **Web:** https://aiayn-creator.github.io/Juan-o-Minga/. Pasará a `juanominga.com`.
- **Stack:** Vite + Svelte 5 + TypeScript, una SPA estática en GitHub Pages, sobre Supabase: Postgres, Auth con Google y funciones RPC. No hay servidor propio.

## Estado

| Parte | Estado |
|---|---|
| Esquema, RLS y RPCs (ronda diaria, respuestas, buzón, ranking y estadísticas) | ✅ Hecho y con tests |
| Sistema visual, marca (emblema, favicon, banner para compartir) | ✅ Hecho |
| Login con Google y elección de apodo | ✅ Hecho |
| Pantallas: inicio, ranking (público), buzón | ✅ Hechas |
| Pantalla de juego, resultado y compartir, pulido final | 🚧 En curso |
| Proyecto de Supabase real y dominio `juanominga.com` | ⏳ Pendiente de configurar |

Mientras no existan las variables de Supabase, la web publicada muestra "El plató está en obras".

## Cómo funciona la seguridad

La anon key de Supabase es pública por diseño; toda la seguridad está en la base de datos:

- **Nadie lee las frases directamente.** `get_today_round()` solo devuelve el id y el texto de las frases sin responder. El bando, el autor y el contexto llegan en la misma llamada que registra la respuesta (`submit_answer()`).
- **Una respuesta por frase y día.** Lo impone la clave primaria de `answers`, así que no depende del navegador ni del dispositivo.
- **Los peñistas nunca se nombran:** ni en la base de datos (una restricción `CHECK` lo impide) ni en la revelación, que siempre dice "un peñista".
- **El buzón guarda las frases como pendientes.** No entran al juego hasta que el administrador las aprueba en Supabase.
- **El ranking solo muestra apodos.** El nombre y el correo de Google nunca salen de Supabase Auth.
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

- `src/screens/` — pantallas: `Intro`, `Nickname` (onboarding), `Leaderboard`, `SuggestionBox`, y `Kit`, que solo existe en desarrollo.
- `src/lib/` — sesión (`session.svelte.ts`), ronda del día (`round.svelte.ts`), router por hash, cliente de Supabase y hora de Madrid.
- `src/lib/ui/` — componentes del plató: marquesina, logo de neón, pulsadores, rodillo, contadores, bombillas, pantalla de la frase…
- `src/styles/` — tokens (paleta, tipografías, movimiento) y estilos globales.
- `brand/` — fuentes SVG de la marca: emblema, icono y banner para compartir.
- `supabase/migrations/` — esquema, RLS y RPCs. Se aplican en orden en el editor SQL de Supabase.
- `supabase/tests/` — tests SQL. `_supabase_stub.sql` imita lo que trae un proyecto de Supabase (roles y `auth.uid()`).
- `supabase/seed.sql` — 12 frases **inventadas**, solo para proyectos de desarrollo.

## Puesta en marcha

1. **Supabase y Google:** crear el proyecto, configurar el login con Google y las URLs de redirección, y desactivar el login por email. Después, ejecutar las migraciones de `supabase/migrations/` en orden en el *SQL Editor*.
2. **Variables en GitHub:** en *Settings → Secrets and variables → Actions → Variables*, crear `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`.
3. **Fecha de lanzamiento:** fijar `launch_date` en la tabla `app_config`. De ella sale el número de ronda "#N".
4. **Frases:** cargarlas a mano en la tabla `phrases` con `status = approved`. Las del buzón llegan como `pending`: para aprobarlas o rechazarlas, basta con cambiar `status` en el editor de tablas.
5. **Despliegue:** cada push a `main` compila y publica en GitHub Pages.
6. **Dominio propio:** poner el DNS de `juanominga.com` y configurarlo en *Settings → Pages*. La subruta y las URLs absolutas se ajustan solas.

## Licencia

Todos los derechos reservados. El repositorio es público solo para poder servirlo con GitHub Pages: ver el código no da permiso para usarlo. Consulta [LICENSE](LICENSE).
