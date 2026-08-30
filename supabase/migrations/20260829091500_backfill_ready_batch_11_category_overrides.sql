update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(
      candidate.metadata,
      '{suggested_category_slug}',
      to_jsonb(category.slug),
      true
    ),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'dyr-kjaeledyr'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%I love dogs%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(
      candidate.metadata,
      '{suggested_category_slug}',
      to_jsonb(category.slug),
      true
    ),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'telecom'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%ICE%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(
      candidate.metadata,
      '{suggested_category_slug}',
      to_jsonb(category.slug),
      true
    ),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  )
from public.campaign_categories category
where category.slug = 'hus-hjem'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.title ilike '%Homeroom%';
