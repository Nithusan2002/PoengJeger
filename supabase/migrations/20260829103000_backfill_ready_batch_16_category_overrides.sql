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
  and candidate.title ilike '%Bosch Home%';

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
  and candidate.title ilike '%Bookbeat%';

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
where category.slug = 'boker-medier'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Bokia%';

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
where category.slug = 'helse-skjonnhet'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Bodystore%';
