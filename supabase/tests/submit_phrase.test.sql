-- submit_phrase(): the suggestion box RPC.

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

do $$
declare
  c uuid;
begin
  insert into tests.ids values ('ana', tests.create_user('Ana'));
  insert into auth.users default values returning id into c; -- no profile yet
  insert into tests.ids values ('nobody', c);
end
$$;

-- ---- anon cannot call it ------------------------------------------------------
set role anon;
do $$
begin
  perform tests.expect_error(
    $q$select submit_phrase('Hola', 'charanga', null, 'Ensayo')$q$, '42501', 'anon cannot submit');
end
$$;
reset role;

-- ---- logged in without profile ------------------------------------------------
select tests.login((select id from tests.ids where name = 'nobody'));
set role authenticated;
do $$
begin
  perform tests.expect_error_message(
    $q$select submit_phrase('Hola', 'charanga', null, 'Ensayo')$q$, 'no_profile', 'nickname required first');
end
$$;
reset role;

-- ---- Ana ------------------------------------------------------------------------
select tests.login((select id from tests.ids where name = 'ana'));
set role authenticated;
do $$
begin
  perform submit_phrase('  Aquí se viene a sufrir  ', 'charanga', '  El del bombo ', '  Ensayo  ');
  perform submit_phrase('Me he perdido', 'penista', 'Fulanito de Tal', 'Verbena');
  perform submit_phrase('Otra más', 'charanga', '   ', 'Procesión');

  perform tests.expect_error_message($q$select submit_phrase('   ', 'charanga', null, 'x')$q$,
    'invalid_text', 'blank text');
  perform tests.expect_error_message(format('select submit_phrase(%L, %L, null, %L)', repeat('a', 281), 'charanga', 'x'),
    'invalid_text', 'text over 280 chars');
  perform tests.expect_error_message($q$select submit_phrase('Hola', 'charanga', null, null)$q$,
    'invalid_context', 'context is required');
  perform tests.expect_error_message($q$select submit_phrase('Hola', null, null, 'x')$q$,
    'invalid_side', 'side is required');
  perform tests.expect_error_message(format('select submit_phrase(%L, %L, %L, %L)', 'Hola', 'charanga', repeat('a', 61), 'x'),
    'invalid_author', 'author over 60 chars');

  -- the client still can't read what it sent
  perform tests.expect_error('select * from phrases', '42501', 'phrases stay unreadable');
end
$$;
reset role;

do $$
declare
  ana uuid := (select id from tests.ids where name = 'ana');
begin
  perform tests.expect_count(format($q$select * from phrases where submitted_by = %L$q$, ana), 3,
    'three phrases stored');
  perform tests.expect_count(format($q$select * from phrases where submitted_by = %L and status <> 'pending'$q$, ana), 0,
    'every submission is pending');
  perform tests.expect_count(format($q$select * from phrases where submitted_by = %L and text = 'Aquí se viene a sufrir'
    and author = 'El del bombo' and context = 'Ensayo'$q$, ana), 1, 'values are trimmed');
  perform tests.expect_count(format($q$select * from phrases where submitted_by = %L and side = 'penista' and author is null$q$, ana), 1,
    'a penista author is dropped, never stored');
  perform tests.expect_count(format($q$select * from phrases where submitted_by = %L and text = 'Otra más' and author is null$q$, ana), 1,
    'a blank author becomes null');

  -- yesterday's submissions (Madrid time) don't count towards today's limit
  insert into phrases (text, side, context, submitted_by, created_at)
  select 'Ayer ' || g, 'penista', 'x', ana, now() - interval '1 day' - interval '1 hour'
  from generate_series(1, 10) g;
end
$$;

-- ---- daily limit ------------------------------------------------------------------
set role authenticated;
do $$
begin
  -- 3 sent already today; 7 more reach the limit of 10
  for i in 1..7 loop
    perform submit_phrase('Frase ' || i, 'penista', null, 'x');
  end loop;
  perform tests.expect_error_message($q$select submit_phrase('La once', 'penista', null, 'x')$q$,
    'daily_limit', 'the 11th submission of the day is rejected');
end
$$;
reset role;
