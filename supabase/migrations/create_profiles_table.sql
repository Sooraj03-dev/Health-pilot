-- ============================================================
-- Profiles Table for Health Pilot
-- ============================================================
-- Stores user profile metadata (role, verification status).
-- Linked 1-to-1 with auth.users via user_id.
-- RLS ensures each user can only read/update their own row.
-- ============================================================

-- 1. Create the profiles table
create table if not exists public.profiles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null unique references auth.users (id) on delete cascade,
  role       text not null check (role in ('patient', 'doctor', 'caregiver')),
  is_verified boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Index for fast lookups by user_id
create index if not exists idx_profiles_user_id on public.profiles (user_id);

-- 2. Enable Row Level Security
alter table public.profiles enable row level security;

-- 3. RLS Policies

-- Allow authenticated users to read only their own profile
create policy "Users can view their own profile"
  on public.profiles
  for select
  using (auth.uid() = user_id);

-- Allow authenticated users to insert their own profile (signup flow)
create policy "Users can insert their own profile"
  on public.profiles
  for insert
  with check (auth.uid() = user_id);

-- Allow authenticated users to update only their own profile
create policy "Users can update their own profile"
  on public.profiles
  for update
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Auto-update the updated_at timestamp on every change
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.handle_updated_at();

-- 5. (Optional) Auto-create a profile row when a new user signs up
--    Uncomment if you want profiles created automatically via a trigger.
--
-- create or replace function public.handle_new_user()
-- returns trigger as $$
-- begin
--   insert into public.profiles (user_id, role)
--   values (new.id, 'patient');  -- default role
--   return new;
-- end;
-- $$ language plpgsql security definer;
--
-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row
--   execute function public.handle_new_user();
