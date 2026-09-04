begin;

create or replace view public.analytics_sanity_7d
with (security_invoker = true)
as
with funnel_steps(step_order, event_name) as (
  values
    (1, 'app_opened'),
    (2, 'store_search_started'),
    (3, 'store_search_result_opened'),
    (4, 'store_detail_opened'),
    (5, 'best_combination_viewed'),
    (6, 'handoff_opened'),
    (7, 'external_destination_opened'),
    (8, 'campaign_detail_opened'),
    (9, 'guide_opened'),
    (10, 'favorite_added'),
    (11, 'favorite_removed')
),
event_counts as (
  select
    product_events.event_name,
    count(*)::bigint as event_count,
    count(distinct product_events.session_id)::bigint as session_count,
    count(distinct product_events.anonymous_user_id)::bigint as user_count,
    max(product_events.occurred_at) as latest_at
  from public.product_events
  where product_events.occurred_at >= now() - interval '7 days'
    and product_events.event_name in (
      select funnel_steps.event_name
      from funnel_steps
    )
  group by product_events.event_name
)
select
  funnel_steps.step_order,
  funnel_steps.event_name,
  coalesce(event_counts.event_count, 0) as event_count,
  coalesce(event_counts.session_count, 0) as session_count,
  coalesce(event_counts.user_count, 0) as user_count,
  event_counts.latest_at
from funnel_steps
left join event_counts
  on event_counts.event_name = funnel_steps.event_name
order by funnel_steps.step_order;

comment on view public.analytics_sanity_7d is
  'Read-only 7-day aggregate over core product analytics events for pilot sanity checks. Uses security_invoker so product_events RLS still applies.';

revoke all on public.analytics_sanity_7d from anon, authenticated;
grant select on public.analytics_sanity_7d to authenticated;

commit;
