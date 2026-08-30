begin;

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'subscription'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%Storytel%';

commit;
