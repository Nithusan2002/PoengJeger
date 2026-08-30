update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'hus-hjem'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Fortum Strøm%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'reise'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and (
    candidate.title ilike '%Football Travel%'
    or candidate.title ilike '%Fjordline%'
  );

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'barn-familie'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Festkompaniet%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'elektronikk'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Farnell%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'subscription'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Fabel%';
