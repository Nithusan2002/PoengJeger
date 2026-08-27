begin;

create table if not exists public.product_events (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  event_name text not null,
  anonymous_user_id uuid not null,
  session_id uuid not null,
  surface text,
  entity_type text,
  entity_id uuid,
  properties jsonb not null default '{}'::jsonb,
  app_version text,
  platform text not null default 'ios',
  created_at timestamptz not null default now(),
  constraint product_events_event_name_check check (
    event_name in (
      'app_opened',
      'program_selected',
      'store_search_started',
      'store_search_result_opened',
      'store_detail_opened',
      'best_combination_viewed',
      'handoff_opened',
      'external_destination_opened',
      'campaign_detail_opened',
      'favorite_added',
      'favorite_removed',
      'filter_applied',
      'notification_enabled',
      'notification_opened',
      'notification_disabled',
      'guide_opened',
      'premium_candidate_used'
    )
  ),
  constraint product_events_surface_check check (
    surface is null or surface in (
      'app',
      'home',
      'store_search',
      'store_detail',
      'how_to_earn',
      'feed',
      'campaign_detail',
      'favorites',
      'guide',
      'settings'
    )
  ),
  constraint product_events_entity_type_check check (
    entity_type is null or entity_type in (
      'bonus_program',
      'store',
      'campaign',
      'guide',
      'category',
      'earning_combination'
    )
  ),
  constraint product_events_properties_object_check check (
    jsonb_typeof(properties) = 'object'
  ),
  constraint product_events_properties_size_check check (
    pg_column_size(properties) <= 4096
  )
);

create index if not exists product_events_occurred_at_idx
  on public.product_events (occurred_at desc);

create index if not exists product_events_event_time_idx
  on public.product_events (event_name, occurred_at desc);

create index if not exists product_events_anonymous_user_time_idx
  on public.product_events (anonymous_user_id, occurred_at desc);

create or replace function public.product_event_properties_are_safe(p_properties jsonb)
returns boolean
language sql
immutable
as $$
  select
    jsonb_typeof(p_properties) = 'object'
    and (
      select count(*)
      from jsonb_each(p_properties)
    ) <= 20
    and not exists (
      select 1
      from jsonb_each(p_properties) as property(key, value)
      where key !~ '^[a-z0-9_]+$'
        or jsonb_typeof(value) not in ('string', 'number', 'boolean', 'null')
        or (
          jsonb_typeof(value) = 'string'
          and length(value #>> '{}') > 200
        )
    );
$$;

create or replace function public.validate_product_event()
returns trigger
language plpgsql
as $$
begin
  if not public.product_event_properties_are_safe(new.properties) then
    raise exception 'Unsafe product event properties';
  end if;

  if new.occurred_at > now() + interval '5 minutes' then
    raise exception 'Product event timestamp cannot be in the future';
  end if;

  if new.occurred_at < now() - interval '30 days' then
    raise exception 'Product event timestamp is too old';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_product_event_before_insert on public.product_events;
create trigger validate_product_event_before_insert
before insert on public.product_events
for each row execute function public.validate_product_event();

alter table public.product_events enable row level security;

create policy "clients insert product events"
on public.product_events
for insert
to anon, authenticated
with check (true);

create policy "editorial members read product events"
on public.product_events
for select
to authenticated
using (public.is_editorial_member());

revoke all on public.product_events from anon, authenticated;
grant insert on public.product_events to anon, authenticated;
grant select on public.product_events to authenticated;

commit;
