with category_updates(title_pattern, category_slug) as (
  values
    ('%Watery%', 'sport-fritid'),
    ('%VOLT%', 'klaer-sko'),
    ('%Vinlagringskompaniet%', 'hus-hjem'),
    ('%Vakre Vene%', 'klaer-sko'),
    ('%Urverket%', 'klaer-sko'),
    ('%Urban Trend%', 'klaer-sko'),
    ('%Understatement%', 'klaer-sko'),
    ('%TT-line%', 'reise'),
    ('%Trapessko%', 'klaer-sko'),
    ('%StockX%', 'klaer-sko'),
    ('%Soma%', 'helse-skjonnhet'),
    ('%SmartBuyGlasses%', 'klaer-sko'),
    ('%Sistie%', 'klaer-sko'),
    ('%Senze of Joy%', 'helse-skjonnhet'),
    ('%Sail Racing%', 'sport-fritid'),
    ('%Safira%', 'klaer-sko'),
    ('%RITO%', 'sport-fritid'),
    ('%Ray-Ban%', 'klaer-sko'),
    ('%Pilgrim%', 'klaer-sko'),
    ('%Philips%', 'elektronikk'),
    ('%partyking%', 'barn-familie'),
    ('%Nespresso%', 'dagligvare'),
    ('%Maxulin%', 'helse-skjonnhet'),
    ('%Marshall%', 'elektronikk'),
    ('%LYR Design%', 'klaer-sko'),
    ('%Lux-case%', 'elektronikk'),
    ('%Liffner%', 'klaer-sko'),
    ('%Länna Møbler%', 'hus-hjem')
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
  and registry.parser_key = 'sas_eurobonus_shopping'
  and candidate.status = 'new'
  and candidate.title ilike update_rule.title_pattern;
