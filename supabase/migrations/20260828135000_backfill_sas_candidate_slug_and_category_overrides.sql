begin;

update public.ingestion_candidates
set
  metadata = jsonb_set(metadata, '{shop_slug}', to_jsonb('under-armour'::text), true),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and title ilike '%Under Armour%';

update public.ingestion_candidates
set
  suggested_category_id = (select id from public.campaign_categories where slug = 'klaer-sko'),
  metadata = jsonb_set(
    metadata,
    '{suggested_category_source}',
    to_jsonb('editorial_override'::text),
    true
  ),
  updated_at = now()
where status in ('new', 'needs_review', 'approved')
  and (
    title ilike '%SWIMS%'
    or title ilike '%Suitable%'
    or title ilike '%Under Armour%'
  );

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
  and title ilike '%Telia%';

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
  and title ilike '%Strim%';

commit;
