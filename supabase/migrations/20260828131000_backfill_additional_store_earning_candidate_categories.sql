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
  and (
    title ilike '%VidaXL%'
    or title ilike '%Vida XL%'
  );

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'dyr-kjaeledyr'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and (
    title ilike '%VetZoo%'
    or title ilike '%ZOO.no%'
  );

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'reise'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%Vy Buss%';

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
  and (
    title ilike '%Trøndermobil%'
    or title ilike '%Trondermobil%'
  );

commit;
