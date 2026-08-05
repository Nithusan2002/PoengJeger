create or replace function public.set_ingestion_candidate_status(
  p_candidate_id uuid,
  p_status text,
  p_review_note text default null
)
returns public.ingestion_candidates
language plpgsql
security invoker
set search_path = public
as $$
declare
  updated_candidate public.ingestion_candidates;
begin
  if not (
    public.is_admin()
    or current_user in ('postgres', 'service_role', 'supabase_admin')
  ) then
    raise exception 'Only admins can review ingestion candidates';
  end if;

  if p_status not in ('needs_review', 'approved', 'rejected') then
    raise exception 'Unsupported candidate review status: %', p_status;
  end if;

  update public.ingestion_candidates
  set
    status = p_status,
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_note = p_review_note
  where id = p_candidate_id
  returning * into updated_candidate;

  if updated_candidate.id is null then
    raise exception 'Ingestion candidate % not found', p_candidate_id;
  end if;

  return updated_candidate;
end;
$$;

create or replace function public.promote_ingestion_candidate_to_campaign(
  p_candidate_id uuid,
  p_primary_program_id uuid default null,
  p_category_id uuid default null,
  p_title text default null,
  p_summary text default null,
  p_details text default null,
  p_review_note text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  candidate_record record;
  new_campaign_id uuid;
  resolved_title text;
  resolved_summary text;
  resolved_details text;
  resolved_program_id uuid;
  resolved_category_id uuid;
begin
  if not (
    public.is_admin()
    or current_user in ('postgres', 'service_role', 'supabase_admin')
  ) then
    raise exception 'Only admins can promote ingestion candidates';
  end if;

  select
    ic.*,
    sr.campaign_source_id
  into candidate_record
  from public.ingestion_candidates ic
  join public.source_registry sr on sr.id = ic.source_registry_id
  where ic.id = p_candidate_id;

  if candidate_record.id is null then
    raise exception 'Ingestion candidate % not found', p_candidate_id;
  end if;

  if candidate_record.promoted_campaign_id is not null then
    raise exception 'Ingestion candidate % is already promoted to campaign %',
      p_candidate_id,
      candidate_record.promoted_campaign_id;
  end if;

  if candidate_record.status not in ('new', 'needs_review', 'approved') then
    raise exception 'Ingestion candidate % cannot be promoted from status %',
      p_candidate_id,
      candidate_record.status;
  end if;

  resolved_title := coalesce(nullif(trim(p_title), ''), candidate_record.title);
  resolved_summary := coalesce(
    nullif(trim(p_summary), ''),
    nullif(trim(candidate_record.summary), ''),
    resolved_title
  );
  resolved_details := coalesce(
    nullif(trim(p_details), ''),
    nullif(trim(candidate_record.raw_content), ''),
    resolved_summary
  );
  resolved_program_id := coalesce(p_primary_program_id, candidate_record.suggested_program_id);
  resolved_category_id := coalesce(p_category_id, candidate_record.suggested_category_id);

  insert into public.campaigns (
    title,
    summary,
    details,
    status,
    primary_program_id,
    category_id,
    editorial_summary,
    created_by,
    updated_by
  )
  values (
    resolved_title,
    resolved_summary,
    resolved_details,
    'draft',
    resolved_program_id,
    resolved_category_id,
    candidate_record.summary,
    auth.uid(),
    auth.uid()
  )
  returning id into new_campaign_id;

  if resolved_program_id is not null then
    insert into public.campaign_programs (campaign_id, program_id)
    values (new_campaign_id, resolved_program_id)
    on conflict do nothing;
  end if;

  insert into public.campaign_source_references (
    campaign_id,
    source_id,
    url,
    title,
    checked_at,
    evidence_note
  )
  values (
    new_campaign_id,
    candidate_record.campaign_source_id,
    candidate_record.source_url,
    resolved_title,
    now(),
    format('Imported from ingestion candidate %s', candidate_record.id)
  );

  update public.ingestion_candidates
  set
    status = 'promoted',
    reviewed_by = auth.uid(),
    reviewed_at = now(),
    review_note = coalesce(
      nullif(trim(p_review_note), ''),
      format('Promoted to draft campaign %s', new_campaign_id)
    ),
    promoted_campaign_id = new_campaign_id
  where id = p_candidate_id;

  return new_campaign_id;
end;
$$;
