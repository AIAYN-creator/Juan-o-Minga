-- What the public client (anon key) can and cannot do.

create table tests.ids (name text primary key, id uuid);
grant select on tests.ids to anon, authenticated;

do $$
declare
  a uuid := tests.create_user('Ana');
  b uuid := tests.create_user('Beto');
  c uuid;
  p uuid;
begin
  insert into auth.users default values returning id into c; -- logged in, no profile yet
  insert into phrases (text, side, context, status) values ('Hola', 'charanga', 'Ensayo', 'approved')
    returning id into p;
  insert into daily_rounds values ('2026-10-01', 1, p);
  insert into answers (user_id, round_date, position, choice, is_correct) values
    (a, '2026-10-01', 1, 'charanga', true),
    (b, '2026-10-01', 1, 'penista', false);
  insert into tests.ids values ('a', a), ('b', b), ('c', c), ('p', p);
end
$$;

-- ---- anon: only app_config ---------------------------------------------------
set role anon;
do $$
begin
  perform tests.expect_count('select * from app_config', 1, 'anon reads app_config');
  perform tests.expect_error('select * from phrases', '42501', 'anon cannot read phrases');
  perform tests.expect_error('select * from daily_rounds', '42501', 'anon cannot read daily_rounds');
  perform tests.expect_error('select * from answers', '42501', 'anon cannot read answers');
  perform tests.expect_error('select * from profiles', '42501', 'anon cannot read profiles');
  perform tests.expect_error($q$insert into phrases (text, side, context) values ('x', 'charanga', 'y')$q$,
    '42501', 'anon cannot insert phrases');
end
$$;
reset role;

-- ---- authenticated user "a" ----------------------------------------------------
select tests.login((select id from tests.ids where name = 'a'));
set role authenticated;
do $$
declare
  a uuid := (select id from tests.ids where name = 'a');
  b uuid := (select id from tests.ids where name = 'b');
begin
  -- the answer key stays hidden
  perform tests.expect_error('select * from phrases', '42501', 'users cannot read phrases');
  perform tests.expect_error('select id from phrases', '42501', 'users cannot read even phrase ids');
  perform tests.expect_error('select * from daily_rounds', '42501', 'users cannot read daily_rounds');
  perform tests.expect_error($q$insert into phrases (text, side, context) values ('x', 'charanga', 'y')$q$,
    '42501', 'users cannot insert phrases directly');
  perform tests.expect_error($q$update phrases set status = 'approved'$q$,
    '42501', 'users cannot approve phrases');

  -- answers: own rows only, read-only
  perform tests.expect_count('select * from answers', 1, 'users see only their own answers');
  perform tests.expect_count(format('select * from answers where user_id = %L', b), 0,
    'users cannot see other players answers');
  perform tests.expect_error(
    format($q$insert into answers (user_id, round_date, position, choice, is_correct) values (%L, '2026-10-01', 1, 'charanga', true)$q$, a),
    '42501', 'users cannot insert answers directly');
  perform tests.expect_error($q$update answers set is_correct = true$q$, '42501', 'users cannot edit answers');
  perform tests.expect_error($q$delete from answers$q$, '42501', 'users cannot delete answers');

  -- profiles: own row, nickname only
  perform tests.expect_count('select * from profiles', 1, 'users see only their own profile');
  update profiles set nickname = 'Anita' where id = a;
  perform tests.expect_count($q$select * from profiles where nickname = 'Anita'$q$, 1, 'users can rename themselves');
  update profiles set nickname = 'Hacked' where id = b; -- RLS: silently matches no rows
  perform tests.expect_error($q$update profiles set created_at = now()$q$, '42501', 'only nickname is writable');
  perform tests.expect_error(format($q$update profiles set id = %L$q$, b), '42501', 'id is not writable');
  perform tests.expect_error($q$delete from profiles$q$, '42501', 'users cannot delete profiles');

  -- config is read-only
  perform tests.expect_error($q$update app_config set launch_date = '2020-01-01'$q$, '42501',
    'users cannot edit app_config');
end
$$;
reset role;

do $$
begin
  assert (select nickname from profiles where id = (select id from tests.ids where name = 'b')) = 'Beto',
    'a user cannot rename someone else';
end
$$;

-- ---- authenticated user "c": first login, no profile yet ----------------------
select tests.login((select id from tests.ids where name = 'c'));
set role authenticated;
do $$
declare
  b uuid := (select id from tests.ids where name = 'b');
  c uuid := (select id from tests.ids where name = 'c');
begin
  perform tests.expect_count('select * from profiles', 0, 'no profile before onboarding');
  perform tests.expect_error(format($q$insert into profiles (id, nickname) values (%L, 'Impostor')$q$, b),
    '42501', 'users cannot create a profile for someone else');
  perform tests.expect_error(format($q$insert into profiles (id, nickname) values (%L, 'beto')$q$, c),
    '23505', 'a taken nickname (case-insensitive) is rejected at onboarding');
  insert into profiles (id, nickname) values (c, 'Carla');
  perform tests.expect_count('select * from profiles', 1, 'onboarding creates the own profile');
end
$$;
reset role;

set role authenticated;
do $$
begin
  perform tests.expect_error(
    format($q$insert into profiles (id, nickname, created_at) values (gen_random_uuid(), 'Otra', now())$q$),
    '42501', 'created_at is not writable on insert');
end
$$;
reset role;
