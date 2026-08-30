begin;

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'hus-hjem'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%Trendcarpet%';

update public.ingestion_candidates ic
set
  summary = regexp_replace(ic.summary, '([0-9])\\s*kr\\M', '\\1 kr', 'gi'),
  updated_at = now()
from public.source_registry sr
where sr.id = ic.source_registry_id
  and sr.parser_key = 'trumf_netthandel'
  and ic.status in ('new', 'needs_review', 'approved')
  and ic.summary ~* '[0-9]\\s*kr\\M';

commit;
