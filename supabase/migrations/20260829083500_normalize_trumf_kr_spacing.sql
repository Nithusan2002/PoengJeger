begin;

update public.ingestion_candidates candidate
set
  summary = regexp_replace(candidate.summary, '([0-9])\s*kr\b', '\1 kr', 'gi'),
  updated_at = now()
from public.source_registry source
where source.id = candidate.source_registry_id
  and source.parser_key = 'trumf_netthandel'
  and candidate.status in ('new', 'needs_review', 'approved')
  and candidate.summary ~* '[0-9]\s*kr\b';

commit;
