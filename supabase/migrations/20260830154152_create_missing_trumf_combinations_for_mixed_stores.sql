begin;

create temporary table tmp_missing_trumf_combinations on commit drop as
with comparable_trumf_rates as (
  select
    store.id as store_id,
    store.name as store_name,
    rate.id as rate_id,
    rate.rate_label,
    rate.handoff_url,
    public.extract_first_decimal(rate.rate_label) as documented_rate
  from public.stores store
  join public.store_earning_rates rate on rate.store_id = store.id
  join public.earning_methods method on method.id = rate.earning_method_id
  where store.status = 'published'
    and rate.status = 'published'
    and method.slug = 'trumf'
    and position('%' in rate.rate_label) > 0
    and rate.rate_label not ilike '%opptil%'
    and public.extract_first_decimal(rate.rate_label) is not null
    and exists (
      select 1
      from public.store_earning_rates sas_rate
      join public.earning_methods sas_method on sas_method.id = sas_rate.earning_method_id
      where sas_rate.store_id = store.id
        and sas_rate.status = 'published'
        and sas_method.slug = 'sas-eurobonus-online-shopping'
        and sas_rate.rate_label ilike '%per 100 kr%'
        and public.extract_first_decimal(sas_rate.rate_label) is not null
    )
    and not exists (
      select 1
      from public.earning_combination_rates combo_rate
      join public.earning_combinations combo on combo.id = combo_rate.combination_id
      where combo_rate.store_earning_rate_id = rate.id
        and combo.status = 'published'
    )
),
inserted as (
  insert into public.earning_combinations (
    store_id,
    status,
    title,
    total_value_label,
    summary,
    easier_alternative_label,
    warning_text,
    primary_handoff_url,
    last_verified_at,
    sort_order
  )
  select
    trumf.store_id,
    'published',
    'Trumf Netthandel',
    public.format_norwegian_decimal(trumf.documented_rate * 13.5, 2)
      || ' EB-poeng / 100 kr',
    'Start hos Trumf Netthandel før du handler hos '
      || trumf.store_name
      || '. '
      || public.format_norwegian_decimal(trumf.documented_rate, 2)
      || ' % Trumf-bonus gir '
      || public.format_norwegian_decimal(trumf.documented_rate, 2)
      || ' Trumf-kroner per 100 kr, som kan bli '
      || public.format_norwegian_decimal(trumf.documented_rate * 13.5, 2)
      || ' EuroBonus-poeng med automatisk overføring eller '
      || public.format_norwegian_decimal(trumf.documented_rate * 10, 2)
      || ' poeng ved engangsoverføring.',
    (
      select public.format_norwegian_decimal(max(public.extract_first_decimal(sas_rate.rate_label)), 2)
        || ' EB-poeng / 100 kr direkte via SAS'
      from public.store_earning_rates sas_rate
      join public.earning_methods sas_method on sas_method.id = sas_rate.earning_method_id
      where sas_rate.store_id = trumf.store_id
        and sas_rate.status = 'published'
        and sas_method.slug = 'sas-eurobonus-online-shopping'
        and sas_rate.rate_label ilike '%per 100 kr%'
    ),
    'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring er dokumentert minimum '
      || public.format_norwegian_decimal(trumf.documented_rate * 10, 2)
      || ' EuroBonus-poeng per 100 kr. Kontroller satsen i portalen før kjøp.',
    trumf.handoff_url,
    now(),
    10
  from comparable_trumf_rates trumf
  returning id, store_id
)
select
  inserted.id as combination_id,
  trumf.rate_id
from inserted
join comparable_trumf_rates trumf on trumf.store_id = inserted.store_id;

insert into public.earning_combination_rates (
  combination_id,
  store_earning_rate_id,
  sort_order
)
select combination_id, rate_id, 0
from tmp_missing_trumf_combinations
on conflict do nothing;

update public.earning_combinations combo
set sort_order = ranked.resolved_sort_order,
    updated_at = now()
from (
  select
    combo.id,
    row_number() over (
      partition by combo.store_id
      order by case method.slug
        when 'trumf' then public.extract_first_decimal(rate.rate_label) * 13.5
        when 'sas-eurobonus-online-shopping' then public.extract_first_decimal(rate.rate_label)
        else 0
      end desc
    ) * 10 as resolved_sort_order
  from public.earning_combinations combo
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where combo.store_id in (
    select distinct store_id
    from public.earning_combinations
    where id in (
      select combination_id
      from tmp_missing_trumf_combinations
    )
  )
    and combo.status = 'published'
    and rate.status = 'published'
    and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
) ranked
where combo.id = ranked.id;

commit;
