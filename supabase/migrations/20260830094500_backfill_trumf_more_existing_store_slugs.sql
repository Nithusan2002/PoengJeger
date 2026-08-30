begin;

update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('e-wheels-2'::text), true),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%E-Wheels%';

update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('disney-1'::text), true),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Disney+%';

update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('jbl-com'::text), true),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%JBL%';

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
from public.source_registry source
cross join public.campaign_categories category
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and category.slug = 'sport-fritid'
  and candidate.status = 'new'
  and candidate.title ilike '%Sportsmagasinet%';

commit;
