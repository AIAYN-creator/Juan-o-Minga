-- What's new: the last release notes each player has seen, so the panel shows
-- once per version and per person, on any device. Players read it with their
-- own profile (the existing select grant) and only move it forward through
-- mark_news_seen(); there is no direct update grant on the column.

alter table public.profiles add column news_seen text
  constraint news_seen_format check (news_seen ~ '^[0-9]+\.[0-9]+\.[0-9]+$');

-- mark_news_seen('2.0.0'): the caller's own profile, never backwards.
-- Errors: not_authenticated (28000), bad_version (22023).
create function public.mark_news_seen(p_version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if p_version is null or p_version !~ '^[0-9]+\.[0-9]+\.[0-9]+$' then
    raise exception 'bad_version' using errcode = '22023';
  end if;

  update public.profiles p
  set news_seen = p_version
  where p.id = uid
    and (p.news_seen is null
         or string_to_array(p.news_seen, '.')::int[] < string_to_array(p_version, '.')::int[]);
end
$$;

revoke execute on function public.mark_news_seen(text) from public, anon;
grant execute on function public.mark_news_seen(text) to authenticated;
