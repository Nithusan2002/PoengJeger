begin;

create temporary table tmp_fixed_bonus_stores on commit drop as
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
      and rate.rate_label ilike '% kr Trumf-bonus'
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
      and rate.rate_label ilike '%EuroBonus-poeng%'
      and rate.rate_label not ilike '%per 100 kr%'
      and public.extract_first_decimal(rate.rate_label) is not null
  );

with fixed_scores as (
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
    end as eurobonus_auto_points,
    case method.slug
      when 'trumf' then public.extract_first_decimal(rate.rate_label) * 10
      else null
    end as eurobonus_single_points
  from tmp_fixed_bonus_stores fixed
  join public.stores store on store.id = fixed.store_id
  join public.earning_combinations combo on combo.store_id = store.id
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where combo.status = 'published'
    and rate.status = 'published'
    and (
      (
        method.slug = 'trumf'
        and rate.rate_label ilike '% kr Trumf-bonus'
        and rate.rate_label not ilike '%opptil%'
      )
      or (
        method.slug = 'sas-eurobonus-online-shopping'
        and rate.rate_label ilike '%EuroBonus-poeng%'
        and rate.rate_label not ilike '%per 100 kr%'
      )
    )
    and public.extract_first_decimal(rate.rate_label) is not null
),
ranked_fixed as (
  select
    *,
    row_number() over (
      partition by store_id
      order by eurobonus_auto_points desc, method_slug desc
    ) * 10 as resolved_sort_order
  from fixed_scores
)
update public.earning_combinations combo
set
  total_value_label = public.format_norwegian_decimal(ranked.eurobonus_auto_points, 2)
    || ' EB-poeng',
  summary = case ranked.method_slug
    when 'trumf' then
      'Start hos Trumf Netthandel før du handler hos '
      || ranked.store_name
      || '. '
      || public.format_norwegian_decimal(ranked.documented_rate, 2)
      || ' Trumf-kroner kan bli '
      || public.format_norwegian_decimal(ranked.eurobonus_auto_points, 2)
      || ' EuroBonus-poeng med automatisk overføring eller '
      || public.format_norwegian_decimal(ranked.eurobonus_single_points, 2)
      || ' poeng ved engangsoverføring.'
    when 'sas-eurobonus-online-shopping' then
      'Start hos SAS EuroBonus Online Shopping før du handler hos '
      || ranked.store_name
      || ' hvis du vil ha direkte EuroBonus-opptjening uten å gå via Trumf.'
    else combo.summary
  end,
  easier_alternative_label = case ranked.method_slug
    when 'trumf' then (
      select public.format_norwegian_decimal(max(other.eurobonus_auto_points), 2)
        || ' EB-poeng direkte via SAS'
      from ranked_fixed other
      where other.store_id = ranked.store_id
        and other.method_slug = 'sas-eurobonus-online-shopping'
    )
    else combo.easier_alternative_label
  end,
  warning_text = case ranked.method_slug
    when 'trumf' then
      'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring gir samme Trumf-bonus '
      || public.format_norwegian_decimal(ranked.eurobonus_single_points, 2)
      || ' EuroBonus-poeng. Kontroller vilkår og sporingskrav hos portalen før kjøp.'
    when 'sas-eurobonus-online-shopping' then
      'SAS-satsen kan være lavere enn Trumf-alternativet målt som EuroBonus-ekvivalent, men enklere hvis du ikke vil bruke Trumf-overføring.'
    else combo.warning_text
  end,
  primary_handoff_url = ranked.handoff_url,
  last_verified_at = now(),
  sort_order = ranked.resolved_sort_order,
  updated_at = now()
from ranked_fixed ranked
where combo.id = ranked.combination_id;

create temporary table tmp_opptil_stores on commit drop as
select distinct store.id as store_id
from public.stores store
join public.store_earning_rates trumf_rate on trumf_rate.store_id = store.id
join public.earning_methods trumf_method on trumf_method.id = trumf_rate.earning_method_id
where store.status = 'published'
  and trumf_rate.status = 'published'
  and trumf_method.slug = 'trumf'
  and trumf_rate.rate_label ilike '%opptil%'
  and exists (
    select 1
    from public.store_earning_rates sas_rate
    join public.earning_methods sas_method on sas_method.id = sas_rate.earning_method_id
    where sas_rate.store_id = store.id
      and sas_rate.status = 'published'
      and sas_method.slug = 'sas-eurobonus-online-shopping'
  );

update public.store_earning_rates rate
set
  warning_text = case method.slug
    when 'trumf' then
      'Trumf-satsen er oppgitt som opptil-verdi og kan ikke rangeres som sikker beste mulighet uten å kontrollere hvilke varer, abonnement eller kjøpsbeløp som gir høyeste sats.'
    when 'sas-eurobonus-online-shopping' then
      'SAS-satsen er brukt som konservativ anbefaling fordi Trumf-satsen er oppgitt som opptil-verdi.'
    else rate.warning_text
  end,
  sort_order = case method.slug
    when 'sas-eurobonus-online-shopping' then 10
    when 'trumf' then 20
    else rate.sort_order
  end,
  updated_at = now()
from public.earning_methods method
join tmp_opptil_stores opptil on true
where method.id = rate.earning_method_id
  and rate.store_id = opptil.store_id
  and rate.status = 'published'
  and method.slug in ('trumf', 'sas-eurobonus-online-shopping');

update public.earning_combinations combo
set
  warning_text = case method.slug
    when 'trumf' then
      'Trumf er oppgitt som opptil-verdi. Bruk denne bare når portalen bekrefter at kjøpet ditt gir høyeste sats.'
    when 'sas-eurobonus-online-shopping' then
      'Konservativ anbefaling: SAS-satsen er fast, mens Trumf-satsen er oppgitt som opptil-verdi.'
    else combo.warning_text
  end,
  sort_order = case method.slug
    when 'sas-eurobonus-online-shopping' then 10
    when 'trumf' then 20
    else combo.sort_order
  end,
  updated_at = now()
from public.earning_combination_rates combo_rate
join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
join public.earning_methods method on method.id = rate.earning_method_id
join tmp_opptil_stores opptil on opptil.store_id = rate.store_id
where combo_rate.combination_id = combo.id
  and combo.store_id = opptil.store_id
  and combo.status = 'published'
  and method.slug in ('trumf', 'sas-eurobonus-online-shopping');

commit;
