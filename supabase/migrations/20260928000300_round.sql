-- The daily round and answering: the anti-cheat core.
--
-- The answer key never reaches the client before the player answers:
--   * get_today_round() returns id + text only for unanswered phrases;
--   * submit_answer() records the answer and returns the verdict and the
--     reveal in the same call;
--   * the answers primary key (user_id, round_date, position) is what limits
--     each player to one answer per phrase per day, on any device.
--
-- Errors (stable messages the client maps to Spanish copy):
--   not_authenticated (28000), no_profile, already_answered,
--   not_enough_phrases (P0001), invalid_position, invalid_choice (22023)

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create function private.madrid_today() returns date
language sql stable set search_path = '' as $$
  select (now() at time zone 'Europe/Madrid')::date
$$;

-- "uno de la charanga" / the author's name / "un peñista" (never a name).
create function private.author_display(p_side public.side, p_author text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_side = 'penista' then 'un peñista'
    when p_author is not null then p_author
    else 'uno de la charanga'
  end
$$;

-- Creates today's round on first use: 3 approved phrases, never-used first,
-- then least recently used; random order among equals and in the positions.
-- A transaction-scoped advisory lock makes concurrent first calls wait, so
-- only one of them builds the round and everyone gets the same 3 phrases.
create function private.ensure_today_round() returns date
language plpgsql set search_path = '' as $$
declare
  today date := private.madrid_today();
  picked int;
begin
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

revoke execute on all functions in schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_today_round(): one row per position. Unanswered rows carry only
-- phrase_id + text; answered rows also carry the caller's choice and the reveal.
-- round_number = days since app_config.launch_date + 1 ("Juan o Minga #N").
-- ---------------------------------------------------------------------------
create function public.get_today_round()
returns table (
  round_date date,
  round_number int,
  "position" smallint,
  phrase_id uuid,
  text text,
  answered boolean,
  choice public.side,
  is_correct boolean,
  side public.side,
  author_display text,
  context text
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  uid uuid := auth.uid();
  today date;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  today := private.ensure_today_round();

  return query
  select r.round_date,
         (r.round_date - c.launch_date + 1)::int,
         r.position,
         p.id,
         p.text,
         a.user_id is not null,
         a.choice,
         a.is_correct,
         case when a.user_id is not null then p.side end,
         case when a.user_id is not null then private.author_display(p.side, p.author) end,
         case when a.user_id is not null then p.context end
  from public.daily_rounds r
  join public.phrases p on p.id = r.phrase_id
  cross join public.app_config c
  left join public.answers a
    on a.user_id = uid and a.round_date = r.round_date and a.position = r.position
  where r.round_date = today
  order by r.position;
end
$$;

-- ---------------------------------------------------------------------------
-- submit_answer(position, choice): records the answer (once, forever) and
-- returns the verdict with the reveal.
-- ---------------------------------------------------------------------------
create function public.submit_answer(p_position smallint, p_choice public.side)
returns table (
  is_correct boolean,
  side public.side,
  author_display text,
  context text
)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  uid uuid := auth.uid();
  today date;
  ph public.phrases;
  correct boolean;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if not exists (select 1 from public.profiles where id = uid) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_position is null or p_position not between 1 and 3 then
    raise exception 'invalid_position' using errcode = '22023';
  end if;
  if p_choice is null then
    raise exception 'invalid_choice' using errcode = '22023';
  end if;

  today := private.ensure_today_round();

  select p.* into ph
  from public.daily_rounds r
  join public.phrases p on p.id = r.phrase_id
  where r.round_date = today and r.position = p_position;

  correct := ph.side = p_choice;

  begin
    insert into public.answers (user_id, round_date, position, choice, is_correct)
    values (uid, today, p_position, p_choice, correct);
  exception when unique_violation then
    raise exception 'already_answered' using errcode = 'P0001';
  end;

  return query
  select correct, ph.side, private.author_display(ph.side, ph.author), ph.context;
end
$$;

revoke execute on function public.get_today_round() from public, anon;
revoke execute on function public.submit_answer(smallint, public.side) from public, anon;
grant execute on function public.get_today_round() to authenticated;
grant execute on function public.submit_answer(smallint, public.side) to authenticated;
