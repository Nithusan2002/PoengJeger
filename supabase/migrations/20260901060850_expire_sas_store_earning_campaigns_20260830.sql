begin;

create temporary table tmp_expired_sas_store_earning_rates on commit drop as
select rate.id as rate_id
from public.store_earning_rates rate
join public.stores store on store.id = rate.store_id
join public.earning_methods method on method.id = rate.earning_method_id
where rate.status = 'published'
  and method.slug = 'sas-eurobonus-online-shopping'
  and store.slug in (
    'autodoc',
    'bilxtra',
    'bjorn-borg',
    'bubbleroom',
    'dyson',
    'farmasiet',
    'fotono',
    'gents',
    'gina-tricot-ab',
    'kicks',
    'outnorth',
    'parfymno',
    'pilgrim',
    'readly',
    'siemens',
    'weekday'
  )
  and (
    rate.ends_at < now()
    or rate.rate_label ilike '%kampanje til 30.08.2026%'
    or rate.normal_rate_label ilike '%kampanje til 30.08.2026%'
    or rate.value_summary ilike '%kampanje til 30.08.2026%'
  );

update public.earning_combinations combo
set
  status = 'archived',
  warning_text = coalesce(
    combo.warning_text,
    'Arkivert fordi den dokumenterte SAS-kampanjesatsen utløp 30.08.2026 og ikke er re-verifisert som aktiv.'
  ),
  updated_at = now()
where combo.status = 'published'
  and exists (
    select 1
    from public.earning_combination_rates combo_rate
    join tmp_expired_sas_store_earning_rates expired
      on expired.rate_id = combo_rate.store_earning_rate_id
    where combo_rate.combination_id = combo.id
  )
  and not exists (
    select 1
    from public.earning_combination_rates combo_rate
    where combo_rate.combination_id = combo.id
      and combo_rate.store_earning_rate_id not in (
        select rate_id
        from tmp_expired_sas_store_earning_rates
      )
  );

update public.store_earning_rates rate
set
  status = 'expired',
  warning_text = 'Utløpt SAS-kampanjesats. Må hentes og kontrolleres på nytt før den kan publiseres igjen.',
  updated_at = now()
from tmp_expired_sas_store_earning_rates expired
where rate.id = expired.rate_id;

commit;
