begin;

update public.ingestion_candidates candidate
set
  status = 'rejected',
  reviewed_at = now(),
  review_note = case candidate.title
    when 'SAS EuroBonus Shopping: Bærum Energi' then
      'Manuelt vurdert 2026-08-31: strøm-/energileverandør med nye-kunde-vilkår holdes utenfor MVP og publiseres ikke automatisk som butikkopptjening.'
    when 'SAS EuroBonus Shopping: ELSKLING' then
      'Manuelt vurdert 2026-08-31: strømavtale-/energisammenligning med nye-kunde-vilkår holdes utenfor MVP og publiseres ikke automatisk som butikkopptjening.'
    else candidate.review_note
  end,
  updated_at = now()
where candidate.status = 'needs_review'
  and candidate.promoted_store_earning_rate_id is null
  and candidate.title in (
    'SAS EuroBonus Shopping: Bærum Energi',
    'SAS EuroBonus Shopping: ELSKLING'
  );

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('manual_review_2026-08-31'::text),
    true
  ),
  status = 'approved',
  reviewed_at = now(),
  review_note = 'Manuelt vurdert 2026-08-31: SAS-kilden beskriver en generell Philips-nettbutikk. Publiseres som egen butikk, separat fra Philips Hue og Philips Home Appliances.',
  updated_at = now()
from public.campaign_categories category
where category.slug = 'elektronikk'
  and candidate.status = 'needs_review'
  and candidate.promoted_store_earning_rate_id is null
  and candidate.title = 'SAS EuroBonus Shopping: Philips';

create temporary table tmp_promoted_philips_store_earning_rate on commit drop as
select
  candidate.id as candidate_id,
  public.promote_ingestion_candidate_to_store_earning(
    candidate.id,
    'Philips',
    null,
    null,
    'Batch-publisert butikkopptjening 2026-08-31 etter manuell identitetsavklaring.'
  ) as rate_id
from public.ingestion_candidates candidate
where candidate.status = 'approved'
  and candidate.promoted_store_earning_rate_id is null
  and candidate.title = 'SAS EuroBonus Shopping: Philips';

update public.store_earning_rates rate
set
  status = 'published',
  warning_text = null,
  checked_at = now(),
  updated_at = now()
from tmp_promoted_philips_store_earning_rate promoted
where rate.id = promoted.rate_id;

update public.stores store
set
  status = 'published',
  last_verified_at = now(),
  updated_at = now()
from tmp_promoted_philips_store_earning_rate promoted
join public.store_earning_rates rate on rate.id = promoted.rate_id
where store.id = rate.store_id;

create temporary table tmp_inserted_philips_combination on commit drop as
with inserted as (
  insert into public.earning_combinations (
    store_id,
    status,
    title,
    total_value_label,
    summary,
    primary_handoff_url,
    last_verified_at,
    sort_order
  )
  select
    rate.store_id,
    'published',
    'EuroBonus Online Shopping',
    rate.rate_label,
    'Åpne Philips via SAS EuroBonus Online Shopping før kjøpet. Da bruker du den publiserte satsen vi har kontrollert for denne butikken.',
    rate.handoff_url,
    now(),
    0
  from tmp_promoted_philips_store_earning_rate promoted
  join public.store_earning_rates rate on rate.id = promoted.rate_id
  returning id, store_id
)
select * from inserted;

insert into public.earning_combination_rates (
  combination_id,
  store_earning_rate_id,
  sort_order
)
select
  combination.id,
  promoted.rate_id,
  0
from tmp_inserted_philips_combination combination
join tmp_promoted_philips_store_earning_rate promoted on true
join public.store_earning_rates rate
  on rate.id = promoted.rate_id
  and rate.store_id = combination.store_id
on conflict do nothing;

commit;
