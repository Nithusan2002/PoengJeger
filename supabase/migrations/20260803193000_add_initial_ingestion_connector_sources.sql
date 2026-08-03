insert into public.campaign_sources (id, name, source_type, base_url)
values
  (
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0211',
    'Trumf Netthandel',
    'official',
    'https://trumfnetthandel.no'
  ),
  (
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0212',
    'SAS EuroBonus Shopping',
    'official',
    'https://onlineshopping.loyaltykey.com'
  ),
  (
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0213',
    're:member reward',
    'bank',
    'https://www.remember.no/reward/rabatt'
  )
on conflict (id) do update
set
  name = excluded.name,
  source_type = excluded.source_type,
  base_url = excluded.base_url;

insert into public.source_registry (
  id,
  campaign_source_id,
  ingest_kind,
  base_url,
  parser_key,
  poll_interval_minutes,
  is_active
)
values
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0311',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0211',
    'api',
    'https://wlp.tcb-cdn.com/trumf/notifierfeed.json',
    'trumf_netthandel',
    720,
    true
  ),
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0312',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0212',
    'api',
    'https://onlineshopping.loyaltykey.com/api/browser-extension/sas/nb-NO/shops',
    'sas_eurobonus_shopping',
    720,
    false
  ),
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0313',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0213',
    'html_page',
    'https://www.remember.no/reward/rabatt',
    'remember_reward',
    720,
    true
  )
on conflict (id) do update
set
  campaign_source_id = excluded.campaign_source_id,
  ingest_kind = excluded.ingest_kind,
  base_url = excluded.base_url,
  parser_key = excluded.parser_key,
  poll_interval_minutes = excluded.poll_interval_minutes,
  is_active = excluded.is_active;
