-- Restore MVP tables that exist in the repository's documented schema but are
-- missing from the linked database. The statements are intentionally
-- idempotent so the migration is also safe on databases where the initial MVP
-- migration already created the objects.

create table if not exists public.user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  preferred_locale text not null default 'nb-NO',
  notifications_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_program_preferences (
  user_id uuid not null references auth.users (id) on delete cascade,
  program_id uuid not null references public.bonus_programs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, program_id)
);

create table if not exists public.user_favorite_campaigns (
  user_id uuid not null references auth.users (id) on delete cascade,
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, campaign_id)
);

create table if not exists public.notification_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  program_id uuid references public.bonus_programs (id) on delete cascade,
  campaign_category_id uuid references public.campaign_categories (id) on delete cascade,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_subscriptions_target_present check (
    program_id is not null or campaign_category_id is not null
  )
);

create table if not exists public.campaign_audit_log (
  id bigint generated always as identity primary key,
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  changed_by uuid references auth.users (id) on delete set null,
  from_status text,
  to_status text,
  change_note text,
  created_at timestamptz not null default now()
);

create index if not exists notification_subscriptions_user_idx
  on public.notification_subscriptions (user_id);

create index if not exists campaign_audit_log_campaign_created_idx
  on public.campaign_audit_log (campaign_id, created_at desc);

create or replace function public.log_campaign_status_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.campaign_audit_log (campaign_id, changed_by, to_status, change_note)
    values (new.id, auth.uid(), new.status, 'Campaign created');
  elsif old.status is distinct from new.status then
    insert into public.campaign_audit_log (campaign_id, changed_by, from_status, to_status, change_note)
    values (new.id, auth.uid(), old.status, new.status, 'Campaign status updated');
  end if;

  return new;
end;
$$;

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_notification_subscriptions_updated_at on public.notification_subscriptions;
create trigger set_notification_subscriptions_updated_at
before update on public.notification_subscriptions
for each row execute function public.set_updated_at();

drop trigger if exists log_campaign_status_change on public.campaigns;
create trigger log_campaign_status_change
after insert or update on public.campaigns
for each row execute function public.log_campaign_status_change();

alter table public.user_profiles enable row level security;
alter table public.user_program_preferences enable row level security;
alter table public.user_favorite_campaigns enable row level security;
alter table public.notification_subscriptions enable row level security;
alter table public.campaign_audit_log enable row level security;

drop policy if exists "users read own profile" on public.user_profiles;
create policy "users read own profile"
on public.user_profiles
for select
using (auth.uid() = id);

drop policy if exists "users insert own profile" on public.user_profiles;
create policy "users insert own profile"
on public.user_profiles
for insert
with check (auth.uid() = id);

drop policy if exists "users update own profile" on public.user_profiles;
create policy "users update own profile"
on public.user_profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "admins read all profiles" on public.user_profiles;
create policy "admins read all profiles"
on public.user_profiles
for select
using (public.is_editorial_member());

drop policy if exists "users read own program preferences" on public.user_program_preferences;
create policy "users read own program preferences"
on public.user_program_preferences
for select
using (auth.uid() = user_id);

drop policy if exists "users manage own program preferences" on public.user_program_preferences;
create policy "users manage own program preferences"
on public.user_program_preferences
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users read own favorites" on public.user_favorite_campaigns;
create policy "users read own favorites"
on public.user_favorite_campaigns
for select
using (auth.uid() = user_id);

drop policy if exists "users manage own favorites" on public.user_favorite_campaigns;
create policy "users manage own favorites"
on public.user_favorite_campaigns
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users read own notification subscriptions" on public.notification_subscriptions;
create policy "users read own notification subscriptions"
on public.notification_subscriptions
for select
using (auth.uid() = user_id);

drop policy if exists "users manage own notification subscriptions" on public.notification_subscriptions;
create policy "users manage own notification subscriptions"
on public.notification_subscriptions
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "admins read campaign audit log" on public.campaign_audit_log;
create policy "admins read campaign audit log"
on public.campaign_audit_log
for select
using (public.is_editorial_member());

drop policy if exists "admins insert campaign audit log" on public.campaign_audit_log;
create policy "admins insert campaign audit log"
on public.campaign_audit_log
for insert
with check (public.is_editorial_member());
