begin;

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'sport-fritid'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and (
    title ilike '%Skogstad Sport%'
    or title ilike '%Skistart%'
  );

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'elektronikk'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%Razer%';

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
  and title ilike '%Readly%';

commit;
