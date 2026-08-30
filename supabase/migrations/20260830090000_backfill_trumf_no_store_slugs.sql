begin;

update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('badno'::text), true),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Bad.no%';

update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('fotono'::text), true),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Foto.no%';

commit;
