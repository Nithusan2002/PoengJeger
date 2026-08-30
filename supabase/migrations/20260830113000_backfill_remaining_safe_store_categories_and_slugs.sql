with category_updates(title_pattern, category_slug) as (
  values
    ('%Kinoklubb%', 'boker-medier'),
    ('%iPhonehuset%', 'elektronikk'),
    ('%Interflora%', 'hus-hjem'),
    ('%Herschel Supply%', 'klaer-sko'),
    ('%Euroflorist%', 'hus-hjem'),
    ('%Brilleland%', 'helse-skjonnhet'),
    ('%SharkNinja%', 'hus-hjem'),
    ('%North Trampoline%', 'sport-fritid'),
    ('%weloveholidays%', 'reise'),
    ('%Slikkepott%', 'hus-hjem'),
    ('%Småungene%', 'barn-familie'),
    ('%Superkul%', 'barn-familie'),
    ('%Tiger of Sweden%', 'klaer-sko'),
    ('%Wakakuu%', 'klaer-sko'),
    ('%Parfym%', 'helse-skjonnhet'),
    ('%Skeidar%', 'hus-hjem'),
    ('%Vistaprint%', 'boker-medier'),
    ('%Prime Video%', 'boker-medier'),
    ('%Tirendo%', 'bil-motor'),
    ('%Pilgrim%', 'klaer-sko'),
    ('%Safira%', 'klaer-sko'),
    ('%Sofas and More%', 'hus-hjem'),
    ('%Sembo%', 'reise'),
    ('%Vakre Vene%', 'klaer-sko'),
    ('%P.Lindberg%', 'hus-hjem'),
    ('%Vivara%', 'dyr-kjaeledyr'),
    ('%ONYX Cookware%', 'hus-hjem'),
    ('%Watery%', 'sport-fritid'),
    ('%ZOO%', 'dyr-kjaeledyr'),
    ('%Weekday%', 'klaer-sko'),
    ('%Sephora%', 'helse-skjonnhet'),
    ('%Amisol%', 'reise'),
    ('%Urban Pioneers Concept Store%', 'klaer-sko'),
    ('%Urban Pioneers%', 'klaer-sko'),
    ('%Philips Hue%', 'elektronikk'),
    ('%SkyShowtime%', 'boker-medier'),
    ('%TripX%', 'reise'),
    ('%Trip%', 'reise'),
    ('%Hulténs%', 'hus-hjem'),
    ('%Puma%', 'klaer-sko'),
    ('%Nordic Nest%', 'hus-hjem'),
    ('%Strikkia%', 'sport-fritid'),
    ('%SACKit%', 'elektronikk'),
    ('%SmartaSaker%', 'hus-hjem'),
    ('%Racketspesialisten%', 'sport-fritid'),
    ('%Viking Footwear%', 'klaer-sko'),
    ('%CS MEGASTORE%', 'elektronikk'),
    ('%Viator%', 'reise'),
    ('%Stormberg%', 'sport-fritid'),
    ('%Omio%', 'reise'),
    ('%VPG%', 'sport-fritid'),
    ('%Tilbords%', 'hus-hjem'),
    ('%Staypro%', 'hus-hjem'),
    ('%SillySanta%', 'klaer-sko'),
    ('%Xplora%', 'elektronikk'),
    ('%Nytelse%', 'helse-skjonnhet'),
    ('%Urverket%', 'klaer-sko'),
    ('%Oakley%', 'klaer-sko'),
    ('%Superdry%', 'klaer-sko'),
    ('%Qatar Airways%', 'reise'),
    ('%Timarco%', 'klaer-sko'),
    ('%NordicFeel%', 'helse-skjonnhet'),
    ('%Vita%', 'helse-skjonnhet'),
    ('%Skruvat%', 'bil-motor')
)
update public.ingestion_candidates candidate
set
  suggested_category_id = category.id,
  metadata = jsonb_set(
    jsonb_set(candidate.metadata, '{suggested_category_slug}', to_jsonb(category.slug), true),
    '{suggested_category_source}',
    to_jsonb('keyword'::text),
    true
  ),
  updated_at = now()
from public.source_registry registry
join category_updates update_rule on true
join public.campaign_categories category on category.slug = update_rule.category_slug
where candidate.source_registry_id = registry.id
  and registry.parser_key in ('sas_eurobonus_shopping', 'trumf_netthandel')
  and candidate.status = 'new'
  and candidate.title ilike update_rule.title_pattern;

with slug_updates(title_pattern, shop_slug) as (
  values
    ('%Parfym%', 'parfymno'),
    ('%Philips Hue%', 'philips-hue'),
    ('%SkyShowtime%', 'sky-showtime'),
    ('%Sofas and More%', 'sofas-more'),
    ('%Tilbords%', 'tilbords-1'),
    ('%Urverket%', 'urverket-no'),
    ('%Vita%', 'vita-no'),
    ('%VPG%', 'vpg-no'),
    ('%ZOO%', 'zoo-se-1'),
    ('%CS MEGASTORE%', 'computersalg'),
    ('%Racketspesialisten%', 'racketspecialisten')
)
update public.ingestion_candidates candidate
set
  metadata = jsonb_set(candidate.metadata, '{shop_slug}', to_jsonb(update_rule.shop_slug), true),
  updated_at = now()
from public.source_registry registry
join slug_updates update_rule on true
where candidate.source_registry_id = registry.id
  and registry.parser_key = 'trumf_netthandel'
  and candidate.status = 'new'
  and candidate.title ilike update_rule.title_pattern;
