create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(public.current_editorial_role() in ('admin', 'editor'), false);
$$;

revoke execute on function public.current_editorial_role() from public;
revoke execute on function public.current_editorial_role() from anon;
revoke execute on function public.current_editorial_role() from authenticated;

create or replace view public.admin_ingestion_candidate_queue
with (security_invoker = true)
as
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
  sr.id as source_registry_id,
  sr.ingest_kind,
  cs.id as campaign_source_id,
  cs.name as source_name,
  bp.id as suggested_program_id,
  bp.name as suggested_program_name,
  cc.id as suggested_category_id,
  cc.name as suggested_category_name
from public.ingestion_candidates ic
join public.source_registry sr on sr.id = ic.source_registry_id
join public.campaign_sources cs on cs.id = sr.campaign_source_id
left join public.bonus_programs bp on bp.id = ic.suggested_program_id
left join public.campaign_categories cc on cc.id = ic.suggested_category_id;
