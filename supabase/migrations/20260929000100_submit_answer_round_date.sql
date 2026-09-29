-- submit_answer() learns which round the client is answering.
--
-- A player who loaded the round at 23:59 and answers after midnight (Madrid)
-- would otherwise have their choice judged against today's phrase at that
-- position, a phrase they never saw. With p_round_date the server refuses it
-- ('round_over') and the client reloads the new round.
-- Old two-argument calls keep working (p_round_date defaults to null).

drop function public.submit_answer(smallint, public.side);

create function public.submit_answer(
  p_position smallint,
  p_choice public.side,
  p_round_date date default null
)
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
  if p_round_date is not null and p_round_date <> private.madrid_today() then
    raise exception 'round_over' using errcode = 'P0001';
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

revoke execute on function public.submit_answer(smallint, public.side, date) from public, anon;
grant execute on function public.submit_answer(smallint, public.side, date) to authenticated;
