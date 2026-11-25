-- Solo para proyecto universitario: no incluyas datos personales ni secretos en este archivo.

create extension if not exists pgcrypto;

create table if not exists public.salgo_places (
  id integer primary key,
  name text not null,
  category text not null,
  city text not null,
  address text not null,
  schedule text not null,
  price text not null,
  description text not null,
  rating double precision not null default 0 check (rating >= 0),
  review_count integer not null default 0 check (review_count >= 0),
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.salgo_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  full_name text not null default 'Usuario',
  avatar_url text,
  city text not null default 'Bucaramanga',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.salgo_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  place_id integer not null references public.salgo_places (id) on delete cascade,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint salgo_favorites_user_place_key unique (user_id, place_id)
);

create table if not exists public.salgo_user_preferences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plan text,
  budget double precision not null default 0,
  companion text,
  place text,
  minutes double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.salgo_notification_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  notification_type text not null,
  enabled boolean not null default true,
  last_read_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint salgo_notification_states_user_type_key
    unique (user_id, notification_type)
);

create or replace function public.salgo_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists salgo_places_touch_updated_at on public.salgo_places;
create trigger salgo_places_touch_updated_at
  before update on public.salgo_places
  for each row execute function public.salgo_touch_updated_at();

drop trigger if exists salgo_profiles_touch_updated_at on public.salgo_profiles;
create trigger salgo_profiles_touch_updated_at
  before update on public.salgo_profiles
  for each row execute function public.salgo_touch_updated_at();

drop trigger if exists salgo_favorites_touch_updated_at on public.salgo_favorites;
create trigger salgo_favorites_touch_updated_at
  before update on public.salgo_favorites
  for each row execute function public.salgo_touch_updated_at();

drop trigger if exists salgo_user_preferences_touch_updated_at
  on public.salgo_user_preferences;
create trigger salgo_user_preferences_touch_updated_at
  before update on public.salgo_user_preferences
  for each row execute function public.salgo_touch_updated_at();

drop trigger if exists salgo_notification_states_touch_updated_at
  on public.salgo_notification_states;
create trigger salgo_notification_states_touch_updated_at
  before update on public.salgo_notification_states
  for each row execute function public.salgo_touch_updated_at();

alter table public.salgo_places enable row level security;
alter table public.salgo_profiles enable row level security;
alter table public.salgo_favorites enable row level security;
alter table public.salgo_user_preferences enable row level security;
alter table public.salgo_notification_states enable row level security;

drop policy if exists salgo_places_public_select on public.salgo_places;
create policy salgo_places_public_select
  on public.salgo_places
  for select to anon, authenticated
  using (is_active);

drop policy if exists salgo_profiles_select_own on public.salgo_profiles;
create policy salgo_profiles_select_own
  on public.salgo_profiles
  for select to authenticated
  using (auth.uid() = id);

drop policy if exists salgo_profiles_insert_own on public.salgo_profiles;
create policy salgo_profiles_insert_own
  on public.salgo_profiles
  for insert to authenticated
  with check (auth.uid() = id);

drop policy if exists salgo_profiles_update_own on public.salgo_profiles;
create policy salgo_profiles_update_own
  on public.salgo_profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists salgo_profiles_delete_own on public.salgo_profiles;
create policy salgo_profiles_delete_own
  on public.salgo_profiles
  for delete to authenticated
  using (auth.uid() = id);

drop policy if exists salgo_favorites_select_own on public.salgo_favorites;
create policy salgo_favorites_select_own
  on public.salgo_favorites
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists salgo_favorites_insert_own on public.salgo_favorites;
create policy salgo_favorites_insert_own
  on public.salgo_favorites
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists salgo_favorites_update_own on public.salgo_favorites;
create policy salgo_favorites_update_own
  on public.salgo_favorites
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists salgo_favorites_delete_own on public.salgo_favorites;
create policy salgo_favorites_delete_own
  on public.salgo_favorites
  for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists salgo_user_preferences_select_own
  on public.salgo_user_preferences;
create policy salgo_user_preferences_select_own
  on public.salgo_user_preferences
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists salgo_user_preferences_insert_own
  on public.salgo_user_preferences;
create policy salgo_user_preferences_insert_own
  on public.salgo_user_preferences
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists salgo_user_preferences_update_own
  on public.salgo_user_preferences;
create policy salgo_user_preferences_update_own
  on public.salgo_user_preferences
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists salgo_user_preferences_delete_own
  on public.salgo_user_preferences;
create policy salgo_user_preferences_delete_own
  on public.salgo_user_preferences
  for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists salgo_notification_states_select_own
  on public.salgo_notification_states;
create policy salgo_notification_states_select_own
  on public.salgo_notification_states
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists salgo_notification_states_insert_own
  on public.salgo_notification_states;
create policy salgo_notification_states_insert_own
  on public.salgo_notification_states
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists salgo_notification_states_update_own
  on public.salgo_notification_states;
create policy salgo_notification_states_update_own
  on public.salgo_notification_states
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists salgo_notification_states_delete_own
  on public.salgo_notification_states;
create policy salgo_notification_states_delete_own
  on public.salgo_notification_states
  for delete to authenticated
  using (auth.uid() = user_id);
