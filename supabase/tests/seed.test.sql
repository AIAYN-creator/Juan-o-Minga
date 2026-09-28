-- The dev seed loads cleanly and is fit to play with (the runner loads
-- supabase/seed.sql before every test file).

do $$
begin
  perform tests.expect_count($q$select * from phrases where status = 'approved'$q$, 12,
    'seed ships 12 approved phrases');
  perform tests.expect_count($q$select * from phrases where side = 'charanga'$q$, 6, '6 charanga phrases');
  perform tests.expect_count($q$select * from phrases where side = 'penista'$q$, 6, '6 penista phrases');
  perform tests.expect_count($q$select * from phrases where side = 'penista' and author is not null$q$, 0,
    'no penista has an author');
  perform tests.expect_count(
    $q$select * from phrases where id::text not like '00000000-0000-4000-8000-0000000000%'$q$, 0,
    'every seed phrase uses the recognisable fixed id');
  perform tests.expect_count($q$select * from phrases where last_used_on is not null$q$, 0,
    'seed phrases start unused');
end
$$;
