-- Leaderboard and personal stats.
--
-- A "day played" is a Madrid date with at least one answer. The streak is the
-- run of consecutive days played that reaches today or yesterday (so it
-- doesn't break until a whole day is skipped). A perfect day ("pleno") is 3/3.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- Per-player aggregates. Internal: only reachable through the RPCs below.
create function private.player_stats(p_user uuid default null)
returns table (
  user_id uuid,
  days_played int,
  correct int,
  answered int,
  pct numeric,
  current_streak int,
  best_streak int,
  perfect_days int
)
language sql
stable
set search_path = ''
as $$
  with per_day as (
    select a.user_id,
           a.round_date,
           count(*)::int as answered,
           (count(*) filter (where a.is_correct))::int as correct
    from public.answers a
    where p_user is null or a.user_id = p_user
    group by a.user_id, a.round_date
  ),
  -- gaps-and-islands: consecutive dates share the same (date - row_number)
  islands as (
    select d.user_id,
           d.round_date,
           d.round_date - (row_number() over (partition by d.user_id order by d.round_date))::int as grp
    from per_day d
  ),
  runs as (
    select i.user_id, count(*)::int as len, max(i.round_date) as last_day
    from islands i
    group by i.user_id, i.grp
  ),
  streaks as (
    select r.user_id,
           max(r.len) as best,
           coalesce(max(r.len) filter (
             where r.last_day >= (now() at time zone 'Europe/Madrid')::date - 1
           ), 0) as current
    from runs r
    group by r.user_id
  )
  select d.user_id,
         count(*)::int,
         sum(d.correct)::int,
         sum(d.answered)::int,
         round(100.0 * sum(d.correct) / nullif(sum(d.answered), 0), 1),
         s.current::int,
         s.best::int,
         (count(*) filter (where d.correct = 3))::int
  from per_day d
  join streaks s on s.user_id = d.user_id
  group by d.user_id, s.current, s.best
$$;

revoke execute on function private.player_stats(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_leaderboard(): everyone who has played, nickname only (never ids, email
-- or Google name). `qualified` = at least 5 days played: the main ranking.
-- The rest are the "aspirantes". `rank` is computed within each group, ties
-- share a rank. `is_me` marks the caller's row (always false for anon).
-- ---------------------------------------------------------------------------
create function public.get_leaderboard()
returns table (
  rank int,
  nickname text,
  days_played int,
  correct int,
  answered int,
  pct numeric,
  current_streak int,
  best_streak int,
  perfect_days int,
  qualified boolean,
  is_me boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with s as (
    select st.*, st.days_played >= 5 as qualified
    from private.player_stats() st
  )
  select (rank() over (
            partition by s.qualified
            order by s.pct desc, s.correct desc, s.days_played desc
          ))::int,
         p.nickname,
         s.days_played,
         s.correct,
         s.answered,
         s.pct,
         s.current_streak,
         s.best_streak,
         s.perfect_days,
         s.qualified,
         coalesce(s.user_id = auth.uid(), false)
  from s
  join public.profiles p on p.id = s.user_id
  order by s.qualified desc, 1, p.nickname
$$;

revoke execute on function public.get_leaderboard() from public;
grant execute on function public.get_leaderboard() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_my_stats(): the caller's own metrics plus how their days ended
-- (dist_0..dist_3 = days finished with 0..3 right). Today only counts in the
-- distribution once all 3 are answered; past days count as they were left.
-- ---------------------------------------------------------------------------
create function public.get_my_stats()
returns table (
  days_played int,
  correct int,
  answered int,
  pct numeric,
  current_streak int,
  best_streak int,
  perfect_days int,
  dist_0 int,
  dist_1 int,
  dist_2 int,
  dist_3 int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  uid uuid := auth.uid();
  today date := (now() at time zone 'Europe/Madrid')::date;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  return query
  with mine as (
    select * from private.player_stats(uid)
  ),
  finished as (
    select (count(*) filter (where a.is_correct))::int as c
    from public.answers a
    where a.user_id = uid
    group by a.round_date
    having count(*) = 3 or a.round_date < today
  )
  select coalesce(m.days_played, 0),
         coalesce(m.correct, 0),
         coalesce(m.answered, 0),
         m.pct,
         coalesce(m.current_streak, 0),
         coalesce(m.best_streak, 0),
         coalesce(m.perfect_days, 0),
         (select count(*) from finished f where f.c = 0)::int,
         (select count(*) from finished f where f.c = 1)::int,
         (select count(*) from finished f where f.c = 2)::int,
         (select count(*) from finished f where f.c = 3)::int
  from (select 1) as one
  left join mine m on true;
end
$$;

revoke execute on function public.get_my_stats() from public, anon;
grant execute on function public.get_my_stats() to authenticated;
