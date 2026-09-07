begin;

create temporary table tmp_trumf_rate_refresh (
  store_name text primary key,
  old_rate_label text not null,
  new_rate numeric not null
) on commit drop;

insert into tmp_trumf_rate_refresh (store_name, old_rate_label, new_rate)
values
  ('Siemens Home', '10,9% Trumf-bonus', 9.3),
  ('Autodude', '9,3% Trumf-bonus', 7.8);

create temporary table tmp_refreshed_rates on commit drop as
with refreshed as (
  update public.store_earning_rates as rate
  set
    rate_label = public.format_norwegian_decimal(target.new_rate, 1) || '% Trumf-bonus',
    normal_rate_label = case
      when rate.normal_rate_label is null then null
      else public.format_norwegian_decimal(target.new_rate, 1) || '% Trumf-bonus'
    end,
    value_summary = public.format_norwegian_decimal(target.new_rate, 1)
      || ' kr Trumf-bonus per 100 kr. Ved overføring til SAS EuroBonus tilsvarer det '
      || public.format_norwegian_decimal(target.new_rate * 10, 2)
      || ' poeng ved engangsoverføring eller '
      || public.format_norwegian_decimal(target.new_rate * 13.5, 2)
      || ' poeng ved automatisk overføring.',
    checked_at = now(),
    updated_at = now()
  from tmp_trumf_rate_refresh target
  join public.stores store on lower(store.name) = lower(target.store_name)
  join public.earning_methods method on method.slug = 'trumf'
  where rate.store_id = store.id
    and rate.earning_method_id = method.id
    and rate.status = 'published'
    and rate.rate_label = target.old_rate_label
  returning rate.id as rate_id, rate.store_id, target.store_name, target.new_rate
)
select * from refreshed;

update public.earning_combinations as combination
set
  total_value_label = public.format_norwegian_decimal(target.new_rate * 13.5, 2)
    || ' EB-poeng / 100 kr',
  summary = 'Start hos Trumf Netthandel før du handler hos '
    || target.store_name
    || '. '
    || public.format_norwegian_decimal(target.new_rate, 1)
    || ' % Trumf-bonus gir '
    || public.format_norwegian_decimal(target.new_rate, 1)
    || ' Trumf-kroner per 100 kr, som kan bli '
    || public.format_norwegian_decimal(target.new_rate * 13.5, 2)
    || ' EuroBonus-poeng med automatisk overføring eller '
    || public.format_norwegian_decimal(target.new_rate * 10, 2)
    || ' poeng ved engangsoverføring.',
  warning_text = 'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring er dokumentert minimum '
    || public.format_norwegian_decimal(target.new_rate * 10, 2)
    || ' EuroBonus-poeng per 100 kr. Kontroller satsen i portalen før kjøp.',
  last_verified_at = now(),
  updated_at = now()
from tmp_refreshed_rates target
where combination.store_id = target.store_id
  and combination.status = 'published'
  and exists (
    select 1
    from public.earning_combination_rates combination_rate
    where combination_rate.combination_id = combination.id
      and combination_rate.store_earning_rate_id = target.rate_id
  );

update public.stores as store
set
  last_verified_at = now(),
  updated_at = now()
from tmp_refreshed_rates target
where store.id = target.store_id;

commit;
