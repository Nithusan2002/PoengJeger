-- Pilotkontroll for publisert butikkopptjening.
-- Kjor etter migrasjonene er brukt i Supabase.

select
  store_name,
  store_slug,
  entity_type,
  entity_id,
  issue_codes
from public.store_earning_publication_quality_issues
order by store_name, entity_type, entity_id;

select
  store.name as store_name,
  category.name as category_name,
  method.name as method_name,
  rate.rate_label,
  rate.requirement_summary,
  rate.warning_text,
  rate.source_title,
  rate.source_url,
  rate.checked_at,
  rate.ends_at,
  combo.total_value_label as recommended_value,
  combo.summary as recommendation_summary,
  combo.last_verified_at as recommendation_checked_at
from public.stores store
left join public.campaign_categories category on category.id = store.category_id
left join public.store_earning_rates rate
  on rate.store_id = store.id
  and rate.status = 'published'
left join public.earning_methods method on method.id = rate.earning_method_id
left join public.earning_combination_rates combo_rate on combo_rate.store_earning_rate_id = rate.id
left join public.earning_combinations combo
  on combo.id = combo_rate.combination_id
  and combo.status = 'published'
where store.status = 'published'
order by
  case category.slug
    when 'dagligvare' then 1
    when 'reise' then 2
    when 'elektronikk' then 3
    when 'shopping' then 4
    else 9
  end,
  store.name,
  rate.sort_order;
