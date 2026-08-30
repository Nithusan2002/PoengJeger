begin;

with candidates as (
  select
    ic.id,
    trim(
      both '-'
      from regexp_replace(
        translate(
          lower(
            regexp_replace(
              regexp_replace(
                regexp_replace(
                  regexp_replace(ic.title, '^Trumf:\s*', '', 'i'),
                  '\.(no|com|se|dk|fi|net|org)(\s|$)',
                  ' ',
                  'gi'
                ),
                '(^|\s)(no|norge|norway)(\s|$)',
                ' ',
                'gi'
              ),
              '[^[:alnum:]æøåäöüéèê]+',
              ' ',
              'g'
            )
          ),
          'æøåäöüéèê',
          'aoaaoueee'
        ),
        '[^a-z0-9]+',
        '-',
        'g'
      )
    ) as clean_shop_slug
  from public.ingestion_candidates ic
  join public.source_registry sr on sr.id = ic.source_registry_id
  where sr.parser_key = 'trumf_netthandel'
)
update public.ingestion_candidates ic
set
  metadata = jsonb_set(
    ic.metadata,
    '{shop_slug}',
    to_jsonb(c.clean_shop_slug),
    true
  ),
  updated_at = now()
from candidates c
where ic.id = c.id
  and c.clean_shop_slug <> ''
  and coalesce(ic.metadata->>'shop_slug', '') is distinct from c.clean_shop_slug;

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
    title ilike '%AEG%'
    or title ilike '%Christiania Glasmagasin%'
    or title ilike '%Jotex%'
  );

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
  and title ilike '%Treningspartner%';

commit;
