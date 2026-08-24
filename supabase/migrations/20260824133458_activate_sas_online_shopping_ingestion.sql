with sas_source as (
  update public.campaign_sources
  set
    source_type = 'official',
    base_url = 'https://onlineshopping.loyaltykey.com'
  where name = 'SAS EuroBonus Shopping'
  returning id
)
update public.source_registry as registry
set
  ingest_kind = 'api',
  base_url = 'https://onlineshopping.loyaltykey.com/api/v1/shops?filter%5Bchannel%5D=SAS&filter%5Blanguage%5D=nb&filter%5Bcountry%5D=no&filter%5Bamount%5D=5000',
  parser_key = 'sas_eurobonus_shopping',
  poll_interval_minutes = 720,
  is_active = true
from sas_source
where registry.campaign_source_id = sas_source.id
  and registry.parser_key = 'sas_eurobonus_shopping';
