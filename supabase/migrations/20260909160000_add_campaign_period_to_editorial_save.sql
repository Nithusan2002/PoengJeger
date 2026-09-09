create or replace function public.save_editorial_campaign_with_period(
  p_campaign_id uuid,
  p_payload jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  saved_campaign_id uuid;
  resolved_start_date timestamptz;
  resolved_end_date timestamptz;
begin
  resolved_start_date := nullif(trim(p_payload ->> 'startDate'), '')::timestamptz;
  resolved_end_date := nullif(trim(p_payload ->> 'endDate'), '')::timestamptz;

  if resolved_start_date is not null
    and resolved_end_date is not null
    and resolved_end_date < resolved_start_date then
    raise exception 'Campaign end date cannot be before start date';
  end if;

  saved_campaign_id := public.save_editorial_campaign(p_campaign_id, p_payload);

  update public.campaigns
  set
    start_date = resolved_start_date,
    end_date = resolved_end_date
  where id = saved_campaign_id;

  return saved_campaign_id;
end;
$$;

grant execute on function public.save_editorial_campaign_with_period(uuid, jsonb) to authenticated;
grant execute on function public.save_editorial_campaign_with_period(uuid, jsonb) to service_role;

comment on function public.save_editorial_campaign_with_period(uuid, jsonb) is
  'Atomically saves editorial campaign content and its optional validity period.';
