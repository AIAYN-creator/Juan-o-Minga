-- The main ranking now opens after 3 days played (was 5), in keeping with the
-- game's 3: three phrases a day, three days to qualify. Same signature and
-- grants; only the threshold changes.

create or replace function public.get_leaderboard()
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
    select st.*, st.days_played >= 3 as qualified
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
