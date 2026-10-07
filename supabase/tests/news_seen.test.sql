-- mark_news_seen(): each player moves their own "last release notes seen"
-- forward, never back, and nobody else's.

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

do $$
begin
  insert into tests.ids values ('ana', tests.create_user('Ana')), ('beto', tests.create_user('Beto'));
end
$$;

-- ---- anon -------------------------------------------------------------------------
set role anon;
do $$
begin
  perform tests.expect_error($q$select mark_news_seen('2.0.0')$q$, '42501', 'anon cannot mark');
end
$$;
reset role;

-- ---- Ana --------------------------------------------------------------------------
select tests.login((select id from tests.ids where name = 'ana'));
set role authenticated;
do $$
begin
  assert (select news_seen from profiles) is null, 'nothing seen yet';

  perform mark_news_seen('2.0.0');
  assert (select news_seen from profiles) = '2.0.0', 'marked 2.0.0';

  perform mark_news_seen('1.0.0');
  assert (select news_seen from profiles) = '2.0.0', 'never backwards';

  perform mark_news_seen('10.0.0');
  assert (select news_seen from profiles) = '10.0.0', 'compared as numbers, not text';

  perform tests.expect_error_message($q$select mark_news_seen('2.0')$q$, 'bad_version', 'version format');
  perform tests.expect_error_message($q$select mark_news_seen('2.0.0; drop table x')$q$, 'bad_version', 'no junk');

  -- no direct writes to the column
  perform tests.expect_error($q$update profiles set news_seen = '0.0.1'$q$, '42501', 'no direct update of news_seen');
end
$$;
reset role;

-- ---- Beto is untouched ------------------------------------------------------------
do $$
begin
  assert (select news_seen from profiles where id = (select id from tests.ids where name = 'beto')) is null,
    'only the caller''s profile changes';
end
$$;
