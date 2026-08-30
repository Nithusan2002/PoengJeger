begin;

create temporary table tmp_comparable_mixed_sas_trumf_stores on commit drop as
select store.id as store_id
from public.stores store
where store.status = 'published'
  and exists (
    select 1
    from public.store_earning_rates rate
    join public.earning_methods method on method.id = rate.earning_method_id
    where rate.store_id = store.id
      and rate.status = 'published'
      and method.slug = 'trumf'
      and position('%' in rate.rate_label) > 0
      and rate.rate_label not ilike '%opptil%'
      and public.extract_first_decimal(rate.rate_label) is not null
  )
  and exists (
    select 1
    from public.store_earning_rates rate
    join public.earning_methods method on method.id = rate.earning_method_id
    where rate.store_id = store.id
      and rate.status = 'published'
      and method.slug = 'sas-eurobonus-online-shopping'
      and rate.rate_label ilike '%per 100 kr%'
      and public.extract_first_decimal(rate.rate_label) is not null
  );

update public.store_earning_rates rate
set
  value_summary = case method.slug
    when 'trumf' then
      public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label), 2)
      || ' kr Trumf-bonus per 100 kr. Ved overføring til SAS EuroBonus tilsvarer det '
      || public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label) * 10, 2)
      || ' poeng ved engangsoverføring eller '
      || public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label) * 13.5, 2)
      || ' poeng ved automatisk overføring.'
    when 'sas-eurobonus-online-shopping' then
      public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label), 2)
      || ' EuroBonus-poeng per 100 kr.'
    else rate.value_summary
  end,
  warning_text = case method.slug
    when 'trumf' then
      'EuroBonus-ekvivalensen er beregnet fra Trumfs overføringskurser: 10 poeng per Trumf-krone ved engangsoverføring og 13,5 poeng per Trumf-krone ved automatisk overføring. Du kan ikke bruke både Trumf Netthandel og SAS EuroBonus Online Shopping på samme portalklikk.'
    when 'sas-eurobonus-online-shopping' then
      'Sammenlign mot Trumf Netthandel når kunden kan overføre Trumf-bonus til SAS EuroBonus. Du kan ikke bruke både SAS EuroBonus Online Shopping og Trumf Netthandel på samme portalklikk.'
    else rate.warning_text
  end,
  sort_order = case method.slug
    when 'trumf' then 10
    when 'sas-eurobonus-online-shopping' then 20
    else rate.sort_order
  end,
  updated_at = now()
from public.earning_methods method
join tmp_comparable_mixed_sas_trumf_stores mixed on true
where method.id = rate.earning_method_id
  and rate.store_id = mixed.store_id
  and rate.status = 'published'
  and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
  and (
    (
      method.slug = 'trumf'
      and position('%' in rate.rate_label) > 0
      and rate.rate_label not ilike '%opptil%'
    )
    or (
      method.slug = 'sas-eurobonus-online-shopping'
      and rate.rate_label ilike '%per 100 kr%'
    )
  )
  and public.extract_first_decimal(rate.rate_label) is not null;

with scored_combinations as (
  select
    combo.id as combination_id,
    store.id as store_id,
    store.name as store_name,
    method.slug as method_slug,
    rate.handoff_url,
    public.extract_first_decimal(rate.rate_label) as documented_rate,
    case method.slug
      when 'trumf' then public.extract_first_decimal(rate.rate_label) * 13.5
      when 'sas-eurobonus-online-shopping' then public.extract_first_decimal(rate.rate_label)
      else null
    end as eurobonus_auto_points_per_100,
    case method.slug
      when 'trumf' then public.extract_first_decimal(rate.rate_label) * 10
      else null
    end as eurobonus_single_points_per_100
  from tmp_comparable_mixed_sas_trumf_stores mixed
  join public.stores store on store.id = mixed.store_id
  join public.earning_combinations combo on combo.store_id = mixed.store_id
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where combo.status = 'published'
    and rate.status = 'published'
    and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
    and (
      (
        method.slug = 'trumf'
        and position('%' in rate.rate_label) > 0
        and rate.rate_label not ilike '%opptil%'
      )
      or (
        method.slug = 'sas-eurobonus-online-shopping'
        and rate.rate_label ilike '%per 100 kr%'
      )
    )
    and public.extract_first_decimal(rate.rate_label) is not null
),
ranked_combinations as (
  select
    *,
    row_number() over (
      partition by store_id
      order by eurobonus_auto_points_per_100 desc, method_slug desc
    ) * 10 as resolved_sort_order
  from scored_combinations
)
update public.earning_combinations combo
set
  total_value_label = public.format_norwegian_decimal(ranked.eurobonus_auto_points_per_100, 2)
    || ' EB-poeng / 100 kr',
  summary = case ranked.method_slug
    when 'trumf' then
      'Start hos Trumf Netthandel før du handler hos '
      || ranked.store_name
      || '. '
      || public.format_norwegian_decimal(ranked.documented_rate, 2)
      || ' % Trumf-bonus gir '
      || public.format_norwegian_decimal(ranked.documented_rate, 2)
      || ' Trumf-kroner per 100 kr, som kan bli '
      || public.format_norwegian_decimal(ranked.eurobonus_auto_points_per_100, 2)
      || ' EuroBonus-poeng med automatisk overføring eller '
      || public.format_norwegian_decimal(ranked.eurobonus_single_points_per_100, 2)
      || ' poeng ved engangsoverføring.'
    when 'sas-eurobonus-online-shopping' then
      'Start hos SAS EuroBonus Online Shopping før du handler hos '
      || ranked.store_name
      || ' hvis du vil ha direkte EuroBonus-opptjening uten å gå via Trumf.'
    else combo.summary
  end,
  easier_alternative_label = case ranked.method_slug
    when 'trumf' then (
      select public.format_norwegian_decimal(max(other.eurobonus_auto_points_per_100), 2)
        || ' EB-poeng / 100 kr direkte via SAS'
      from ranked_combinations other
      where other.store_id = ranked.store_id
        and other.method_slug = 'sas-eurobonus-online-shopping'
    )
    else combo.easier_alternative_label
  end,
  warning_text = case ranked.method_slug
    when 'trumf' then
      'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring er dokumentert minimum '
      || public.format_norwegian_decimal(ranked.eurobonus_single_points_per_100, 2)
      || ' EuroBonus-poeng per 100 kr. Kontroller satsen i portalen før kjøp.'
    when 'sas-eurobonus-online-shopping' then
      'SAS-satsen kan være lavere enn Trumf-alternativet målt som EuroBonus-ekvivalent, men enklere hvis du ikke vil bruke Trumf-overføring.'
    else combo.warning_text
  end,
  primary_handoff_url = ranked.handoff_url,
  last_verified_at = now(),
  sort_order = ranked.resolved_sort_order,
  updated_at = now()
from ranked_combinations ranked
where combo.id = ranked.combination_id;

commit;
