-- Test helpers, loaded after the migrations. Run as the superuser.

create schema tests;
grant usage on schema tests to anon, authenticated;

-- Creates an auth user plus profile and returns its id.
create function tests.create_user(nickname text) returns uuid
language plpgsql security definer as $$
declare
  uid uuid;
begin
  insert into auth.users default values returning id into uid;
  insert into public.profiles (id, nickname) values (uid, nickname);
  return uid;
end
$$;

-- Makes auth.uid() return this user. Follow with `set role authenticated;`.
create function tests.login(uid uuid) returns void
language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', uid)::text, false)
$$;

create function tests.logout() returns void
language sql as $$
  select set_config('request.jwt.claims', '', false)
$$;

-- Runs sql as the current role and asserts it fails with the given SQLSTATE.
create function tests.expect_error(sql text, expected_state text, label text)
returns void
language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    if sqlstate <> expected_state then
      raise exception '% -- expected SQLSTATE %, got % (%)', label, expected_state, sqlstate, sqlerrm;
    end if;
    return;
  end;
  raise exception '% -- expected SQLSTATE %, but it succeeded', label, expected_state;
end
$$;

-- Asserts that a query returns the expected count.
create function tests.expect_count(sql text, expected bigint, label text)
returns void
language plpgsql as $$
declare
  n bigint;
begin
  execute format('select count(*) from (%s) q', sql) into n;
  if n <> expected then
    raise exception '% -- expected % rows, got %', label, expected, n;
  end if;
end
$$;

grant execute on all functions in schema tests to anon, authenticated;

-- Like expect_error, but matches the exception message (our RPCs raise stable
-- snake_case messages such as 'daily_limit') instead of the SQLSTATE.
create function tests.expect_error_message(sql text, expected_message text, label text)
returns void
language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    if sqlerrm <> expected_message then
      raise exception '% -- expected error "%", got % (%)', label, expected_message, sqlstate, sqlerrm;
    end if;
    return;
  end;
  raise exception '% -- expected error "%", but it succeeded', label, expected_message;
end
$$;

grant execute on function tests.expect_error_message(text, text, text) to anon, authenticated;
