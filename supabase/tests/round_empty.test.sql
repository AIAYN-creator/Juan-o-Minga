-- With fewer than 3 approved phrases there is no round, and nothing half-built
-- is left behind.

do $$
declare
  uid uuid := tests.create_user('Ana');
begin
  update phrases set status = 'pending' where right(id::text, 2)::int >= 3; -- only 2 approved left
  perform tests.login(uid);
end
$$;
set role authenticated;
do $$
begin
  perform tests.expect_error_message('select * from get_today_round()', 'not_enough_phrases',
    'no round with fewer than 3 approved phrases');
end
$$;
reset role;

do $$
begin
  perform tests.expect_count('select * from daily_rounds', 0, 'no partial round is stored');
  perform tests.expect_count('select * from phrases where last_used_on is not null', 0, 'no phrase marked as used');
end
$$;
