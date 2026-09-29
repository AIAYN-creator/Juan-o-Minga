-- Launch gate: before app_config.launch_at nobody gets a round or answers,
-- whatever they call; the rest of the app stays open.

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

do $$
begin
  insert into tests.ids values ('ana', tests.create_user('Ana'));
  -- the migration ships Friday 2 October 2026, 18:30 Madrid
  assert (select launch_at from app_config) = timestamptz '2026-10-02 16:30:00+00', 'launch at 18:30 Madrid (UTC+2)';
  assert (select launch_date from app_config) = date '2026-10-02', 'launch day is round #1';
  -- curtain still down for this test, whatever today's date
  update app_config set launch_at = now() + interval '1 hour';
end
$$;

-- anon can read when it opens (for the countdown)
set role anon;
do $$
begin
  perform tests.expect_count('select launch_at from app_config', 1, 'anon reads launch_at');
end
$$;
reset role;

select tests.login((select id from tests.ids where name = 'ana'));
set role authenticated;
do $$
begin
  perform tests.expect_error_message('select * from get_today_round()', 'not_launched', 'no round before launch');
  perform tests.expect_error_message($q$select * from submit_answer(1::smallint, 'charanga')$q$,
    'not_launched', 'no answers before launch');
  -- the rest stays open
  perform submit_phrase('Una frase para el estreno', 'charanga', null, 'Antes del lanzamiento');
  perform tests.expect_count('select * from get_leaderboard()', 0, 'leaderboard works (empty)');
end
$$;
reset role;

do $$
begin
  perform tests.expect_count('select * from daily_rounds', 0, 'no round was built before launch');
  perform tests.expect_count('select * from phrases where last_used_on is not null', 0, 'no phrase was used');
  update app_config set launch_at = now() - interval '1 second';
end
$$;

set role authenticated;
do $$
begin
  perform tests.expect_count('select * from get_today_round()', 3, 'curtain up: the round opens');
end
$$;
reset role;
