update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  ),
  updated_at = now()
from public.campaign_categories category
where category.slug = 'helse-skjonnhet'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' = 'trumf_netthandel'
  and candidate.title ilike '%Oslo Skin Lab%';

update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  ),
  updated_at = now()
from public.campaign_categories category
where category.slug = 'sport-fritid'
  and candidate.status = 'new'
  and candidate.metadata ->> 'parser_key' = 'trumf_netthandel'
  and candidate.title = 'Trumf: Db';
