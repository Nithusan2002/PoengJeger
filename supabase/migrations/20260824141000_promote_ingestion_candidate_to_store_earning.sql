alter table public.ingestion_candidates
add column if not exists promoted_store_earning_rate_id uuid
references public.store_earning_rates (id) on delete set null;

create index if not exists ingestion_candidates_promoted_store_earning_rate_idx
  on public.ingestion_candidates (promoted_store_earning_rate_id)
  where promoted_store_earning_rate_id is not null;

alter table public.ingestion_candidates
drop constraint if exists ingestion_candidates_review_state;

alter table public.ingestion_candidates
add constraint ingestion_candidates_review_state check (
  (status = 'new' and reviewed_at is null and promoted_campaign_id is null and promoted_store_earning_rate_id is null)
  or (status in ('needs_review', 'approved', 'rejected') and reviewed_at is not null and promoted_campaign_id is null and promoted_store_earning_rate_id is null)
  or (
    status = 'promoted'
    and reviewed_at is not null
    and (
      promoted_campaign_id is not null
      or promoted_store_earning_rate_id is not null
    )
  )
);

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
  ic.promoted_store_earning_rate_id,
  sr.id as source_registry_id,
  sr.ingest_kind,
  sr.parser_key,
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

create or replace function public.promote_ingestion_candidate_to_store_earning(
  p_candidate_id uuid,
  p_store_name text default null,
  p_category_id uuid default null,
  p_rate_label text default null,
  p_review_note text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  candidate_record record;
  resolved_store_id uuid;
  resolved_rate_id uuid;
  resolved_store_name text;
  resolved_store_slug text;
  resolved_rate_label text;
  resolved_method_slug text;
  resolved_method_id uuid;
  resolved_category_id uuid;
  resolved_handoff_url text;
  resolved_source_title text;
  resolved_requirement_summary text;
  slug_seed text;
begin
  if not (
    public.is_admin()
    or current_user in ('postgres', 'service_role', 'supabase_admin')
  ) then
    raise exception 'Only admins can promote ingestion candidates to store earning rates';
  end if;

  select
    ic.*,
    sr.parser_key,
    sr.campaign_source_id,
    cs.name as source_name
  into candidate_record
  from public.ingestion_candidates ic
  join public.source_registry sr on sr.id = ic.source_registry_id
  join public.campaign_sources cs on cs.id = sr.campaign_source_id
  where ic.id = p_candidate_id;

  if candidate_record.id is null then
    raise exception 'Ingestion candidate % not found', p_candidate_id;
  end if;

  if candidate_record.promoted_campaign_id is not null then
    raise exception 'Ingestion candidate % is already promoted to campaign %',
      p_candidate_id,
      candidate_record.promoted_campaign_id;
  end if;

  if candidate_record.promoted_store_earning_rate_id is not null then
    raise exception 'Ingestion candidate % is already promoted to store earning rate %',
      p_candidate_id,
      candidate_record.promoted_store_earning_rate_id;
  end if;

  if candidate_record.status not in ('new', 'needs_review', 'approved') then
    raise exception 'Ingestion candidate % cannot be promoted from status %',
      p_candidate_id,
      candidate_record.status;
  end if;

  resolved_method_slug := case candidate_record.parser_key
    when 'sas_eurobonus_shopping' then 'sas-eurobonus-online-shopping'
    when 'trumf_netthandel' then 'trumf'
    else null
  end;

  if resolved_method_slug is null then
    raise exception 'Ingestion candidate % uses unsupported store earning parser %',
      p_candidate_id,
      candidate_record.parser_key;
  end if;

  select id into resolved_method_id
  from public.earning_methods
  where slug = resolved_method_slug;

  if resolved_method_id is null then
    raise exception 'Earning method % is missing', resolved_method_slug;
  end if;

  resolved_store_name := coalesce(
    nullif(trim(p_store_name), ''),
    nullif(
      trim(
        regexp_replace(
          candidate_record.title,
          '^(SAS EuroBonus Shopping|SAS EuroBonus|Trumf):\s*',
          '',
          'i'
        )
      ),
      ''
    )
  );

  if resolved_store_name is null then
    raise exception 'Store name is missing for ingestion candidate %', p_candidate_id;
  end if;

  slug_seed := coalesce(
    nullif(trim(candidate_record.metadata->>'shop_slug'), ''),
    nullif(trim(regexp_replace(candidate_record.metadata->>'url_name', '-?trumf$', '', 'i')), ''),
    resolved_store_name
  );
  resolved_store_slug := trim(
    both '-'
    from regexp_replace(
      translate(lower(slug_seed), 'æøåäöüéèê', 'aoaaoueee'),
      '[^a-z0-9]+',
      '-',
      'g'
    )
  );

  if resolved_store_slug is null or resolved_store_slug = '' then
    raise exception 'Store slug is missing for ingestion candidate %', p_candidate_id;
  end if;

  resolved_rate_label := coalesce(
    nullif(trim(p_rate_label), ''),
    nullif(trim(candidate_record.summary), '')
  );

  if resolved_rate_label is null then
    raise exception 'Rate label is missing for ingestion candidate %', p_candidate_id;
  end if;

  resolved_category_id := coalesce(p_category_id, candidate_record.suggested_category_id);
  resolved_handoff_url := coalesce(
    nullif(trim(candidate_record.metadata->>'handoff_url'), ''),
    candidate_record.source_url
  );
  resolved_source_title := coalesce(
    nullif(trim(candidate_record.source_name), ''),
    'Ingestion candidate source'
  );
  resolved_requirement_summary := case candidate_record.parser_key
    when 'sas_eurobonus_shopping' then 'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores.'
    when 'trumf_netthandel' then 'Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.'
    else null
  end;

  insert into public.stores (
    slug,
    name,
    category_id,
    status,
    search_keywords,
    last_verified_at
  )
  values (
    resolved_store_slug,
    resolved_store_name,
    resolved_category_id,
    'draft',
    array[resolved_store_name, resolved_store_slug],
    now()
  )
  on conflict (slug) do update
  set
    name = excluded.name,
    category_id = coalesce(public.stores.category_id, excluded.category_id),
    search_keywords = (
      select array(
        select distinct keyword
        from unnest(public.stores.search_keywords || excluded.search_keywords) as keyword
        where nullif(trim(keyword), '') is not null
      )
    ),
    updated_at = now()
  returning id into resolved_store_id;

  insert into public.store_earning_rates (
    store_id,
    earning_method_id,
    status,
    rate_label,
    normal_rate_label,
    value_summary,
    requirement_summary,
    warning_text,
    handoff_url,
    source_url,
    source_title,
    checked_at,
    is_base_rate
  )
  values (
    resolved_store_id,
    resolved_method_id,
    'draft',
    resolved_rate_label,
    resolved_rate_label,
    candidate_record.summary,
    resolved_requirement_summary,
    'Må kontrolleres redaksjonelt før publisering.',
    resolved_handoff_url,
    candidate_record.source_url,
    resolved_source_title,
    now(),
    true
  )
  returning id into resolved_rate_id;

  update public.ingestion_candidates
  set
    status = 'promoted',
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_note = coalesce(
      nullif(trim(p_review_note), ''),
      format('Promoted to draft store earning rate %s', resolved_rate_id)
    ),
    promoted_store_earning_rate_id = resolved_rate_id
  where id = p_candidate_id;

  return resolved_rate_id;
end;
$$;

grant execute on function public.promote_ingestion_candidate_to_store_earning(uuid, text, uuid, text, text) to authenticated;
grant execute on function public.promote_ingestion_candidate_to_store_earning(uuid, text, uuid, text, text) to service_role;
