-- Development seed: 12 INVENTED phrases, already approved, so a dev project
-- can play 4 full rounds without touching the table editor.
--
-- ⚠️ DEVELOPMENT ONLY. Never run this on the production project: these
-- phrases would show up in the real game. Real phrases are loaded by hand in
-- Supabase and are NEVER committed to this repo.
--
-- Fixed ids (…-0000000000NN) so they are easy to spot and remove:
--   delete from public.phrases where id::text like '00000000-0000-4000-8000-0000000000%';
-- (fails for any phrase already used in a round -- delete those rounds first)

insert into public.phrases (id, text, side, author, context, status) values
  ('00000000-0000-4000-8000-000000000001',
   'El pasodoble lo toco mejor con dos cubatas, con tres ya me sale jazz',
   'charanga', 'El del bombo', 'Ensayo de la víspera, en el almacén', 'approved'),
  ('00000000-0000-4000-8000-000000000002',
   '¿Alguien ha visto mi trompeta? La dejé encima de la barra hace un momento',
   'charanga', null, 'Cuarta ronda de la verbena del sábado', 'approved'),
  ('00000000-0000-4000-8000-000000000003',
   'Esta noche no bebo, que mañana madrugo',
   'penista', null, 'A las once de la noche, antes del primer toro de fuego', 'approved'),
  ('00000000-0000-4000-8000-000000000004',
   'Si tocáis Paquito el Chocolatero otra vez me tiro a la fuente',
   'penista', null, 'Pasacalles del domingo, delante del ayuntamiento', 'approved'),
  ('00000000-0000-4000-8000-000000000005',
   'Yo no desafino, es que voy por delante de la melodía',
   'charanga', 'La del saxo', 'Después de la procesión, justificándose', 'approved'),
  ('00000000-0000-4000-8000-000000000006',
   'Que alguien apunte dónde está la peña, que el año pasado acabé en otro pueblo',
   'penista', null, 'Primera noche de fiestas, bastante pronto', 'approved'),
  ('00000000-0000-4000-8000-000000000007',
   'El chándal de la charanga no se lava, se cura',
   'charanga', null, 'Discusión sobre el uniforme en la furgoneta', 'approved'),
  ('00000000-0000-4000-8000-000000000008',
   'Dos horas haciendo cola para la paella y resulta que era la de otra peña',
   'penista', null, 'Comida popular del lunes', 'approved'),
  ('00000000-0000-4000-8000-000000000009',
   'Tú marca el ritmo, que la partitura ya la improvisamos',
   'charanga', 'El de la caja', 'Arrancando el primer pasacalles', 'approved'),
  ('00000000-0000-4000-8000-000000000010',
   'Yo a la charanga la sigo hasta el fin del mundo, o hasta que cierren el bar',
   'penista', null, 'Pasacalles de madrugada', 'approved'),
  ('00000000-0000-4000-8000-000000000011',
   'Hoy tocamos sentados, que ayer nos dimos todos por perdidos',
   'charanga', null, 'Sesión vermú del martes', 'approved'),
  ('00000000-0000-4000-8000-000000000012',
   'Me he dejado el móvil en el toro mecánico',
   'penista', null, 'Última noche, en la plaza', 'approved')
on conflict (id) do nothing;
