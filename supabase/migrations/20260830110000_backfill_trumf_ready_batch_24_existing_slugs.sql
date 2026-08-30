update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('vida-xl-se'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%VidaXL%';

update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('barbershop-no'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Barbershop%';

update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('polarnopyret'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike '%Polarn O. Pyret%';
