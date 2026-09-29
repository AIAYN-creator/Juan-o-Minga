-- Launch gate: nobody plays before the curtain rises.
--
-- app_config.launch_at is the exact opening moment (Friday 2 October 2026,
-- 18:30 Madrid). Before it, building or reading the round fails with
-- 'not_launched', so the answer key can't be reached early even by calling
-- the API directly. Login, nickname, leaderboard and suggestion box stay open.
-- launch_date moves to the same day, so that Friday is "Juan o Minga #1".
-- Both values can be changed in the table editor if the date moves.

alter table public.app_config
  add column launch_at timestamptz not null
    default (timestamp '2026-10-02 18:30' at time zone 'Europe/Madrid');

update public.app_config
set launch_date = date '2026-10-02',
    launch_at = timestamp '2026-10-02 18:30' at time zone 'Europe/Madrid';

-- The client reads launch_at to show the countdown (app_config is already
-- readable by anon and authenticated).

create or replace function private.ensure_today_round() returns date
language plpgsql set search_path = '' as $$
declare
  today date := private.madrid_today();
  picked int;
begin
  if now() < (select launch_at from public.app_config) then
    raise exception 'not_launched' using errcode = 'P0001';
  end if;

  if exists (select 1 from public.daily_rounds where round_date = today) then
    return today;
  end if;

  perform pg_advisory_xact_lock(hashtextextended('daily_round', 0));

  if exists (select 1 from public.daily_rounds where round_date = today) then
    return today;
  end if;

  with chosen as (
    select p.id
    from public.phrases p
    where p.status = 'approved'
    order by p.last_used_on asc nulls first, random()
    limit 3
  ),
  numbered as (
    select id, (row_number() over (order by random()))::smallint as position
    from chosen
  ),
  inserted as (
    insert into public.daily_rounds (round_date, position, phrase_id)
    select today, n.position, n.id from numbered n
    returning phrase_id
  )
  update public.phrases p
  set last_used_on = today
  from inserted i
  where p.id = i.phrase_id;

  get diagnostics picked = row_count;
  if picked < 3 then
    raise exception 'not_enough_phrases' using errcode = 'P0001';
  end if;

  return today;
end
$$;

revoke execute on function private.ensure_today_round() from public, anon, authenticated;
