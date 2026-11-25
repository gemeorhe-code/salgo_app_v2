-- Fase C: preferencias del usuario y estados de notificación.

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

alter table public.salgo_user_preferences enable row level security;
alter table public.salgo_notification_states enable row level security;

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
