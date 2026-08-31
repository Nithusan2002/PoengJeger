begin;

insert into public.campaign_categories (slug, name)
values ('gaver-opplevelser', 'Gaver og opplevelser')
on conflict (slug) do update
set
  name = excluded.name,
  updated_at = now();

create temporary table tmp_reviewed_store_earning_candidates (
  title text primary key,
  category_slug text not null
) on commit drop;

insert into tmp_reviewed_store_earning_candidates (title, category_slug)
values
  ('SAS EuroBonus Shopping: Calstop', 'helse-skjonnhet'),
  ('SAS EuroBonus Shopping: Detailshop', 'bil-motor'),
  ('SAS EuroBonus Shopping: Truestory', 'gaver-opplevelser'),
  ('SAS EuroBonus Shopping: YouWish', 'gaver-opplevelser'),
  ('Trumf: Backe i Grensen', 'hus-hjem'),
  ('Trumf: Beredd', 'sport-fritid'),
  ('Trumf: Comforth Scandinavia', 'helse-skjonnhet'),
  ('Trumf: Engrospris', 'hus-hjem'),
  ('Trumf: Karma', 'helse-skjonnhet'),
  ('Trumf: Stille', 'hus-hjem'),
  ('Trumf: Tønnesen', 'klaer-sko'),
  ('Trumf: YourSurprise', 'gaver-opplevelser'),
  ('Trumf: YouWish', 'gaver-opplevelser');

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('manual_review_2026-08-30'::text),
    true
  ),
  status = 'approved',
  reviewed_at = now(),
  review_note = 'Manuelt vurdert 2026-08-30: kategorien er avklart mot kildebeskrivelse/offisiell butikkside og kandidaten kan promoteres til butikkopptjening.',
  updated_at = now()
from tmp_reviewed_store_earning_candidates reviewed
join public.campaign_categories category on category.slug = reviewed.category_slug
where candidate.title = reviewed.title
  and candidate.status = 'needs_review'
  and candidate.promoted_store_earning_rate_id is null;

create temporary table tmp_promoted_store_earning_rates on commit drop as
select
  candidate.id as candidate_id,
  registry.parser_key,
  public.promote_ingestion_candidate_to_store_earning(
    candidate.id,
    null,
    null,
    null,
    'Batch-publisert butikkopptjening 2026-08-30 (reviewed restekandidater)'
  ) as rate_id
from public.ingestion_candidates candidate
join public.source_registry registry on registry.id = candidate.source_registry_id
join tmp_reviewed_store_earning_candidates reviewed on reviewed.title = candidate.title
where candidate.status = 'approved'
  and candidate.promoted_store_earning_rate_id is null;

update public.store_earning_rates rate
set
  status = 'published',
  warning_text = null,
  checked_at = now(),
  updated_at = now()
from tmp_promoted_store_earning_rates promoted
where rate.id = promoted.rate_id;

update public.stores store
set
  status = 'published',
  last_verified_at = now(),
  updated_at = now()
from tmp_promoted_store_earning_rates promoted
join public.store_earning_rates rate on rate.id = promoted.rate_id
where store.id = rate.store_id;

create temporary table tmp_inserted_combinations on commit drop as
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
    case promoted.parser_key
      when 'sas_eurobonus_shopping' then 'EuroBonus Online Shopping'
      when 'trumf_netthandel' then 'Trumf Netthandel'
      else 'Butikkopptjening'
    end,
    rate.rate_label,
    case promoted.parser_key
      when 'sas_eurobonus_shopping'
        then 'Åpne ' || store.name || ' via SAS EuroBonus Online Shopping før kjøpet. Da bruker du den publiserte satsen vi har kontrollert for denne butikken.'
      when 'trumf_netthandel'
        then 'Åpne ' || store.name || ' via Trumf Netthandel før kjøpet. Da bruker du den publiserte Trumf-satsen vi har kontrollert for denne butikken.'
      else 'Bruk den dokumenterte opptjeningsmetoden før kjøpet.'
    end,
    rate.handoff_url,
    now(),
    0
  from tmp_promoted_store_earning_rates promoted
  join public.store_earning_rates rate on rate.id = promoted.rate_id
  join public.stores store on store.id = rate.store_id
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
from tmp_inserted_combinations combination
join tmp_promoted_store_earning_rates promoted on true
join public.store_earning_rates rate
  on rate.id = promoted.rate_id
  and rate.store_id = combination.store_id
on conflict do nothing;

select count(*) as promoted_count
from tmp_promoted_store_earning_rates;

commit;
