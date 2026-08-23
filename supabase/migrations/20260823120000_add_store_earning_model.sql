begin;

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  category_id uuid references public.campaign_categories (id) on delete set null,
  status text not null default 'draft',
  website_url text,
  search_keywords text[] not null default '{}',
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint stores_slug_format check (slug ~ '^[a-z0-9-]+$'),
  constraint stores_status check (status in ('draft', 'review', 'published', 'archived')),
  constraint stores_website_https check (website_url is null or website_url ~ '^https://')
);

create table if not exists public.earning_methods (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  method_type text not null,
  program_id uuid references public.bonus_programs (id) on delete set null,
  status text not null default 'published',
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint earning_methods_slug_format check (slug ~ '^[a-z0-9-]+$'),
  constraint earning_methods_type check (method_type in ('portal', 'card', 'loyalty', 'campaign', 'manual')),
  constraint earning_methods_status check (status in ('draft', 'published', 'archived'))
);

create table if not exists public.store_earning_rates (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  earning_method_id uuid not null references public.earning_methods (id) on delete restrict,
  status text not null default 'draft',
  rate_label text not null,
  normal_rate_label text,
  value_summary text,
  requirement_summary text,
  warning_text text,
  handoff_url text,
  source_url text,
  source_title text,
  checked_at timestamptz,
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer not null default 0,
  is_base_rate boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_earning_rates_status check (status in ('draft', 'published', 'expired', 'archived')),
  constraint store_earning_rates_handoff_https check (handoff_url is null or handoff_url ~ '^https://'),
  constraint store_earning_rates_source_https check (source_url is null or source_url ~ '^https://'),
  constraint store_earning_rates_date_order check (ends_at is null or starts_at is null or ends_at >= starts_at)
);

create table if not exists public.earning_combinations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores (id) on delete cascade,
  status text not null default 'draft',
  title text not null,
  total_value_label text not null,
  summary text not null,
  easier_alternative_label text,
  warning_text text,
  primary_handoff_url text,
  last_verified_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint earning_combinations_status check (status in ('draft', 'published', 'archived')),
  constraint earning_combinations_handoff_https check (primary_handoff_url is null or primary_handoff_url ~ '^https://')
);

create table if not exists public.earning_combination_rates (
  combination_id uuid not null references public.earning_combinations (id) on delete cascade,
  store_earning_rate_id uuid not null references public.store_earning_rates (id) on delete cascade,
  sort_order integer not null default 0,
  primary key (combination_id, store_earning_rate_id)
);

create table if not exists public.earning_combination_steps (
  id uuid primary key default gen_random_uuid(),
  combination_id uuid not null references public.earning_combinations (id) on delete cascade,
  text text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stores_status_name_idx on public.stores (status, name);
create index if not exists stores_category_idx on public.stores (category_id);
create index if not exists earning_methods_status_name_idx on public.earning_methods (status, name);
create index if not exists store_earning_rates_store_status_idx on public.store_earning_rates (store_id, status, sort_order);
create index if not exists store_earning_rates_method_idx on public.store_earning_rates (earning_method_id);
create index if not exists earning_combinations_store_status_idx on public.earning_combinations (store_id, status, sort_order);
create index if not exists earning_combination_steps_combination_sort_idx on public.earning_combination_steps (combination_id, sort_order);

drop trigger if exists set_stores_updated_at on public.stores;
create trigger set_stores_updated_at
before update on public.stores
for each row execute function public.set_updated_at();

drop trigger if exists set_earning_methods_updated_at on public.earning_methods;
create trigger set_earning_methods_updated_at
before update on public.earning_methods
for each row execute function public.set_updated_at();

drop trigger if exists set_store_earning_rates_updated_at on public.store_earning_rates;
create trigger set_store_earning_rates_updated_at
before update on public.store_earning_rates
for each row execute function public.set_updated_at();

drop trigger if exists set_earning_combinations_updated_at on public.earning_combinations;
create trigger set_earning_combinations_updated_at
before update on public.earning_combinations
for each row execute function public.set_updated_at();

drop trigger if exists set_earning_combination_steps_updated_at on public.earning_combination_steps;
create trigger set_earning_combination_steps_updated_at
before update on public.earning_combination_steps
for each row execute function public.set_updated_at();

alter table public.stores enable row level security;
alter table public.earning_methods enable row level security;
alter table public.store_earning_rates enable row level security;
alter table public.earning_combinations enable row level security;
alter table public.earning_combination_rates enable row level security;
alter table public.earning_combination_steps enable row level security;

create policy "published stores are readable"
on public.stores
for select
using (status = 'published');

create policy "editorial members manage stores"
on public.stores
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

create policy "published earning methods are readable"
on public.earning_methods
for select
using (status = 'published');

create policy "editorial members manage earning methods"
on public.earning_methods
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

create policy "published store earning rates are readable"
on public.store_earning_rates
for select
using (
  status = 'published'
  and exists (
    select 1 from public.stores
    where stores.id = store_earning_rates.store_id
      and stores.status = 'published'
  )
  and exists (
    select 1 from public.earning_methods
    where earning_methods.id = store_earning_rates.earning_method_id
      and earning_methods.status = 'published'
  )
);

create policy "editorial members manage store earning rates"
on public.store_earning_rates
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

create policy "published earning combinations are readable"
on public.earning_combinations
for select
using (
  status = 'published'
  and exists (
    select 1 from public.stores
    where stores.id = earning_combinations.store_id
      and stores.status = 'published'
  )
);

create policy "editorial members manage earning combinations"
on public.earning_combinations
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

create policy "published earning combination rates are readable"
on public.earning_combination_rates
for select
using (
  exists (
    select 1 from public.earning_combinations
    where earning_combinations.id = earning_combination_rates.combination_id
      and earning_combinations.status = 'published'
  )
);

create policy "editorial members manage earning combination rates"
on public.earning_combination_rates
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

create policy "published earning combination steps are readable"
on public.earning_combination_steps
for select
using (
  exists (
    select 1 from public.earning_combinations
    where earning_combinations.id = earning_combination_steps.combination_id
      and earning_combinations.status = 'published'
  )
);

create policy "editorial members manage earning combination steps"
on public.earning_combination_steps
for all
using (public.is_editorial_member())
with check (public.is_editorial_member());

commit;
