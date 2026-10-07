-- v2: rewards for the suggestion box.
--
-- * Megáfono de oro (📣): whoever has the most approved phrases from the box.
--   Only *who* leads is public, never how many phrases each player sent.
-- * Streak shields (🛡️): every 3 approved phrases earn one, 2 at most. When a
--   player comes back after missing days, one shield per missed day is spent
--   (only if they cover the whole gap) and those days keep the streak alive.
--   A shielded day never counts as played: no answers, no %, no days_played.

-- ---------------------------------------------------------------------------
-- Wallets and shielded days. Private: only the functions below touch them.
-- ---------------------------------------------------------------------------
create table private.shield_wallets (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  shields smallint not null default 0 check (shields between 0 and 2),
  progress smallint not null default 0 check (progress between 0 and 2)
);

create table private.shield_days (
  user_id uuid not null references public.profiles (id) on delete cascade,
  day date not null,
  spent_on date not null, -- the day the player came back and the shield was used
  primary key (user_id, day)
);

alter table private.shield_wallets enable row level security;
alter table private.shield_days enable row level security;
revoke all on private.shield_wallets, private.shield_days from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Earning: a box phrase turning 'approved' moves its sender one step; every
-- third step is a shield, unless they already hold 2 (then it's just reset).
-- ---------------------------------------------------------------------------
create function private.earn_shield()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'approved' and new.submitted_by is not null
     and (tg_op = 'INSERT' or old.status is distinct from 'approved') then
    insert into private.shield_wallets as w (user_id, shields, progress)
    values (new.submitted_by, 0, 1)
    on conflict (user_id) do update
      set shields = case when w.progress = 2 then least(2, w.shields + 1) else w.shields end,
          progress = (w.progress + 1) % 3;
  end if;
  return null;
end
$$;

create trigger phrases_earn_shield
after insert or update of status on public.phrases
for each row execute function private.earn_shield();

-- ---------------------------------------------------------------------------
-- Spending: on every answer, if the player skipped days since the last day
-- they played (or had shielded) and their shields cover the whole gap, those
-- days become shielded. The wallet row lock makes it once per gap, even with
-- answers arriving in parallel.
-- ---------------------------------------------------------------------------
create function private.spend_shields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  bal smallint;
  last_day date;
  missed int;
begin
  select w.shields into bal
  from private.shield_wallets w
  where w.user_id = new.user_id
  for update;

  if coalesce(bal, 0) = 0 then
    return null;
  end if;

  select greatest(
           (select max(a.round_date) from public.answers a
             where a.user_id = new.user_id and a.round_date < new.round_date),
           (select max(s.day) from private.shield_days s
             where s.user_id = new.user_id and s.day < new.round_date))
  into last_day;

  if last_day is null then
    return null;
  end if;

  missed := new.round_date - last_day - 1;
  if missed < 1 or missed > bal then
    return null; -- nothing to cover, or not enough: the streak breaks, shields are kept
  end if;

  insert into private.shield_days (user_id, day, spent_on)
  select new.user_id, last_day + g, new.round_date
  from generate_series(1, missed) g;

  update private.shield_wallets w
  set shields = w.shields - missed
  where w.user_id = new.user_id;

  return null;
end
$$;

create trigger answers_spend_shields
after insert on public.answers
for each row execute function private.spend_shields();

revoke execute on function private.earn_shield(), private.spend_shields() from public, anon, authenticated;

-- Phrases approved before v2 count too.
insert into private.shield_wallets (user_id, shields, progress)
select p.submitted_by, least(2, count(*) / 3), count(*) % 3
from public.phrases p
where p.status = 'approved' and p.submitted_by is not null
group by p.submitted_by;

-- ---------------------------------------------------------------------------
-- Streaks now run over played *and* shielded days, and a streak stays alive
-- while the days missed up to yesterday fit in the player's shields (they are
-- spent for real when the player comes back). Same signature as before.
-- ---------------------------------------------------------------------------
create or replace function private.player_stats(p_user uuid default null)
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
  covered as (
    select d.user_id, d.round_date as day from per_day d
    union
    select s.user_id, s.day from private.shield_days s
    where p_user is null or s.user_id = p_user
  ),
  -- gaps-and-islands: consecutive dates share the same (date - row_number)
  islands as (
    select c.user_id,
           c.day,
           c.day - (row_number() over (partition by c.user_id order by c.day))::int as grp
    from covered c
  ),
  runs as (
    select i.user_id, count(*)::int as len, max(i.day) as last_day
    from islands i
    group by i.user_id, i.grp
  ),
  streaks as (
    select r.user_id,
           max(r.len) as best,
           coalesce(max(r.len) filter (
             where r.last_day >= (now() at time zone 'Europe/Madrid')::date - 1 - coalesce(w.shields, 0)
           ), 0) as current
    from runs r
    left join private.shield_wallets w on w.user_id = r.user_id
    group by r.user_id, w.shields
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

-- Approved box phrases per sender. Internal, like player_stats.
create function private.contributions()
returns table (user_id uuid, approved int, is_top boolean)
language sql
stable
set search_path = ''
as $$
  with c as (
    select p.submitted_by as user_id, count(*)::int as approved
    from public.phrases p
    where p.status = 'approved' and p.submitted_by is not null
    group by p.submitted_by
  )
  select c.user_id, c.approved, c.approved = max(c.approved) over ()
  from c
$$;

revoke execute on function private.contributions() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_leaderboard(): + shields and top_contributor (the 📣). New columns, so
-- drop and create; same grants.
-- ---------------------------------------------------------------------------
drop function public.get_leaderboard();

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
  is_me boolean,
  shields int,
  top_contributor boolean
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
         coalesce(s.user_id = auth.uid(), false),
         coalesce(w.shields, 0)::int,
         coalesce(c.is_top, false)
  from s
  join public.profiles p on p.id = s.user_id
  left join private.shield_wallets w on w.user_id = s.user_id
  left join private.contributions() c on c.user_id = s.user_id
  order by s.qualified desc, 1, p.nickname
$$;

revoke execute on function public.get_leaderboard() from public;
grant execute on function public.get_leaderboard() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_my_stats(): + the caller's box and shield numbers. Only the caller ever
-- sees their own count of approved phrases.
-- ---------------------------------------------------------------------------
drop function public.get_my_stats();

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
  dist_3 int,
  approved_phrases int,
  top_contributor boolean,
  shields int,
  shield_progress int,
  shield_saved_today boolean
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
         (select count(*) from finished f where f.c = 3)::int,
         coalesce((select c.approved from private.contributions() c where c.user_id = uid), 0),
         coalesce((select c.is_top from private.contributions() c where c.user_id = uid), false),
         coalesce((select w.shields from private.shield_wallets w where w.user_id = uid), 0)::int,
         coalesce((select w.progress from private.shield_wallets w where w.user_id = uid), 0)::int,
         exists (select 1 from private.shield_days sd where sd.user_id = uid and sd.spent_on = today)
  from (select 1) as one
  left join mine m on true;
end
$$;

revoke execute on function public.get_my_stats() from public, anon;
grant execute on function public.get_my_stats() to authenticated;
