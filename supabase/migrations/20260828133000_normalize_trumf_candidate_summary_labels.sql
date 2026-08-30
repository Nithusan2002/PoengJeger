begin;

update public.ingestion_candidates ic
set
  summary = trim(ic.summary) || ' Trumf-bonus',
  updated_at = now()
from public.source_registry sr
where sr.id = ic.source_registry_id
  and sr.parser_key = 'trumf_netthandel'
  and ic.status in ('new', 'needs_review', 'approved')
  and nullif(trim(ic.summary), '') is not null
  and ic.summary !~* '\mtrumf\M';

commit;
