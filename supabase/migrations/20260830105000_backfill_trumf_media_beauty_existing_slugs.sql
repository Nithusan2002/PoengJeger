update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('inkmann-2'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Inkmann%';

update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('lyko-dk'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%LYKO%';

update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('storytel-no'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Storytel%';
