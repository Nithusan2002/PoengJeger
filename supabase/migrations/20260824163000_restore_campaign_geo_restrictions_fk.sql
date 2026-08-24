create table if not exists public.campaign_geo_restrictions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  country_code text not null,
  created_at timestamptz not null default now(),
  constraint campaign_geo_restrictions_country_code_length check (char_length(country_code) = 2),
  unique (campaign_id, country_code)
);

create index if not exists campaign_geo_restrictions_campaign_idx
  on public.campaign_geo_restrictions (campaign_id);

alter table public.campaign_geo_restrictions enable row level security;

drop policy if exists "campaign geo restrictions for readable campaigns"
  on public.campaign_geo_restrictions;
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

drop policy if exists "admins manage campaign geo restrictions"
  on public.campaign_geo_restrictions;
create policy "admins manage campaign geo restrictions"
on public.campaign_geo_restrictions
for all
using (public.is_admin())
with check (public.is_admin());
