begin;

with electrolux_store as (
  select id
  from public.stores
  where slug = 'electrolux'
),
trumf_rate as (
  select ser.id
  from public.store_earning_rates ser
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ser.store_id
  where em.slug = 'trumf'
),
sas_rate as (
  select ser.id
  from public.store_earning_rates ser
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ser.store_id
  where em.slug = 'sas-eurobonus-online-shopping'
)
update public.stores
set
  last_verified_at = '2026-08-30T00:00:00Z',
  updated_at = now()
where id in (select id from electrolux_store);

with electrolux_store as (
  select id
  from public.stores
  where slug = 'electrolux'
)
update public.store_earning_rates ser
set
  value_summary = case em.slug
    when 'trumf' then '3,9 kr Trumf-bonus per 100 kr. Ved overføring til SAS EuroBonus tilsvarer det 39 poeng ved engangsoverføring eller 52,65 poeng ved automatisk overføring.'
    when 'sas-eurobonus-online-shopping' then '25 EuroBonus-poeng per 100 kr.'
    else ser.value_summary
  end,
  warning_text = case em.slug
    when 'trumf' then 'EuroBonus-ekvivalensen er beregnet fra Trumfs overføringskurser: 10 poeng per Trumf-krone ved engangsoverføring og 13,5 poeng per Trumf-krone ved automatisk overføring. Du kan ikke bruke både Trumf Netthandel og SAS EuroBonus Online Shopping på samme portalklikk.'
    when 'sas-eurobonus-online-shopping' then 'Trumf Netthandel gir høyere EuroBonus-ekvivalent hvis du overfører Trumf-bonusen til SAS EuroBonus. Du kan ikke bruke både SAS EuroBonus Online Shopping og Trumf Netthandel på samme portalklikk.'
    else ser.warning_text
  end,
  checked_at = '2026-08-30T00:00:00Z',
  sort_order = case em.slug
    when 'trumf' then 10
    when 'sas-eurobonus-online-shopping' then 20
    else ser.sort_order
  end,
  updated_at = now()
from public.earning_methods em, electrolux_store s
where ser.earning_method_id = em.id
  and ser.store_id = s.id
  and em.slug in ('trumf', 'sas-eurobonus-online-shopping');

with electrolux_store as (
  select id
  from public.stores
  where slug = 'electrolux'
),
trumf_combination as (
  select ec.id
  from public.earning_combinations ec
  join public.earning_combination_rates ecr on ecr.combination_id = ec.id
  join public.store_earning_rates ser on ser.id = ecr.store_earning_rate_id
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ec.store_id
  where em.slug = 'trumf'
),
sas_combination as (
  select ec.id
  from public.earning_combinations ec
  join public.earning_combination_rates ecr on ecr.combination_id = ec.id
  join public.store_earning_rates ser on ser.id = ecr.store_earning_rate_id
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ec.store_id
  where em.slug = 'sas-eurobonus-online-shopping'
)
update public.earning_combinations ec
set
  title = case
    when ec.id in (select id from trumf_combination) then 'Trumf Netthandel'
    when ec.id in (select id from sas_combination) then 'EuroBonus Online Shopping'
    else ec.title
  end,
  total_value_label = case
    when ec.id in (select id from trumf_combination) then '52,65 EB-poeng / 100 kr'
    when ec.id in (select id from sas_combination) then '25 EB-poeng / 100 kr'
    else ec.total_value_label
  end,
  summary = case
    when ec.id in (select id from trumf_combination) then 'Start hos Trumf Netthandel før du handler hos Electrolux. 3,9 % Trumf-bonus gir 3,90 Trumf-kroner per 100 kr, som kan bli 52,65 EuroBonus-poeng med automatisk overføring eller 39 poeng ved engangsoverføring.'
    when ec.id in (select id from sas_combination) then 'Start hos SAS EuroBonus Online Shopping før du handler hos Electrolux hvis du vil ha direkte EuroBonus-opptjening uten å gå via Trumf.'
    else ec.summary
  end,
  easier_alternative_label = case
    when ec.id in (select id from trumf_combination) then '25 EB-poeng / 100 kr direkte via SAS'
    else ec.easier_alternative_label
  end,
  warning_text = case
    when ec.id in (select id from trumf_combination) then 'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring er dokumentert minimum 39 EuroBonus-poeng per 100 kr. Kontroller satsen i portalen før kjøp.'
    when ec.id in (select id from sas_combination) then 'SAS-satsen er lavere enn Trumf-alternativet målt som EuroBonus-ekvivalent, men enklere hvis du ikke vil bruke Trumf-overføring.'
    else ec.warning_text
  end,
  last_verified_at = '2026-08-30T00:00:00Z',
  sort_order = case
    when ec.id in (select id from trumf_combination) then 10
    when ec.id in (select id from sas_combination) then 20
    else ec.sort_order
  end,
  updated_at = now()
where ec.id in (
  select id from trumf_combination
  union
  select id from sas_combination
);

delete from public.earning_combination_steps
where combination_id in (
  select ec.id
  from public.earning_combinations ec
  join public.stores s on s.id = ec.store_id
  where s.slug = 'electrolux'
);

with electrolux_store as (
  select id
  from public.stores
  where slug = 'electrolux'
),
trumf_combination as (
  select ec.id
  from public.earning_combinations ec
  join public.earning_combination_rates ecr on ecr.combination_id = ec.id
  join public.store_earning_rates ser on ser.id = ecr.store_earning_rate_id
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ec.store_id
  where em.slug = 'trumf'
),
sas_combination as (
  select ec.id
  from public.earning_combinations ec
  join public.earning_combination_rates ecr on ecr.combination_id = ec.id
  join public.store_earning_rates ser on ser.id = ecr.store_earning_rate_id
  join public.earning_methods em on em.id = ser.earning_method_id
  join electrolux_store s on s.id = ec.store_id
  where em.slug = 'sas-eurobonus-online-shopping'
)
insert into public.earning_combination_steps (combination_id, text, sort_order)
select id, text, sort_order
from (
  select id, 'Start hos Trumf Netthandel og åpne Electrolux derfra.' as text, 10 as sort_order
  from trumf_combination
  union all
  select id, 'Start med tom handlekurv og fullfør kjøpet i samme nettleserøkt.' as text, 20 as sort_order
  from trumf_combination
  union all
  select id, 'Bruk automatisk Trumf-overføring til SAS EuroBonus hvis du vil ha høyeste EuroBonus-ekvivalent.' as text, 30 as sort_order
  from trumf_combination
  union all
  select id, 'Start hos SAS EuroBonus Online Shopping og åpne Electrolux derfra.' as text, 10 as sort_order
  from sas_combination
  union all
  select id, 'Fullfør kjøpet i samme nettleserøkt og kontroller at kjøpet spores i EuroBonus.' as text, 20 as sort_order
  from sas_combination
) steps;

commit;
