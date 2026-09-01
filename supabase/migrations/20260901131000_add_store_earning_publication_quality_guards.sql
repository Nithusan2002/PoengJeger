begin;

alter table public.stores
drop constraint if exists stores_published_quality_guard;

alter table public.stores
add constraint stores_published_quality_guard check (
  status <> 'published'
  or (
    last_verified_at is not null
    and nullif(trim(name), '') is not null
    and nullif(trim(slug), '') is not null
  )
) not valid;

alter table public.store_earning_rates
drop constraint if exists store_earning_rates_published_quality_guard;

alter table public.store_earning_rates
add constraint store_earning_rates_published_quality_guard check (
  status <> 'published'
  or (
    checked_at is not null
    and nullif(trim(rate_label), '') is not null
    and nullif(trim(requirement_summary), '') is not null
    and nullif(trim(source_url), '') is not null
    and nullif(trim(source_title), '') is not null
  )
) not valid;

alter table public.earning_combinations
drop constraint if exists earning_combinations_published_quality_guard;

alter table public.earning_combinations
add constraint earning_combinations_published_quality_guard check (
  status <> 'published'
  or (
    last_verified_at is not null
    and nullif(trim(title), '') is not null
    and nullif(trim(total_value_label), '') is not null
    and nullif(trim(summary), '') is not null
  )
) not valid;

create or replace view public.store_earning_publication_quality_issues
with (security_invoker = true)
as
select
  store.id as store_id,
  store.slug as store_slug,
  store.name as store_name,
  'store'::text as entity_type,
  store.id as entity_id,
  array_remove(array[
    case when store.last_verified_at is null then 'missing_last_verified_at' end,
    case when nullif(trim(store.name), '') is null then 'missing_name' end,
    case when nullif(trim(store.slug), '') is null then 'missing_slug' end
  ], null) as issue_codes
from public.stores store
where store.status = 'published'
  and (
    store.last_verified_at is null
    or nullif(trim(store.name), '') is null
    or nullif(trim(store.slug), '') is null
  )

union all

select
  store.id as store_id,
  store.slug as store_slug,
  store.name as store_name,
  'store_earning_rate'::text as entity_type,
  rate.id as entity_id,
  array_remove(array[
    case when rate.checked_at is null then 'missing_checked_at' end,
    case when nullif(trim(rate.rate_label), '') is null then 'missing_rate_label' end,
    case when nullif(trim(rate.requirement_summary), '') is null then 'missing_requirement_summary' end,
    case when nullif(trim(rate.source_url), '') is null then 'missing_source_url' end,
    case when nullif(trim(rate.source_title), '') is null then 'missing_source_title' end,
    case when rate.ends_at is not null and rate.ends_at < now() then 'expired_but_published' end
  ], null) as issue_codes
from public.store_earning_rates rate
join public.stores store on store.id = rate.store_id
where rate.status = 'published'
  and (
    rate.checked_at is null
    or nullif(trim(rate.rate_label), '') is null
    or nullif(trim(rate.requirement_summary), '') is null
    or nullif(trim(rate.source_url), '') is null
    or nullif(trim(rate.source_title), '') is null
    or (rate.ends_at is not null and rate.ends_at < now())
  )

union all

select
  store.id as store_id,
  store.slug as store_slug,
  store.name as store_name,
  'earning_combination'::text as entity_type,
  combo.id as entity_id,
  array_remove(array[
    case when combo.last_verified_at is null then 'missing_last_verified_at' end,
    case when nullif(trim(combo.title), '') is null then 'missing_title' end,
    case when nullif(trim(combo.total_value_label), '') is null then 'missing_total_value_label' end,
    case when nullif(trim(combo.summary), '') is null then 'missing_summary' end,
    case
      when not exists (
        select 1
        from public.earning_combination_rates combo_rate
        where combo_rate.combination_id = combo.id
      ) then 'missing_combination_rates'
    end
  ], null) as issue_codes
from public.earning_combinations combo
join public.stores store on store.id = combo.store_id
where combo.status = 'published'
  and (
    combo.last_verified_at is null
    or nullif(trim(combo.title), '') is null
    or nullif(trim(combo.total_value_label), '') is null
    or nullif(trim(combo.summary), '') is null
    or not exists (
      select 1
      from public.earning_combination_rates combo_rate
      where combo_rate.combination_id = combo.id
    )
  );

comment on view public.store_earning_publication_quality_issues is
  'Redaksjonell pilot-audit for publisert butikkopptjening som mangler minimumsfelt eller har utløpte publiserte satser.';

commit;
