drop view if exists public.admin_ingestion_candidate_queue;

create view public.admin_ingestion_candidate_queue
with (security_invoker = true)
as
with candidate_context as (
  select
    ic.id,
    ic.status,
    ic.detected_at,
    ic.source_url,
    ic.title,
    ic.summary,
    ic.reviewed_at,
    ic.review_note,
    ic.promoted_campaign_id,
    ic.promoted_store_earning_rate_id,
    ic.metadata,
    sr.id as source_registry_id,
    sr.ingest_kind,
    sr.parser_key,
    cs.id as campaign_source_id,
    cs.name as source_name,
    bp.id as suggested_program_id,
    bp.name as suggested_program_name,
    cc.id as suggested_category_id,
    cc.slug as suggested_category_slug,
    cc.name as suggested_category_name,
    nullif(trim(ic.metadata ->> 'shop_slug'), '') as shop_slug,
    coalesce((ic.metadata ->> 'missing_bonus_value')::boolean, false) as missing_bonus_value,
    nullif(trim(ic.metadata ->> 'suggested_category_source'), '') as suggested_category_source
  from public.ingestion_candidates ic
  join public.source_registry sr on sr.id = ic.source_registry_id
  join public.campaign_sources cs on cs.id = sr.campaign_source_id
  left join public.bonus_programs bp on bp.id = ic.suggested_program_id
  left join public.campaign_categories cc on cc.id = ic.suggested_category_id
),
store_context as (
  select
    c.*,
    c.parser_key in ('trumf_netthandel', 'sas_eurobonus_shopping') as is_store_earning_candidate,
    case c.parser_key
      when 'sas_eurobonus_shopping' then 'sas-eurobonus-online-shopping'
      when 'trumf_netthandel' then 'trumf'
      else null
    end as suggested_method_slug,
    s.id as matched_store_id,
    s.name as matched_store_name,
    s.status as matched_store_status
  from candidate_context c
  left join public.stores s on s.slug = c.shop_slug
),
review_context as (
  select
    sc.*,
    sc.matched_store_id is not null as matches_existing_store,
    exists (
      select 1
      from public.store_earning_rates ser
      join public.earning_methods em on em.id = ser.earning_method_id
      where ser.store_id = sc.matched_store_id
        and em.slug = sc.suggested_method_slug
        and ser.status in ('draft', 'published')
    ) as has_existing_store_method_rate,
    (
      sc.suggested_category_id is null
      or sc.suggested_category_slug is null
      or sc.suggested_category_slug = 'annet'
      or coalesce(sc.suggested_category_source = 'default', false)
    ) as needs_category_review
  from store_context sc
)
select
  rc.id,
  rc.status,
  rc.detected_at,
  rc.source_url,
  rc.title,
  rc.summary,
  rc.reviewed_at,
  rc.review_note,
  rc.promoted_campaign_id,
  rc.promoted_store_earning_rate_id,
  rc.source_registry_id,
  rc.ingest_kind,
  rc.campaign_source_id,
  rc.source_name,
  rc.suggested_program_id,
  rc.suggested_program_name,
  rc.suggested_category_id,
  rc.suggested_category_slug,
  rc.suggested_category_name,
  rc.parser_key,
  rc.shop_slug,
  rc.missing_bonus_value,
  rc.suggested_category_source,
  rc.is_store_earning_candidate,
  rc.suggested_method_slug,
  rc.matched_store_id,
  rc.matched_store_name,
  rc.matched_store_status,
  rc.matches_existing_store,
  rc.has_existing_store_method_rate,
  rc.needs_category_review,
  (
    rc.is_store_earning_candidate
    and rc.status in ('new', 'needs_review', 'approved')
    and rc.promoted_campaign_id is null
    and rc.promoted_store_earning_rate_id is null
    and rc.shop_slug is not null
    and not rc.missing_bonus_value
    and not rc.needs_category_review
    and not rc.has_existing_store_method_rate
  ) as is_ready_for_store_earning,
  case
    when rc.promoted_campaign_id is not null or rc.promoted_store_earning_rate_id is not null
      then 'Promotert'
    when rc.missing_bonus_value
      then 'Mangler verdi'
    when rc.needs_category_review
      then 'Kategori usikker'
    when rc.has_existing_store_method_rate
      then 'Mulig duplikat'
    when rc.matches_existing_store
      then 'Matcher butikk'
    when rc.is_store_earning_candidate and rc.shop_slug is not null
      then 'Klar til draft'
    else 'Trenger review'
  end as review_signal_label
from review_context rc;
