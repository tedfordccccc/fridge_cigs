-- Row-level security checks. Run with:  bash supabase/tests/run-local.sh
\set ON_ERROR_STOP on
\set QUIET on
\o /dev/null

-- Expect a statement to fail. Usage: select pg_temp.fails($$ ... $$, 'label');
create function pg_temp.fails(stmt text, label text) returns void language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    raise notice 'ok   - % (blocked: %)', label, sqlerrm;
    return;
  end;
  raise exception 'FAIL - % was allowed', label;
end $$;
create function pg_temp.ok(cond boolean, label text) returns void language plpgsql as $$
begin
  if cond then raise notice 'ok   - %', label; else raise exception 'FAIL - %', label; end if;
end $$;
grant execute on all functions in schema pg_temp to anon, authenticated;

-- Two people sign up; profiles appear automatically.
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'connor@example.com', '{"full_name":"Connor"}'),
  ('00000000-0000-0000-0000-00000000000b', 'bea@example.com', '{}'),
  ('00000000-0000-0000-0000-00000000000c', 'admin@example.com', '{}');
insert into public.admins values ('00000000-0000-0000-0000-00000000000c');
select pg_temp.ok((select display_name from public.profiles where user_id = '00000000-0000-0000-0000-00000000000a') = 'Connor', 'profile auto-created from Google name');
select pg_temp.ok((select display_name from public.profiles where user_id = '00000000-0000-0000-0000-00000000000b') = 'bea', 'profile falls back to email name');

-- ── Signed-out visitor ──
set role anon;
select pg_temp.ok((select count(*) from public.profiles) = 3, 'anon can read profiles');
select pg_temp.fails($$insert into public.places (name, city) values ('Sheetz', 'Erie, PA')$$, 'anon adding a place');
select pg_temp.fails($$select * from public.admins$$, 'anon reading admins');
reset role;

-- ── Connor (user A) ──
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';
insert into public.places (id, name, city) values ('10000000-0000-0000-0000-000000000001', 'McDonald''s', 'Buffalo, NY');
select pg_temp.fails($$insert into public.places (name, city) values ('mcdonald''s ', 'buffalo, ny')$$, 'duplicate manual place');
insert into public.pours (id, place_id, format, ice_type, fizz, syrup, chill, ice, crispiness)
  values ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'fountain', 'nugget', 10, 9, 8, 10, 1.00);
select pg_temp.ok((select crispiness from public.pours where id = '20000000-0000-0000-0000-000000000001') = 9.20, 'crispiness computed server-side (client value ignored)');
select pg_temp.ok((select user_id from public.pours where id = '20000000-0000-0000-0000-000000000001') = '00000000-0000-0000-0000-00000000000a', 'user_id defaults to signed-in person');
select pg_temp.fails($$insert into public.pours (user_id, place_id, format, ice_type, fizz, syrup, chill, ice, crispiness)
  values ('00000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-000000000001', 'can', 'none', 5, 5, 5, 5, 0)$$, 'logging a pour as someone else');
select pg_temp.fails($$insert into public.pours (place_id, format, ice_type, fizz, syrup, chill, ice, crispiness)
  values ('10000000-0000-0000-0000-000000000001', 'can', 'none', 11, 5, 5, 5, 0)$$, 'score above 10');
select pg_temp.fails($$insert into public.pours (place_id, format, ice_type, fizz, syrup, chill, ice, crispiness, notes)
  values ('10000000-0000-0000-0000-000000000001', 'can', 'none', 5, 5, 5, 5, 0, repeat('x', 501))$$, 'notes over 500 chars');
update public.profiles set display_name = 'Connor C', home_city = 'Buffalo, NY' where user_id = '00000000-0000-0000-0000-00000000000a';
update public.pours set fizz = 1 where id = '20000000-0000-0000-0000-000000000001';
select pg_temp.ok((select crispiness from public.pours where id = '20000000-0000-0000-0000-000000000001') = 6.50, 'owner can edit pour; score recomputed');
select pg_temp.fails($$update public.pours set user_id = '00000000-0000-0000-0000-00000000000b' where id = '20000000-0000-0000-0000-000000000001'$$, 'giving a pour away');
update public.places set name = 'Hacked' where id = '10000000-0000-0000-0000-000000000001';  -- silently matches no rows

-- ── Bea (user B) ──
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
update public.pours set fizz = 10 where id = '20000000-0000-0000-0000-000000000001';
delete from public.pours where id = '20000000-0000-0000-0000-000000000001';
update public.profiles set display_name = 'Hacked' where user_id = '00000000-0000-0000-0000-00000000000a';
reset role;
select pg_temp.ok((select fizz from public.pours where id = '20000000-0000-0000-0000-000000000001') = 1, 'someone else cannot edit my pour');
select pg_temp.ok(exists (select 1 from public.pours where id = '20000000-0000-0000-0000-000000000001'), 'someone else cannot delete my pour');
select pg_temp.ok((select display_name from public.profiles where user_id = '00000000-0000-0000-0000-00000000000a') = 'Connor C', 'someone else cannot edit my profile');
select pg_temp.ok((select name from public.places where id = '10000000-0000-0000-0000-000000000001') = 'McDonald''s', 'non-admin place edit had no effect');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
select pg_temp.fails($$insert into public.admins values ('00000000-0000-0000-0000-00000000000b')$$, 'making yourself an admin');
insert into public.pours (place_id, format, ice_type, fizz, syrup, chill, ice, crispiness)
  values ('10000000-0000-0000-0000-000000000001', 'can', 'none', 6, 6, 6, 6, 0);

-- ── Leaderboard view ──
select pg_temp.ok((select pour_count from public.place_scores where place_id = '10000000-0000-0000-0000-000000000001') = 2, 'leaderboard counts pours');
select pg_temp.ok((select avg_crispiness from public.place_scores where place_id = '10000000-0000-0000-0000-000000000001') = 6.25, 'leaderboard averages crispiness');
select pg_temp.ok((select formats::text from public.place_scores where place_id = '10000000-0000-0000-0000-000000000001') = '{fountain,can}', 'leaderboard lists formats');

-- ── Admin ──
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000c';
delete from public.pours where id = '20000000-0000-0000-0000-000000000001';
update public.places set name = 'McDonald''s (Elmwood)' where id = '10000000-0000-0000-0000-000000000001';
reset role;
select pg_temp.ok(not exists (select 1 from public.pours where id = '20000000-0000-0000-0000-000000000001'), 'admin can delete any pour');
select pg_temp.ok((select name from public.places where id = '10000000-0000-0000-0000-000000000001') = 'McDonald''s (Elmwood)', 'admin can edit places');

\o
\echo 'All RLS checks passed.'
