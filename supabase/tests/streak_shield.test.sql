-- Streak shields (🛡️) and the Megáfono de oro (📣).
--
-- Days are relative to today (Madrid), d = 0 is today.
--   Pepa: 9 box phrases approved -> 2 shields (capped), megáfono; never plays
--   Leo:  3 approved -> 1 shield. Plays d3, d2, skips d1, plays d0
--         -> the shield covers d1: streak 4, days played 3, 0 shields left
--   Mia:  3 approved -> 1 shield. Plays d4, d3, skips d2 and d1, plays d0
--         -> 1 shield can't cover 2 days: streak 1, shield kept
--   Noa:  3 approved -> 1 shield. Plays d3, d2, skips d1, not yet today
--         -> streak still 2 on the board (the shield will cover d1)
--   Ivo:  no shields, same days as Noa -> streak 0
--   Uxue: 2 approved, 1 pending, 1 rejected, 1 loaded by hand -> progress 2, 0 shields

create table tests.ids (name text primary key, id uuid);

create function tests.day(d int) returns date
language sql as $$ select (now() at time zone 'Europe/Madrid')::date - d $$;

create function tests.play(uid uuid, d int) returns void
language sql as $$
  insert into answers (user_id, round_date, position, choice, is_correct)
  values (uid, tests.day(d), 1, 'charanga', true),
         (uid, tests.day(d), 2, 'charanga', true),
         (uid, tests.day(d), 3, 'charanga', false)
$$;

-- n box phrases from uid, sent as pending and then approved by the jury
create function tests.approve_box(uid uuid, n int) returns void
language plpgsql as $$
declare
  pid uuid;
begin
  for i in 1..n loop
    insert into phrases (text, side, context, status, submitted_by)
    values ('Del buzón ' || i, 'charanga', 'x', 'pending', uid) returning id into pid;
    update phrases set status = 'approved' where id = pid;
  end loop;
end
$$;

do $$
declare
  p1 uuid; p2 uuid; p3 uuid;
  pepa uuid := tests.create_user('Pepa');
  leo uuid := tests.create_user('Leo');
  mia uuid := tests.create_user('Mia');
  noa uuid := tests.create_user('Noa');
  ivo uuid := tests.create_user('Ivo');
  uxue uuid := tests.create_user('Uxue');
begin
  insert into tests.ids values ('pepa', pepa), ('leo', leo), ('mia', mia), ('noa', noa), ('ivo', ivo), ('uxue', uxue);
  insert into phrases (text, side, context, status) values ('Uno', 'charanga', 'x', 'approved') returning id into p1;
  insert into phrases (text, side, context, status) values ('Dos', 'penista', 'x', 'approved') returning id into p2;
  insert into phrases (text, side, context, status) values ('Tres', 'charanga', 'x', 'approved') returning id into p3;
  for d in 0..9 loop
    insert into daily_rounds values (tests.day(d), 1, p1), (tests.day(d), 2, p2), (tests.day(d), 3, p3);
  end loop;

  -- earning
  perform tests.approve_box(pepa, 9);
  perform tests.approve_box(leo, 3);
  perform tests.approve_box(mia, 3);
  perform tests.approve_box(noa, 3);
  perform tests.approve_box(uxue, 2);
  insert into phrases (text, side, context, status, submitted_by) values ('Pendiente', 'charanga', 'x', 'pending', uxue);
  insert into phrases (text, side, context, status, submitted_by) values ('Rechazada', 'charanga', 'x', 'rejected', uxue);
  insert into phrases (text, side, context, status) values ('A mano', 'charanga', 'x', 'approved');

  -- an approved phrase saved again doesn't count twice
  update phrases set status = 'approved' where submitted_by = uxue and status = 'approved';

  -- playing
  perform tests.play(leo, 3); perform tests.play(leo, 2); perform tests.play(leo, 0);
  perform tests.play(mia, 4); perform tests.play(mia, 3); perform tests.play(mia, 0);
  perform tests.play(noa, 3); perform tests.play(noa, 2);
  perform tests.play(ivo, 3); perform tests.play(ivo, 2);
end
$$;

-- ---- wallets (as the superuser) ---------------------------------------------------
do $$
declare
  r record;
begin
  select * into r from private.shield_wallets where user_id = (select id from tests.ids where name = 'pepa');
  assert r.shields = 2, format('9 approved -> 2 shields, capped (got %s)', r.shields);

  select * into r from private.shield_wallets where user_id = (select id from tests.ids where name = 'uxue');
  assert r.shields = 0 and r.progress = 2,
    format('only approved box phrases count, once each (got %s shields, progress %s)', r.shields, r.progress);

  assert (select count(*) from private.shield_days where user_id = (select id from tests.ids where name = 'leo')) = 1,
    'Leo: one shielded day';
  assert (select day from private.shield_days where user_id = (select id from tests.ids where name = 'leo')) = tests.day(1),
    'Leo: the shielded day is yesterday';
  assert (select shields from private.shield_wallets where user_id = (select id from tests.ids where name = 'leo')) = 0,
    'Leo spent his shield';
  assert (select shields from private.shield_wallets where user_id = (select id from tests.ids where name = 'mia')) = 1,
    'Mia keeps her shield: it could not cover 2 days';
  assert not exists (select 1 from private.shield_days where user_id = (select id from tests.ids where name = 'mia')),
    'Mia: nothing shielded';
end
$$;

-- ---- the board, as anon -----------------------------------------------------------
set role anon;
do $$
declare
  r record;
begin
  select * into r from get_leaderboard() where nickname = 'Leo';
  assert r.current_streak = 4 and r.best_streak = 4, format('Leo: shielded day joins the streak (got %s/%s)', r.current_streak, r.best_streak);
  assert r.days_played = 3 and r.answered = 9, 'Leo: a shielded day is not a day played';
  assert r.shields = 0 and not r.top_contributor, 'Leo: no shields left, no megáfono';

  select * into r from get_leaderboard() where nickname = 'Mia';
  assert r.current_streak = 1 and r.best_streak = 2, format('Mia: streak broke (got %s/%s)', r.current_streak, r.best_streak);
  assert r.shields = 1, 'Mia: shield on the board';

  select * into r from get_leaderboard() where nickname = 'Noa';
  assert r.current_streak = 2, format('Noa: streak alive while her shield covers yesterday (got %s)', r.current_streak);

  select * into r from get_leaderboard() where nickname = 'Ivo';
  assert r.current_streak = 0, format('Ivo: no shield, streak gone (got %s)', r.current_streak);

  -- Pepa never played, so she isn't on the board; nobody else leads the box
  assert not exists (select 1 from get_leaderboard() where top_contributor), 'megáfono only for the top sender';

  perform tests.expect_error('select * from private.shield_wallets', '42501', 'wallets are private');
  perform tests.expect_error('select * from private.contributions()', '42501', 'contributions are private');
end
$$;
reset role;

-- ---- Leo's own stats --------------------------------------------------------------
select tests.login((select id from tests.ids where name = 'leo'));
set role authenticated;
do $$
declare
  r record;
begin
  select * into r from get_my_stats();
  assert r.shield_saved_today, 'Leo: saved today';
  assert r.shields = 0 and r.shield_progress = 0 and r.approved_phrases = 3, 'Leo: wallet and box numbers';
  assert not r.top_contributor, 'Leo is not the top sender';
  assert r.current_streak = 4 and r.days_played = 3, 'Leo: streak and days in my stats';

  perform tests.expect_error('select * from private.shield_days', '42501', 'shielded days are private');
end
$$;
reset role;

-- ---- Pepa leads the box; a tie shares the megáfono --------------------------------
select tests.login((select id from tests.ids where name = 'pepa'));
set role authenticated;
do $$
declare
  r record;
begin
  select * into r from get_my_stats();
  assert r.top_contributor and r.approved_phrases = 9, 'Pepa holds the megáfono';
  assert r.shields = 2 and not r.shield_saved_today, 'Pepa: 2 shields, none used';
end
$$;
reset role;

select tests.approve_box((select id from tests.ids where name = 'leo'), 6);
select tests.play((select id from tests.ids where name = 'pepa'), 0);

set role anon;
do $$
begin
  assert (select array_agg(nickname order by nickname) from get_leaderboard() where top_contributor)
    = array['Leo', 'Pepa'], 'tied at 9: both carry the megáfono';
end
$$;
reset role;
