begin;

delete from public.earning_combination_rates combo_rate
using public.earning_combinations combo,
      public.stores store,
      public.store_earning_rates rate,
      public.earning_methods method
where combo.id = combo_rate.combination_id
  and store.id = combo.store_id
  and rate.id = combo_rate.store_earning_rate_id
  and method.id = rate.earning_method_id
  and store.name = 'YouWish'
  and (
    (combo.title = 'Trumf Netthandel' and method.slug <> 'trumf')
    or (
      combo.title = 'EuroBonus Online Shopping'
      and method.slug <> 'sas-eurobonus-online-shopping'
    )
  );

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
  from public.stores store
  join public.earning_combinations combo on combo.store_id = store.id
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where store.name = 'YouWish'
    and combo.status = 'published'
    and rate.status = 'published'
    and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
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
