update public.ingestion_candidates as candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb('kinoklubben'::text), true),
  updated_at = now()
from public.source_registry as registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'sas_eurobonus_shopping'
  and candidate.status = 'new'
  and candidate.title = 'SAS EuroBonus Shopping: Kinoklubb';
