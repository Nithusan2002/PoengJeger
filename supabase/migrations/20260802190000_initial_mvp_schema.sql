create extension if not exists pgcrypto;
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'poengjeger_role') in ('admin', 'editor'),
    false
  );
$$;
create table if not exists public.bonus_programs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  issuer_name text not null,
  country_code text not null default 'NO',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bonus_programs_slug_format check (slug ~ '^[a-z0-9-]+$'),
  constraint bonus_programs_country_code_length check (char_length(country_code) = 2)
);
create table if not exists public.campaign_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_categories_slug_format check (slug ~ '^[a-z0-9-]+$')
);
create table if not exists public.campaign_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  source_type text not null,
  base_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_sources_source_type check (
    source_type in ('official', 'newsletter', 'bank', 'retailer', 'forum', 'blog', 'social', 'other')
  )
);
create table if not exists public.user_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  preferred_locale text not null default 'nb-NO',
  notifications_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null,
  details text not null,
  status text not null default 'draft',
  start_date timestamptz,
  end_date timestamptz,
  last_verified_at timestamptz,
  primary_program_id uuid references public.bonus_programs (id) on delete set null,
  category_id uuid references public.campaign_categories (id) on delete set null,
  editorial_score numeric(5,2),
  editorial_summary text,
  is_featured boolean not null default false,
  created_by uuid references auth.users (id) on delete set null,
  updated_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaigns_status check (status in ('draft', 'review', 'published', 'expired', 'archived')),
  constraint campaigns_date_order check (end_date is null or start_date is null or end_date >= start_date),
  constraint campaigns_editorial_score_range check (
    editorial_score is null or (editorial_score >= 0 and editorial_score <= 100)
  )
);
create table if not exists public.campaign_programs (
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  program_id uuid not null references public.bonus_programs (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (campaign_id, program_id)
);
create table if not exists public.campaign_requirements (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  text text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.campaign_source_references (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  source_id uuid not null references public.campaign_sources (id) on delete restrict,
  url text not null,
  title text,
  checked_at timestamptz not null,
  evidence_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.campaign_editorial_assessments (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null unique references public.campaigns (id) on delete cascade,
  score numeric(5,2),
  reason_why_it_matters text not null,
  estimated_value_text text,
  difficulty_level text,
  availability_scope text,
  risk_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaign_editorial_assessments_score_range check (
    score is null or (score >= 0 and score <= 100)
  ),
  constraint campaign_editorial_assessments_difficulty_level check (
    difficulty_level is null or difficulty_level in ('low', 'medium', 'high')
  ),
  constraint campaign_editorial_assessments_availability_scope check (
    availability_scope is null or availability_scope in ('narrow', 'regional', 'broad')
  )
);
create table if not exists public.campaign_geo_restrictions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  country_code text not null,
  created_at timestamptz not null default now(),
  constraint campaign_geo_restrictions_country_code_length check (char_length(country_code) = 2),
  unique (campaign_id, country_code)
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
create index if not exists campaigns_status_end_date_idx
  on public.campaigns (status, end_date);
create index if not exists campaigns_primary_program_idx
  on public.campaigns (primary_program_id);
create index if not exists campaigns_category_idx
  on public.campaigns (category_id);
create index if not exists campaign_programs_program_campaign_idx
  on public.campaign_programs (program_id, campaign_id);
create index if not exists campaign_requirements_campaign_sort_idx
  on public.campaign_requirements (campaign_id, sort_order);
create index if not exists campaign_source_references_campaign_idx
  on public.campaign_source_references (campaign_id);
create index if not exists campaign_geo_restrictions_campaign_idx
  on public.campaign_geo_restrictions (campaign_id);
create index if not exists notification_subscriptions_user_idx
  on public.notification_subscriptions (user_id);
create index if not exists campaign_audit_log_campaign_created_idx
  on public.campaign_audit_log (campaign_id, created_at desc);
create or replace function public.enforce_campaign_publish_requirements()
returns trigger
language plpgsql
as $$
declare
  source_reference_count integer;
begin
  if new.status = 'published' then
    if new.last_verified_at is null then
      raise exception 'Published campaigns must have last_verified_at set';
    end if;

    select count(*)
      into source_reference_count
    from public.campaign_source_references
    where campaign_id = new.id;

    if source_reference_count = 0 then
      raise exception 'Published campaigns must have at least one source reference';
    end if;
  end if;

  return new;
end;
$$;
create or replace function public.log_campaign_status_change()
returns trigger
language plpgsql
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
drop trigger if exists set_bonus_programs_updated_at on public.bonus_programs;
create trigger set_bonus_programs_updated_at
before update on public.bonus_programs
for each row execute function public.set_updated_at();
drop trigger if exists set_campaign_categories_updated_at on public.campaign_categories;
create trigger set_campaign_categories_updated_at
before update on public.campaign_categories
for each row execute function public.set_updated_at();
drop trigger if exists set_campaign_sources_updated_at on public.campaign_sources;
create trigger set_campaign_sources_updated_at
before update on public.campaign_sources
for each row execute function public.set_updated_at();
drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();
drop trigger if exists set_campaigns_updated_at on public.campaigns;
create trigger set_campaigns_updated_at
before update on public.campaigns
for each row execute function public.set_updated_at();
drop trigger if exists enforce_campaign_publish_requirements on public.campaigns;
create trigger enforce_campaign_publish_requirements
before insert or update on public.campaigns
for each row execute function public.enforce_campaign_publish_requirements();
drop trigger if exists log_campaign_status_change on public.campaigns;
create trigger log_campaign_status_change
after insert or update on public.campaigns
for each row execute function public.log_campaign_status_change();
drop trigger if exists set_campaign_requirements_updated_at on public.campaign_requirements;
create trigger set_campaign_requirements_updated_at
before update on public.campaign_requirements
for each row execute function public.set_updated_at();
drop trigger if exists set_campaign_source_references_updated_at on public.campaign_source_references;
create trigger set_campaign_source_references_updated_at
before update on public.campaign_source_references
for each row execute function public.set_updated_at();
drop trigger if exists set_campaign_editorial_assessments_updated_at on public.campaign_editorial_assessments;
create trigger set_campaign_editorial_assessments_updated_at
before update on public.campaign_editorial_assessments
for each row execute function public.set_updated_at();
drop trigger if exists set_notification_subscriptions_updated_at on public.notification_subscriptions;
create trigger set_notification_subscriptions_updated_at
before update on public.notification_subscriptions
for each row execute function public.set_updated_at();
alter table public.bonus_programs enable row level security;
alter table public.campaign_categories enable row level security;
alter table public.campaign_sources enable row level security;
alter table public.user_profiles enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_programs enable row level security;
alter table public.campaign_requirements enable row level security;
alter table public.campaign_source_references enable row level security;
alter table public.campaign_editorial_assessments enable row level security;
alter table public.campaign_geo_restrictions enable row level security;
alter table public.user_program_preferences enable row level security;
alter table public.user_favorite_campaigns enable row level security;
alter table public.notification_subscriptions enable row level security;
alter table public.campaign_audit_log enable row level security;
drop policy if exists "published bonus programs are readable" on public.bonus_programs;
create policy "published bonus programs are readable"
on public.bonus_programs
for select
using (is_active or public.is_admin());
drop policy if exists "admins manage bonus programs" on public.bonus_programs;
create policy "admins manage bonus programs"
on public.bonus_programs
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign categories are readable" on public.campaign_categories;
create policy "campaign categories are readable"
on public.campaign_categories
for select
using (true);
drop policy if exists "admins manage campaign categories" on public.campaign_categories;
create policy "admins manage campaign categories"
on public.campaign_categories
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign sources readable for published content" on public.campaign_sources;
create policy "campaign sources readable for published content"
on public.campaign_sources
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaign_source_references csr
    join public.campaigns c on c.id = csr.campaign_id
    where csr.source_id = campaign_sources.id
      and c.status = 'published'
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign sources" on public.campaign_sources;
create policy "admins manage campaign sources"
on public.campaign_sources
for all
using (public.is_admin())
with check (public.is_admin());
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
using (public.is_admin());
drop policy if exists "published campaigns are readable" on public.campaigns;
create policy "published campaigns are readable"
on public.campaigns
for select
using (
  public.is_admin()
  or (
    status = 'published'
    and (start_date is null or start_date <= now())
    and (end_date is null or end_date >= now())
  )
);
drop policy if exists "admins manage campaigns" on public.campaigns;
create policy "admins manage campaigns"
on public.campaigns
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign program links for readable campaigns" on public.campaign_programs;
create policy "campaign program links for readable campaigns"
on public.campaign_programs
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaigns c
    where c.id = campaign_programs.campaign_id
      and c.status = 'published'
      and (c.start_date is null or c.start_date <= now())
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign program links" on public.campaign_programs;
create policy "admins manage campaign program links"
on public.campaign_programs
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign requirements for readable campaigns" on public.campaign_requirements;
create policy "campaign requirements for readable campaigns"
on public.campaign_requirements
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaigns c
    where c.id = campaign_requirements.campaign_id
      and c.status = 'published'
      and (c.start_date is null or c.start_date <= now())
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign requirements" on public.campaign_requirements;
create policy "admins manage campaign requirements"
on public.campaign_requirements
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign source references for readable campaigns" on public.campaign_source_references;
create policy "campaign source references for readable campaigns"
on public.campaign_source_references
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaigns c
    where c.id = campaign_source_references.campaign_id
      and c.status = 'published'
      and (c.start_date is null or c.start_date <= now())
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign source references" on public.campaign_source_references;
create policy "admins manage campaign source references"
on public.campaign_source_references
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign editorial assessments for readable campaigns" on public.campaign_editorial_assessments;
create policy "campaign editorial assessments for readable campaigns"
on public.campaign_editorial_assessments
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaigns c
    where c.id = campaign_editorial_assessments.campaign_id
      and c.status = 'published'
      and (c.start_date is null or c.start_date <= now())
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign editorial assessments" on public.campaign_editorial_assessments;
create policy "admins manage campaign editorial assessments"
on public.campaign_editorial_assessments
for all
using (public.is_admin())
with check (public.is_admin());
drop policy if exists "campaign geo restrictions for readable campaigns" on public.campaign_geo_restrictions;
create policy "campaign geo restrictions for readable campaigns"
on public.campaign_geo_restrictions
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.campaigns c
    where c.id = campaign_geo_restrictions.campaign_id
      and c.status = 'published'
      and (c.start_date is null or c.start_date <= now())
      and (c.end_date is null or c.end_date >= now())
  )
);
drop policy if exists "admins manage campaign geo restrictions" on public.campaign_geo_restrictions;
create policy "admins manage campaign geo restrictions"
on public.campaign_geo_restrictions
for all
using (public.is_admin())
with check (public.is_admin());
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
using (public.is_admin());
drop policy if exists "admins insert campaign audit log" on public.campaign_audit_log;
create policy "admins insert campaign audit log"
on public.campaign_audit_log
for insert
with check (public.is_admin());
