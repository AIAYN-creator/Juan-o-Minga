-- get_today_round() and submit_answer(). The seed (12 approved phrases) is loaded.
-- Setup makes the pick deterministic: only seed phrases 01, 02 and 03 are unused,
--   01 charanga, author "El del bombo"; 02 charanga, no author; 03 penista.

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

-- where a phrase landed today
create function tests.pos_of(phrase uuid) returns smallint
language sql security definer as $$
  select position from daily_rounds
  where round_date = (now() at time zone 'Europe/Madrid')::date and phrase_id = phrase
$$;
grant execute on function tests.pos_of(uuid) to authenticated;

do $$
declare
  nobody uuid;
begin
  insert into tests.ids values ('ana', tests.create_user('Ana')), ('beto', tests.create_user('Beto'));
  insert into auth.users default values returning id into nobody;
  insert into tests.ids values ('nobody', nobody);

  -- 9 seed phrases already used in the past; 01..03 never used
  update phrases set last_used_on = (now() at time zone 'Europe/Madrid')::date - (10 + right(id::text, 2)::int)
  where right(id::text, 2)::int >= 4;
  -- pending and rejected phrases never used either: they must still never be picked
  insert into phrases (text, side, context, status) values
    ('Pendiente 1', 'charanga', 'x', 'pending'), ('Pendiente 2', 'penista', 'x', 'pending'),
    ('Rechazada', 'penista', 'x', 'rejected');

  -- launched 4 days ago -> today is #5
  update app_config set launch_date = (now() at time zone 'Europe/Madrid')::date - 4;
end
$$;

-- ---- anon ----------------------------------------------------------------------
set role anon;
do $$
begin
  perform tests.expect_error('select * from get_today_round()', '42501', 'anon cannot get the round');
  perform tests.expect_error($q$select * from submit_answer(1::smallint, 'charanga')$q$, '42501', 'anon cannot answer');
end
$$;
reset role;

-- ---- Ana opens the round ----------------------------------------------------------
select tests.login((select id from tests.ids where name = 'ana'));
set role authenticated;
do $$
declare
  r record;
  keys text[];
begin
  perform tests.expect_count('select * from get_today_round()', 3, 'three phrases');
  assert (select array_agg(position order by position) from get_today_round()) = array[1, 2, 3]::smallint[], 'positions 1..3';
  assert (select count(distinct phrase_id) from get_today_round()) = 3, 'three different phrases';
  assert (select bool_and(right(phrase_id::text, 2) in ('01', '02', '03')) from get_today_round()),
    'never-used approved phrases are picked first (and no pending/rejected ones)';
  assert (select round_number from get_today_round() limit 1) = 5, 'round number = days since launch + 1';

  -- nothing about the answer leaves the database before answering
  for r in select * from get_today_round() loop
    assert not r.answered and r.side is null and r.author_display is null and r.context is null
       and r.choice is null and r.is_correct is null,
      'unanswered rows carry only id and text';
  end loop;

  -- still no direct access to the answer key
  perform tests.expect_error('select * from daily_rounds', '42501', 'daily_rounds stays hidden');
  perform tests.expect_error('select side from phrases', '42501', 'phrases stay hidden');
end
$$;
reset role;

do $$
begin
  perform tests.expect_count(
    $q$select * from daily_rounds where round_date = (now() at time zone 'Europe/Madrid')::date$q$, 3,
    'the round is stored');
  perform tests.expect_count(
    $q$select * from phrases where last_used_on = (now() at time zone 'Europe/Madrid')::date$q$, 3,
    'picked phrases are marked as used today');
end
$$;

-- ---- Ana answers ---------------------------------------------------------------------
set role authenticated;
do $$
declare
  p01 smallint := tests.pos_of('00000000-0000-4000-8000-000000000001');
  p02 smallint := tests.pos_of('00000000-0000-4000-8000-000000000002');
  p03 smallint := tests.pos_of('00000000-0000-4000-8000-000000000003');
  r record;
begin
  -- right: charanga with author -> the author's name
  select * into r from submit_answer(p01, 'charanga');
  assert r.is_correct and r.side = 'charanga' and r.author_display = 'El del bombo'
     and r.context = 'Ensayo de la víspera, en el almacén', 'reveal with author';

  -- wrong: it was a peñista -> never a name
  select * into r from submit_answer(p03, 'charanga');
  assert not r.is_correct and r.side = 'penista' and r.author_display = 'un peñista', 'peñista stays anonymous';

  perform tests.expect_error_message(format('select * from submit_answer(%s::smallint, %L)', p01, 'penista'),
    'already_answered', 'an answer cannot be changed');
  perform tests.expect_error_message($q$select * from submit_answer(4::smallint, 'charanga')$q$,
    'invalid_position', 'position must be 1..3');
  perform tests.expect_error_message($q$select * from submit_answer(1::smallint, null)$q$,
    'invalid_choice', 'choice is required');

  -- resuming: answered rows come back with the reveal, the other one stays hidden
  for r in select * from get_today_round() loop
    if r.position = p02 then
      assert not r.answered and r.side is null and r.author_display is null, 'unanswered stays hidden on resume';
    else
      assert r.answered and r.side is not null and r.author_display is not null and r.choice = 'charanga',
        'answered rows come back with the reveal';
    end if;
  end loop;

  -- charanga without author
  select * into r from submit_answer(p02, 'penista');
  assert not r.is_correct and r.author_display = 'uno de la charanga', 'charanga without author';

  perform tests.expect_count('select * from answers', 3, 'three answers, the daily max');
end
$$;
reset role;

-- ---- Beto: same round, his own answers ---------------------------------------------
select tests.login((select id from tests.ids where name = 'beto'));
set role authenticated;
do $$
begin
  assert (select bool_and(right(phrase_id::text, 2) in ('01', '02', '03')) from get_today_round()),
    'everyone gets the same phrases';
  assert (select count(*) from get_today_round() where answered) = 0, 'Ana''s answers are not Beto''s';
  perform submit_answer(1::smallint, 'penista');
  perform tests.expect_count('select * from answers', 1, 'Beto sees only his answer');
end
$$;
reset role;

do $$
begin
  perform tests.expect_count(
    $q$select * from daily_rounds where round_date = (now() at time zone 'Europe/Madrid')::date$q$, 3,
    'no second round was created');
end
$$;

-- ---- logged in, no nickname yet ----------------------------------------------------
select tests.login((select id from tests.ids where name = 'nobody'));
set role authenticated;
do $$
begin
  perform tests.expect_count('select * from get_today_round()', 3, 'the round can be read before onboarding');
  perform tests.expect_error_message($q$select * from submit_answer(1::smallint, 'charanga')$q$,
    'no_profile', 'answering needs a nickname');
end
$$;
reset role;
