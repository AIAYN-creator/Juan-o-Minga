-- Constraints of the core schema (run as superuser: no RLS in the way).

do $$
declare
  a uuid := tests.create_user('Pepa');
  p1 uuid;
  p2 uuid;
begin
  -- phrases
  perform tests.expect_error(
    $q$insert into phrases (text, side, author, context) values ('Hola', 'penista', 'Fulano', 'En la plaza')$q$,
    '23514', 'a penista phrase cannot have an author');
  perform tests.expect_error(
    $q$insert into phrases (text, side, context) values ('   ', 'charanga', 'En la plaza')$q$,
    '23514', 'phrase text cannot be blank');
  perform tests.expect_error(
    $q$insert into phrases (text, side, context) values ('Hola', 'charanga', '')$q$,
    '23514', 'context cannot be blank');

  insert into phrases (text, side, author, context) values ('Hola', 'charanga', 'El del bombo', 'Ensayo')
    returning id into p1;
  assert (select status from phrases where id = p1) = 'pending', 'new phrases start as pending';
  insert into phrases (text, side, context, status) values ('Adiós', 'penista', 'Verbena', 'approved')
    returning id into p2;

  -- profiles
  perform tests.expect_error($q$select tests.create_user('ab')$q$, '23514', 'nickname under 3 chars');
  perform tests.expect_error($q$select tests.create_user('abcdefghijklmnopqrstu')$q$, '23514', 'nickname over 20 chars');
  perform tests.expect_error($q$select tests.create_user(' Pepe')$q$, '23514', 'nickname must be trimmed');
  perform tests.expect_error($q$select tests.create_user('pepa')$q$, '23505', 'nickname unique, case-insensitive');

  -- daily_rounds
  insert into daily_rounds values ('2026-10-01', 1, p1), ('2026-10-01', 2, p2);
  perform tests.expect_error(
    format($q$insert into daily_rounds values ('2026-10-01', 4, %L)$q$, p1),
    '23514', 'position must be 1..3');
  perform tests.expect_error(
    format($q$insert into daily_rounds values ('2026-10-01', 3, %L)$q$, p1),
    '23505', 'a phrase appears once per round');
  perform tests.expect_error(format($q$delete from phrases where id = %L$q$, p1),
    '23001', 'a phrase used in a round cannot be deleted');

  -- answers
  insert into answers (user_id, round_date, position, choice, is_correct)
    values (a, '2026-10-01', 1, 'charanga', true);
  perform tests.expect_error(
    format($q$insert into answers (user_id, round_date, position, choice, is_correct) values (%L, '2026-10-01', 1, 'penista', false)$q$, a),
    '23505', 'one answer per user, day and position');
  perform tests.expect_error(
    format($q$insert into answers (user_id, round_date, position, choice, is_correct) values (%L, '2026-10-01', 3, 'penista', false)$q$, a),
    '23503', 'answers must point to an existing round slot');

  -- app_config
  perform tests.expect_count('select * from app_config', 1, 'app_config ships with one row');
  perform tests.expect_error($q$insert into app_config (launch_date) values ('2026-01-01')$q$,
    '23505', 'app_config is a single row');
end
$$;
