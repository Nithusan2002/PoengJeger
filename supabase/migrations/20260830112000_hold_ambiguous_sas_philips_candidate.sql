update public.ingestion_candidates candidate
set
  status = 'needs_review',
  reviewed_at = now(),
  review_note = concat_ws(
    E'\n',
    nullif(candidate.review_note, ''),
    'Holdt tilbake fra batchpublisering 2026-08-30: SAS-kandidaten "Philips" er tvetydig mot eksisterende butikker Philips Home Appliances og Philips Hue.'
  ),
  updated_at = now()
from public.source_registry registry
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'sas_eurobonus_shopping'
  and candidate.status = 'new'
  and candidate.title = 'SAS EuroBonus Shopping: Philips';
