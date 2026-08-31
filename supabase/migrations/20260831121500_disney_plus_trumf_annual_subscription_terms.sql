with disney_trumf_rate as (
  select rate.id
  from public.store_earning_rates rate
  join public.stores store on store.id = rate.store_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where store.name = 'Disney+'
    and method.slug = 'trumf'
),
disney_trumf_combinations as (
  select distinct combo.id
  from public.earning_combinations combo
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join disney_trumf_rate rate on rate.id = combo_rate.store_earning_rate_id
)
update public.store_earning_rates rate
set
  requirement_summary = 'Gjelder nye kunder ved kjøp av Disney+ årsabonnement. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.',
  warning_text = 'Kjøp med rabattkode genererer normalt ikke Trumf-bonus med mindre annet er oppgitt. Kontroller vilkårene hos Trumf før kjøp.',
  updated_at = now()
from disney_trumf_rate target
where rate.id = target.id;

with disney_trumf_rate as (
  select rate.id
  from public.store_earning_rates rate
  join public.stores store on store.id = rate.store_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where store.name = 'Disney+'
    and method.slug = 'trumf'
),
disney_trumf_combinations as (
  select distinct combo.id
  from public.earning_combinations combo
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join disney_trumf_rate rate on rate.id = combo_rate.store_earning_rate_id
)
update public.earning_combinations combo
set
  summary = 'Start hos Trumf Netthandel før du kjøper Disney+ årsabonnement som ny kunde. 110 Trumf-kroner kan bli 1485 EuroBonus-poeng med automatisk overføring eller 1100 poeng ved engangsoverføring.',
  warning_text = 'Gjelder nye kunder ved kjøp av Disney+ årsabonnement. Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring gir samme Trumf-bonus 1100 EuroBonus-poeng. Rabattkoder kan gjøre at Trumf-bonus ikke spores.',
  updated_at = now()
from disney_trumf_combinations target
where combo.id = target.id;
