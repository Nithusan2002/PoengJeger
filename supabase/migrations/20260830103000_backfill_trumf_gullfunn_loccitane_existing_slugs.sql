update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('gullfunn-1'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Gullfunn%';

update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('loccitane'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Occitane%';
