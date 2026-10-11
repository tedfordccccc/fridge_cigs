-- Fridge Cig Report: initial schema
-- Tables: profiles, places, pours (+ admins). Row-level security on every table.
--
-- Who can do what:
--   Everyone (even signed out) can READ places, pours and profiles, so the
--   leaderboard is public.
--   Signed-in people can add pours (as themselves) and add places.
--   Only a pour's owner, or an admin, can edit or delete it.
--   Only you can edit your own profile.
--   Admins are listed in public.admins, which nobody can read or write from the app;
--   add one from the Supabase SQL editor:  insert into public.admins values ('<user uuid>');

-- ───────────────────────── Enums ─────────────────────────

create type public.pour_format as enum ('fountain', 'can', 'plastic_bottle', 'glass_bottle');
create type public.ice_type as enum ('nugget', 'crushed', 'cubed', 'crescent', 'shaved', 'none');

-- ───────────────────────── Scoring ─────────────────────────
-- Same weights as the prototype: fizz 30%, syrup ratio 30%, chill 25%, ice 15%.
-- If these ever change, update src/lib/scoring.ts too, then recompute stored scores:
--   update public.pours set crispiness = public.crispiness(fizz, syrup, chill, ice);

create function public.crispiness(fizz int, syrup int, chill int, ice int)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select round(fizz * 0.30 + syrup * 0.30 + chill * 0.25 + ice * 0.15, 2)
$$;

-- ───────────────────────── Admins ─────────────────────────

create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table public.admins enable row level security;
-- No policies on purpose: the app can't read or change this table.

-- security definer lets policies check the admins table without exposing it.
create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()))
$$;

-- ───────────────────────── Profiles ─────────────────────────

create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) between 1 and 40),
  home_city text check (char_length(home_city) <= 80),
  favorite_format public.pour_format,
  avatar_url text check (char_length(avatar_url) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create policy "Profiles are public"
  on public.profiles for select
  to anon, authenticated
  using (true);

create policy "People create their own profile"
  on public.profiles for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "People edit their own profile"
  on public.profiles for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Make a profile row automatically when someone signs up. The display name starts as
-- whatever Google/Apple gave us, else the part of the email before the @.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name, avatar_url)
  values (
    new.id,
    left(coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(new.email, '@', 1), ''),
      'Someone'
    ), 40),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────── Places ─────────────────────────

create table public.places (
  id uuid primary key default gen_random_uuid(),
  google_place_id text unique,          -- null for manual-entry places
  name text not null check (char_length(btrim(name)) between 1 and 120),
  address text check (char_length(address) <= 300),
  city text check (char_length(city) <= 80),
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.places enable row level security;

-- Manual entries can't duplicate each other (same name + city, ignoring case and spaces).
create unique index places_manual_unique
  on public.places (lower(btrim(name)), lower(btrim(coalesce(city, ''))))
  where google_place_id is null;

create policy "Places are public"
  on public.places for select
  to anon, authenticated
  using (true);

create policy "Signed-in people add places"
  on public.places for insert
  to authenticated
  with check (created_by = (select auth.uid()));

create policy "Admins edit places"
  on public.places for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "Admins delete places"
  on public.places for delete
  to authenticated
  using ((select public.is_admin()));

-- ───────────────────────── Pours ─────────────────────────

create table public.pours (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  place_id uuid not null references public.places (id) on delete cascade,
  format public.pour_format not null,
  ice_type public.ice_type not null,
  fizz smallint not null check (fizz between 1 and 10),
  syrup smallint not null check (syrup between 1 and 10),
  chill smallint not null check (chill between 1 and 10),
  ice smallint not null check (ice between 1 and 10),
  crispiness numeric(4, 2) not null,     -- filled in by trigger below; never trusted from the client
  notes text check (char_length(notes) <= 500),
  poured_on date not null default current_date,
  created_at timestamptz not null default now()
);
alter table public.pours enable row level security;

create index pours_place_id_idx on public.pours (place_id);
create index pours_user_id_idx on public.pours (user_id);
create index pours_created_at_idx on public.pours (created_at desc);

-- Always compute crispiness on the server so nobody can post a fake 10.0.
create function public.pours_set_crispiness()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.crispiness := public.crispiness(new.fizz, new.syrup, new.chill, new.ice);
  return new;
end;
$$;

create trigger pours_set_crispiness
  before insert or update on public.pours
  for each row execute function public.pours_set_crispiness();

create policy "Pours are public"
  on public.pours for select
  to anon, authenticated
  using (true);

create policy "People log pours as themselves"
  on public.pours for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "Owners or admins edit pours"
  on public.pours for update
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));

create policy "Owners or admins delete pours"
  on public.pours for delete
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

-- Owners can't hand a pour to someone else; admins can't either (it would misattribute it).
create function public.pours_lock_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.user_id is distinct from old.user_id then
    raise exception 'A pour''s owner cannot be changed';
  end if;
  return new;
end;
$$;

create trigger pours_lock_owner
  before update on public.pours
  for each row execute function public.pours_lock_owner();

-- ───────────────────────── Leaderboard ─────────────────────────
-- One row per place: average crispiness, pour count, formats seen.
-- Ranked by average, ties broken by number of pours (same as the prototype).
-- security_invoker = true means the view obeys the RLS policies above.

create view public.place_scores
with (security_invoker = true)
as
select
  p.id as place_id,
  p.name,
  p.city,
  p.address,
  p.lat,
  p.lng,
  p.google_place_id,
  round(avg(r.crispiness), 2) as avg_crispiness,
  count(r.id)::int as pour_count,
  array_agg(distinct r.format order by r.format) as formats,
  array_agg(distinct r.ice_type order by r.ice_type) as ice_types,
  max(r.created_at) as last_poured_at
from public.places p
join public.pours r on r.place_id = p.id
group by p.id;

-- ───────────────────────── Grants ─────────────────────────
-- Supabase grants table access to anon/authenticated by default; RLS above does the
-- real gatekeeping. Make the defaults explicit, and keep signed-out visitors read-only.

grant usage on schema public to anon, authenticated;
grant select on public.profiles, public.places, public.pours, public.place_scores to anon, authenticated;
grant insert, update on public.profiles to authenticated;
grant insert, update, delete on public.places, public.pours to authenticated;
revoke insert, update, delete on public.profiles, public.places, public.pours from anon;
revoke all on public.admins from anon, authenticated;
