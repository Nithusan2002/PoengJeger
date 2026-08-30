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
  and title ilike '%Proteinfabrikken%';

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'telecom'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%PlussMobil%';

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'barn-familie'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and (
    title ilike '%Polarn O. Pyret%'
    or title ilike '%PatPat%'
  );

commit;
