# Juan o Minga

¿Lo dijo uno de la charanga o un peñista? Tres frases al día. Un solo intento.

Juego web diario: Vite + Svelte + TypeScript (SPA estática) sobre Supabase (Postgres, Auth con Google y funciones RPC).

## Desarrollo local

```bash
npm install
cp .env.example .env.local   # y rellena las claves de Supabase
npm run dev
```

| Variable | Qué es |
|---|---|
| `VITE_SUPABASE_URL` | URL del proyecto de Supabase |
| `VITE_SUPABASE_ANON_KEY` | Anon key (pública por diseño; la seguridad está en RLS y RPCs) |
| `BASE_PATH` | Ruta desde la que se sirve la web: vacío para `juanominga.com`, `/Juan-o-Minga/` para GitHub Pages (`aiayn-creator.github.io/Juan-o-Minga`) |

Otros scripts: `npm run check` (tipos), `npm run build`, `npm run preview`.

## Estructura

- `src/` — frontend. Rutas por hash (`#/jugar`, `#/ranking`, `#/buzon`, `#/apodo`).
- `supabase/migrations/` — esquema SQL, RLS y funciones RPC.

> Las frases reales **nunca** se commitean: este repo es público. El seed solo lleva frases inventadas.

<!-- Pendiente (tarjeta launch): crear el proyecto de Supabase, configurar Google OAuth, desplegar, aprobar frases y añadir el dominio propio. -->
