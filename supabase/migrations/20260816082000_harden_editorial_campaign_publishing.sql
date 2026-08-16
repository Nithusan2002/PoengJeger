create or replace function public.is_editorial_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_editorial_role() in ('admin', 'editor'), false);
$$;

create or replace function public.is_admin_role()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_editorial_role() = 'admin', false);
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_editorial_member();
$$;

grant execute on function public.is_editorial_member() to anon;
grant execute on function public.is_editorial_member() to authenticated;
grant execute on function public.is_editorial_member() to service_role;
grant execute on function public.is_admin_role() to anon;
grant execute on function public.is_admin_role() to authenticated;
grant execute on function public.is_admin_role() to service_role;

drop policy if exists "admins manage campaign sources" on public.campaign_sources;
drop policy if exists "editorial members read campaign sources" on public.campaign_sources;
create policy "editorial members read campaign sources"
on public.campaign_sources
for select
using (public.is_editorial_member());
create policy "admins manage campaign sources"
on public.campaign_sources
for all
using (public.is_admin_role())
with check (public.is_admin_role());

drop policy if exists "admins manage source registry" on public.source_registry;
drop policy if exists "editorial members read source registry" on public.source_registry;
create policy "editorial members read source registry"
on public.source_registry
for select
using (public.is_editorial_member());
create policy "admins manage source registry"
on public.source_registry
for all
using (public.is_admin_role())
with check (public.is_admin_role());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'campaign_source_references_https_url'
      and conrelid = 'public.campaign_source_references'::regclass
  ) then
    alter table public.campaign_source_references
      add constraint campaign_source_references_https_url
      check (url ~* '^https://[^[:space:]]+$') not valid;
  end if;
end $$;

alter table public.program_guides
  alter column strategy drop not null;

alter table public.program_guides
  drop constraint if exists program_guides_strategy_present;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'program_guides_published_strategy_present'
      and conrelid = 'public.program_guides'::regclass
  ) then
    alter table public.program_guides
      add constraint program_guides_published_strategy_present check (
        status <> 'published' or length(trim(coalesce(strategy, ''))) > 0
      );
  end if;
end $$;

create or replace function public.enforce_campaign_publish_requirements()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  source_reference_count integer;
  program_link_count integer;
begin
  if new.status = 'published' then
    if new.last_verified_at is null then
      raise exception 'Published campaigns must have last_verified_at set';
    end if;

    select count(*)
      into source_reference_count
    from public.campaign_source_references
    where campaign_id = new.id;

    if source_reference_count = 0 then
      raise exception 'Published campaigns must have at least one source reference';
    end if;

    select count(*)
      into program_link_count
    from public.campaign_programs
    where campaign_id = new.id;

    if program_link_count = 0 then
      raise exception 'Published campaigns must have at least one bonus program';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.save_editorial_campaign(
  p_campaign_id uuid,
  p_payload jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  resolved_status text;
  resolved_title text;
  resolved_summary text;
  resolved_details text;
  resolved_program_id uuid;
  resolved_category_id uuid;
  resolved_editorial_summary text;
  resolved_last_verified_at timestamptz;
  assessment_reason text;
  assessment_estimated_value text;
  assessment_difficulty text;
  assessment_availability text;
  assessment_risk_note text;
  has_assessment_content boolean;
  requirement_text text;
  requirement_index integer := 0;
  resolved_source_reference_id uuid;
  resolved_source_id uuid;
  resolved_source_url text;
  resolved_source_title text;
  resolved_source_checked_at timestamptz;
  resolved_source_evidence_note text;
begin
  if not public.is_editorial_member() then
    raise exception 'Only editorial members can save campaigns';
  end if;

  resolved_status := coalesce(nullif(trim(p_payload ->> 'status'), ''), 'draft');
  if resolved_status not in ('draft', 'review', 'published', 'expired', 'archived') then
    raise exception 'Unsupported campaign status: %', resolved_status;
  end if;

  resolved_title := nullif(trim(p_payload ->> 'title'), '');
  resolved_summary := nullif(trim(p_payload ->> 'summary'), '');
  resolved_details := nullif(trim(p_payload ->> 'details'), '');

  if resolved_title is null or resolved_summary is null or resolved_details is null then
    raise exception 'Campaign title, summary and details are required';
  end if;

  resolved_program_id := nullif(trim(p_payload ->> 'primaryProgramId'), '')::uuid;
  resolved_category_id := nullif(trim(p_payload ->> 'categoryId'), '')::uuid;
  resolved_editorial_summary := nullif(trim(p_payload ->> 'editorialSummary'), '');
  resolved_last_verified_at := nullif(trim(p_payload ->> 'lastVerifiedAt'), '')::timestamptz;

  assessment_reason := nullif(trim(p_payload ->> 'reasonWhyItMatters'), '');
  assessment_estimated_value := nullif(trim(p_payload ->> 'estimatedValueText'), '');
  assessment_difficulty := nullif(trim(p_payload ->> 'difficultyLevel'), '');
  assessment_availability := nullif(trim(p_payload ->> 'availabilityScope'), '');
  assessment_risk_note := nullif(trim(p_payload ->> 'riskNote'), '');
  has_assessment_content := assessment_reason is not null
    or assessment_estimated_value is not null
    or assessment_difficulty is not null
    or assessment_availability is not null
    or assessment_risk_note is not null;

  resolved_source_id := nullif(trim(p_payload ->> 'sourceId'), '')::uuid;
  resolved_source_url := nullif(trim(p_payload ->> 'sourceUrl'), '');
  resolved_source_title := coalesce(nullif(trim(p_payload ->> 'sourceTitle'), ''), resolved_title);
  resolved_source_checked_at := coalesce(
    nullif(trim(p_payload ->> 'sourceCheckedAt'), '')::timestamptz,
    resolved_last_verified_at,
    now()
  );
  resolved_source_evidence_note := nullif(trim(p_payload ->> 'sourceEvidenceNote'), '');

  if resolved_source_url is not null and resolved_source_url !~* '^https://[^[:space:]]+$' then
    raise exception 'Campaign source URL must be an https URL';
  end if;

  if resolved_status = 'published' then
    if resolved_last_verified_at is null then
      raise exception 'Publishing requires last_verified_at';
    end if;
    if resolved_program_id is null then
      raise exception 'Publishing requires a bonus program';
    end if;
    if resolved_source_id is null or resolved_source_url is null then
      raise exception 'Publishing requires a source';
    end if;
    if assessment_reason is null then
      raise exception 'Publishing requires an editorial reason';
    end if;
  end if;

  update public.campaigns
  set
    title = resolved_title,
    summary = resolved_summary,
    details = resolved_details,
    status = case when resolved_status = 'published' then 'draft' else resolved_status end,
    primary_program_id = resolved_program_id,
    category_id = resolved_category_id,
    editorial_summary = resolved_editorial_summary,
    last_verified_at = resolved_last_verified_at,
    updated_by = auth.uid()
  where id = p_campaign_id
  returning id into p_campaign_id;

  if p_campaign_id is null then
    raise exception 'Campaign not found';
  end if;

  delete from public.campaign_programs
  where campaign_id = p_campaign_id;

  if resolved_program_id is not null then
    insert into public.campaign_programs (campaign_id, program_id)
    values (p_campaign_id, resolved_program_id)
    on conflict do nothing;
  end if;

  delete from public.campaign_requirements
  where campaign_id = p_campaign_id;

  for requirement_text in
    select nullif(trim(value), '')
    from jsonb_array_elements_text(coalesce(p_payload -> 'requirements', '[]'::jsonb))
  loop
    if requirement_text is not null then
      insert into public.campaign_requirements (campaign_id, text, sort_order)
      values (p_campaign_id, requirement_text, requirement_index);
      requirement_index := requirement_index + 1;
    end if;
  end loop;

  if has_assessment_content then
    if assessment_reason is null then
      raise exception 'Editorial assessment requires reason_why_it_matters';
    end if;

    insert into public.campaign_editorial_assessments (
      campaign_id,
      score,
      reason_why_it_matters,
      estimated_value_text,
      difficulty_level,
      availability_scope,
      risk_note
    )
    values (
      p_campaign_id,
      null,
      assessment_reason,
      assessment_estimated_value,
      assessment_difficulty,
      assessment_availability,
      assessment_risk_note
    )
    on conflict (campaign_id) do update
    set
      score = excluded.score,
      reason_why_it_matters = excluded.reason_why_it_matters,
      estimated_value_text = excluded.estimated_value_text,
      difficulty_level = excluded.difficulty_level,
      availability_scope = excluded.availability_scope,
      risk_note = excluded.risk_note;
  else
    delete from public.campaign_editorial_assessments
    where campaign_id = p_campaign_id;
  end if;

  if resolved_source_id is not null and resolved_source_url is not null then
    select id
      into resolved_source_reference_id
    from public.campaign_source_references
    where campaign_id = p_campaign_id
    order by created_at asc
    limit 1;

    if resolved_source_reference_id is null then
      insert into public.campaign_source_references (
        campaign_id,
        source_id,
        url,
        title,
        checked_at,
        evidence_note
      )
      values (
        p_campaign_id,
        resolved_source_id,
        resolved_source_url,
        resolved_source_title,
        resolved_source_checked_at,
        resolved_source_evidence_note
      );
    else
      update public.campaign_source_references
      set
        source_id = resolved_source_id,
        url = resolved_source_url,
        title = resolved_source_title,
        checked_at = resolved_source_checked_at,
        evidence_note = resolved_source_evidence_note
      where id = resolved_source_reference_id;
    end if;
  end if;

  if resolved_status = 'published' then
    update public.campaigns
    set status = 'published'
    where id = p_campaign_id;
  end if;

  return p_campaign_id;
end;
$$;

grant execute on function public.save_editorial_campaign(uuid, jsonb) to authenticated;
grant execute on function public.save_editorial_campaign(uuid, jsonb) to service_role;
