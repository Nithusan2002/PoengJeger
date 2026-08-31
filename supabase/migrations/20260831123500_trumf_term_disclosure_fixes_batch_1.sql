with target_rates as (
  select
    rate.id as rate_id,
    store.id as store_id,
    store.name as store_name,
    case store.name
      when 'FotoKnudsen' then 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
      when 'Nextory' then 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
      when 'Kinoklubb' then 'Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
      when 'Zooplus' then 'Høyeste Trumf-sats gjelder nye kunder. Andre og tredje kjøp for nye kunder og kjøp fra eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
      when 'Autodoc' then 'Høyeste Trumf-sats gjelder ny kunde. Dekk og kjøp fra eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
    end as requirement_summary,
    case store.name
      when 'FotoKnudsen' then 'Kildekontroll viser 9,3 % for ny kunde og 4,6 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Nextory' then 'Det gis ikke Trumf-bonus dersom abonnementet sies opp i prøveperioden. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Kinoklubb' then 'Hvis kjøpet er et abonnement, er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Zooplus' then 'Kildekontroll viser 6,2 % for ny kunde, 4,6 % for andre og tredje kjøp som ny kunde, og 1,5 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Autodoc' then 'Kildekontroll viser 6,2 % for ny kunde, 3,1 % for eksisterende kunde og 0,7 % for dekk. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
    end as warning_text,
    case store.name
      when 'Autodoc' then 'Opptil 6,2% Trumf-bonus'
      else rate.rate_label
    end as rate_label,
    case store.name
      when 'Autodoc' then 'Opptil 6,2% Trumf-bonus'
      else rate.value_summary
    end as value_summary
  from public.store_earning_rates rate
  join public.stores store on store.id = rate.store_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where method.slug = 'trumf'
    and store.name in ('FotoKnudsen', 'Nextory', 'Kinoklubb', 'Zooplus', 'Autodoc')
)
update public.store_earning_rates rate
set
  rate_label = target.rate_label,
  value_summary = target.value_summary,
  requirement_summary = target.requirement_summary,
  warning_text = target.warning_text,
  checked_at = now(),
  updated_at = now()
from target_rates target
where rate.id = target.rate_id;

with target_combinations as (
  select distinct
    combo.id as combo_id,
    store.name as store_name,
    case store.name
      when 'FotoKnudsen' then 'Åpne FotoKnudsen via Trumf Netthandel før kjøpet. Høyeste dokumenterte sats gjelder nye kunder; eksisterende kunder har lavere Trumf-sats.'
      when 'Nextory' then 'Start hos Trumf Netthandel før du tegner Nextory som ny kunde. 35 Trumf-kroner kan bli 472,5 EuroBonus-poeng med automatisk overføring eller 350 poeng ved engangsoverføring.'
      when 'Kinoklubb' then 'Start hos Trumf Netthandel før du handler hos Kinoklubb. 35 Trumf-kroner kan bli 472,5 EuroBonus-poeng med automatisk overføring eller 350 poeng ved engangsoverføring.'
      when 'Zooplus' then 'Åpne Zooplus via Trumf Netthandel før kjøpet. Høyeste dokumenterte sats gjelder nye kunder; senere kjøp og eksisterende kunder har lavere Trumf-sats.'
    end as summary,
    case store.name
      when 'FotoKnudsen' then 'Kildekontroll viser 9,3 % for ny kunde og 4,6 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Nextory' then 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget, og det gis ikke Trumf-bonus hvis abonnementet sies opp i prøveperioden. Beregningen forutsetter automatisk Trumf-overføring til EuroBonus.'
      when 'Kinoklubb' then 'Ved abonnement er kun første betaling bonusberettiget. Beregningen forutsetter automatisk Trumf-overføring til EuroBonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
      when 'Zooplus' then 'Kildekontroll viser 6,2 % for ny kunde, 4,6 % for andre og tredje kjøp som ny kunde, og 1,5 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'
    end as warning_text
  from public.earning_combinations combo
  join public.stores store on store.id = combo.store_id
  join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
  join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
  join public.earning_methods method on method.id = rate.earning_method_id
  where method.slug = 'trumf'
    and store.name in ('FotoKnudsen', 'Nextory', 'Kinoklubb', 'Zooplus')
)
update public.earning_combinations combo
set
  summary = target.summary,
  warning_text = target.warning_text,
  last_verified_at = now(),
  updated_at = now()
from target_combinations target
where combo.id = target.combo_id;

update public.stores store
set
  last_verified_at = now(),
  updated_at = now()
where store.name in ('FotoKnudsen', 'Nextory', 'Kinoklubb', 'Zooplus', 'Autodoc');
