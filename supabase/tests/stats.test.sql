-- get_leaderboard() and get_my_stats().
--
-- Days are relative to today (Madrid), d = 0 is today, d = 1 yesterday...
--   Ana:   d 5..0, all 3 answered, right per day 0,3,1,2,3,3 (d5 -> d0)
--          -> 6 days, 12/18 = 66.7 %, 3 plenos, streak 6 (best 6)
--   Beto:  d 9..5 and d 2, all right
--          -> 6 days, 18/18 = 100 %, 6 plenos, streak 0 (best 5)
--   Carla: d 1 (2 of 3 right) and today only 1 answered (right)
--          -> 2 days, aspirante, streak 2
--   Eva:   d 4..2, all wrong
--          -> 3 days, exactly the threshold: in the ranking, last, 0 %
--   Dani:  nickname, never played

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

create function tests.day(d int) returns date
language sql as $$ select (now() at time zone 'Europe/Madrid')::date - d $$;

create function tests.play(uid uuid, d int, results boolean[]) returns void
language plpgsql as $$
begin
  for i in 1..array_length(results, 1) loop
    insert into answers (user_id, round_date, position, choice, is_correct)
    values (uid, tests.day(d), i, 'charanga', results[i]);
  end loop;
end
$$;

do $$
declare
  p1 uuid; p2 uuid; p3 uuid;
  ana uuid := tests.create_user('Ana');
  beto uuid := tests.create_user('Beto');
  carla uuid := tests.create_user('Carla');
  dani uuid := tests.create_user('Dani');
  eva uuid := tests.create_user('Eva');
begin
  insert into tests.ids values ('ana', ana), ('beto', beto), ('carla', carla), ('dani', dani), ('eva', eva);
  insert into phrases (text, side, context, status) values ('Uno', 'charanga', 'x', 'approved') returning id into p1;
  insert into phrases (text, side, context, status) values ('Dos', 'penista', 'x', 'approved') returning id into p2;
  insert into phrases (text, side, context, status) values ('Tres', 'charanga', 'x', 'approved') returning id into p3;
  for d in 0..9 loop
    insert into daily_rounds values (tests.day(d), 1, p1), (tests.day(d), 2, p2), (tests.day(d), 3, p3);
  end loop;

  perform tests.play(ana, 5, array[false, false, false]);
  perform tests.play(ana, 4, array[true, true, true]);
  perform tests.play(ana, 3, array[true, false, false]);
  perform tests.play(ana, 2, array[true, true, false]);
  perform tests.play(ana, 1, array[true, true, true]);
  perform tests.play(ana, 0, array[true, true, true]);

  for d in 5..9 loop
    perform tests.play(beto, d, array[true, true, true]);
  end loop;
  perform tests.play(beto, 2, array[true, true, true]);

  perform tests.play(carla, 1, array[true, true, false]);
  perform tests.play(carla, 0, array[true]);

  for d in 2..4 loop
    perform tests.play(eva, d, array[false, false, false]);
  end loop;
end
$$;

-- ---- leaderboard, as anon ---------------------------------------------------------
set role anon;
do $$
declare
  r record;
begin
  perform tests.expect_count('select * from get_leaderboard()', 4, 'only players who played are listed');

  select * into r from get_leaderboard() where nickname = 'Beto';
  assert r.rank = 1 and r.qualified, 'Beto (100 %) leads the ranking';
  assert r.days_played = 6 and r.correct = 18 and r.answered = 18 and r.pct = 100.0, 'Beto totals';
  assert r.current_streak = 0 and r.best_streak = 5, format('Beto streak: skipped yesterday, best 5 (got %s/%s)', r.current_streak, r.best_streak);
  assert r.perfect_days = 6, 'Beto plenos';
  assert not r.is_me, 'anon is nobody';

  select * into r from get_leaderboard() where nickname = 'Ana';
  assert r.rank = 2 and r.qualified, 'Ana second';
  assert r.days_played = 6 and r.correct = 12 and r.answered = 18 and r.pct = 66.7, format('Ana totals (pct %s)', r.pct);
  assert r.current_streak = 6 and r.best_streak = 6, format('Ana streak reaches today (got %s/%s)', r.current_streak, r.best_streak);
  assert r.perfect_days = 3, 'Ana plenos';

  select * into r from get_leaderboard() where nickname = 'Eva';
  assert r.qualified and r.rank = 3, 'Eva qualifies with exactly 3 days';

  select * into r from get_leaderboard() where nickname = 'Carla';
  assert not r.qualified and r.rank = 1, 'Carla is an aspirante (under 3 days)';
  assert r.current_streak = 2, format('Carla streak yesterday + today (got %s)', r.current_streak);

  -- ranking rows first, then aspirantes
  assert (select array_agg(nickname) from get_leaderboard()) = array['Beto', 'Ana', 'Eva', 'Carla'], 'order';

  -- nothing but these columns ever leaves the database
  assert (select array_agg(k order by k) from jsonb_object_keys(
            (select to_jsonb(l) from get_leaderboard() l limit 1)) k)
    = array['answered', 'best_streak', 'correct', 'current_streak', 'days_played', 'is_me',
            'nickname', 'pct', 'perfect_days', 'qualified', 'rank', 'shields', 'top_contributor'],
    'leaderboard exposes nickname and stats only (no ids, no email, no phrase counts)';

  perform tests.expect_error('select * from get_my_stats()', '42501', 'anon has no personal stats');
  perform tests.expect_error('select * from private.player_stats()', '42501', 'private schema is off limits');
end
$$;
reset role;

-- ---- Ana --------------------------------------------------------------------------
select tests.login((select id from tests.ids where name = 'ana'));
set role authenticated;
do $$
declare
  r record;
begin
  assert (select count(*) from get_leaderboard() where is_me) = 1, 'exactly one row is mine';
  assert (select nickname from get_leaderboard() where is_me) = 'Ana', 'and it is Ana';

  select * into r from get_my_stats();
  assert r.days_played = 6 and r.correct = 12 and r.answered = 18 and r.pct = 66.7, 'Ana my_stats totals';
  assert r.current_streak = 6 and r.best_streak = 6 and r.perfect_days = 3, 'Ana my_stats streaks';
  assert (r.dist_0, r.dist_1, r.dist_2, r.dist_3) = (1, 1, 1, 3),
    format('Ana distribution (got %s %s %s %s)', r.dist_0, r.dist_1, r.dist_2, r.dist_3);

  perform tests.expect_error('select * from private.player_stats()', '42501', 'users cannot reach private stats');
end
$$;
reset role;

-- ---- Carla: today unfinished -------------------------------------------------------
select tests.login((select id from tests.ids where name = 'carla'));
set role authenticated;
do $$
declare
  r record;
begin
  select * into r from get_my_stats();
  assert r.days_played = 2 and r.answered = 4 and r.correct = 3, 'Carla totals include today';
  assert (r.dist_0, r.dist_1, r.dist_2, r.dist_3) = (0, 0, 1, 0),
    format('unfinished today is left out of the distribution (got %s %s %s %s)', r.dist_0, r.dist_1, r.dist_2, r.dist_3);
end
$$;
reset role;

-- ---- Dani: never played ------------------------------------------------------------
select tests.login((select id from tests.ids where name = 'dani'));
set role authenticated;
do $$
declare
  r record;
begin
  perform tests.expect_count('select * from get_my_stats()', 1, 'always one row');
  select * into r from get_my_stats();
  assert r.days_played = 0 and r.answered = 0 and r.current_streak = 0 and r.pct is null, 'zeros for a new player';
  assert (r.dist_0, r.dist_1, r.dist_2, r.dist_3) = (0, 0, 0, 0), 'empty distribution';
end
$$;
reset role;
