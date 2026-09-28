-- submit_phrase: the suggestion box. The only way a user can add a phrase.
-- Everything lands as 'pending' until the admin approves it in the table
-- editor, so nothing sent here can reach the game on its own.
--
-- Errors (raised with a stable message the client maps to Spanish copy):
--   not_authenticated (28000)  no session
--   no_profile        (P0001)  logged in but hasn't picked a nickname yet
--   invalid_side / invalid_text / invalid_context / invalid_author (22023)
--   daily_limit       (P0001)  already 10 submissions today (Madrid time)

create index phrases_submitted_by_idx on public.phrases (submitted_by, created_at)
  where submitted_by is not null;

create function public.submit_phrase(
  p_text text,
  p_side public.side,
  p_author text default null,
  p_context text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  today date := (now() at time zone 'Europe/Madrid')::date;
  clean_text text := btrim(p_text);
  clean_context text := btrim(p_context);
  clean_author text := nullif(btrim(p_author), '');
  sent_today int;
  new_id uuid;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if not exists (select 1 from public.profiles where id = uid) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;

  if p_side is null then
    raise exception 'invalid_side' using errcode = '22023';
  end if;
  if clean_text is null or char_length(clean_text) not between 1 and 280 then
    raise exception 'invalid_text' using errcode = '22023';
  end if;
  if clean_context is null or char_length(clean_context) not between 1 and 280 then
    raise exception 'invalid_context' using errcode = '22023';
  end if;
  -- Peñistas are never named: drop the author instead of storing it.
  if p_side = 'penista' then
    clean_author := null;
  end if;
  if clean_author is not null and char_length(clean_author) > 60 then
    raise exception 'invalid_author' using errcode = '22023';
  end if;

  -- Serialise per user so parallel calls can't sneak past the daily limit.
  perform pg_advisory_xact_lock(hashtextextended('submit_phrase:' || uid::text, 0));

  select count(*) into sent_today
  from public.phrases
  where submitted_by = uid
    and (created_at at time zone 'Europe/Madrid')::date = today;

  if sent_today >= 10 then
    raise exception 'daily_limit' using errcode = 'P0001';
  end if;

  insert into public.phrases (text, side, author, context, submitted_by)
  values (clean_text, p_side, clean_author, clean_context, uid)
  returning id into new_id;

  return new_id;
end
$$;

revoke execute on function public.submit_phrase(text, public.side, text, text) from public, anon;
grant execute on function public.submit_phrase(text, public.side, text, text) to authenticated;
