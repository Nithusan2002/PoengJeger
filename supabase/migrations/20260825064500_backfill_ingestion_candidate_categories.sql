begin;

with category_ids as (
  select
    max(id) filter (where slug = 'dagligvare') as dagligvare_id,
    max(id) filter (where slug = 'hotel') as hotel_id,
    max(id) filter (where slug = 'reise') as reise_id,
    max(id) filter (where slug = 'telecom') as telecom_id,
    max(id) filter (where slug = 'credit-card') as credit_card_id,
    max(id) filter (where slug = 'subscription') as subscription_id,
    max(id) filter (where slug = 'shopping') as shopping_id
  from public.campaign_categories
),
candidates as (
  select
    ic.id,
    lower(
      concat_ws(
        ' ',
        ic.title,
        ic.source_url,
        ic.metadata ->> 'host_name',
        ic.metadata ->> 'url_name',
        ic.metadata ->> 'shop_slug',
        ic.metadata ->> 'source_description_text'
      )
    ) as haystack
  from public.ingestion_candidates ic
  join public.source_registry sr on sr.id = ic.source_registry_id
  where ic.suggested_category_id is null
    and ic.promoted_campaign_id is null
    and ic.promoted_store_earning_rate_id is null
    and ic.status in ('new', 'needs_review', 'approved')
    and sr.parser_key in ('trumf_netthandel', 'sas_eurobonus_shopping', 'remember_reward')
)
update public.ingestion_candidates ic
set suggested_category_id = coalesce(
  case
    when c.haystack like '%dagligvare%'
      or c.haystack like '%grocery%'
      or c.haystack like '%matkasse%'
      or c.haystack like '%matvarer%'
      or c.haystack like '%meny%'
      or c.haystack like '%kiwi%'
      or c.haystack like '%spar%'
      or c.haystack like '%joker%'
      or c.haystack like '%oda%'
      or c.haystack like '%kolonial%'
      or c.haystack like '%godtlevert%'
      or c.haystack like '%adamsmatkasse%'
      or c.haystack like '%adams matkasse%'
      or c.haystack like '%morgenlevering%'
      then category_ids.dagligvare_id
    when c.haystack like '%hotel%'
      or c.haystack like '%hotell%'
      or c.haystack like '%hotels%'
      or c.haystack like '%overnatting%'
      or c.haystack like '%strawberry%'
      or c.haystack like '%scandic%'
      or c.haystack like '%thon%'
      or c.haystack like '%radisson%'
      or c.haystack like '%booking%'
      then category_ids.hotel_id
    when c.haystack like '%reise%'
      or c.haystack like '%travel%'
      or c.haystack like '%flight%'
      or c.haystack like '%fly%'
      or c.haystack like '%tog%'
      or c.haystack like '%buss%'
      or c.haystack like '%ferie%'
      or c.haystack like '%cruise%'
      or c.haystack like '%leiebil%'
      or c.haystack like '%rentalcar%'
      or c.haystack like '%hertz%'
      or c.haystack like '%avis%'
      or c.haystack like '%vy%'
      or c.haystack like '%norwegian%'
      then category_ids.reise_id
    when c.haystack like '%telekom%'
      or c.haystack like '%mobil%'
      or c.haystack like '%mobile%'
      or c.haystack like '%bredband%'
      or c.haystack like '%broadband%'
      or c.haystack like '%telia%'
      or c.haystack like '%telenor%'
      or c.haystack like '%onecall%'
      or c.haystack like '%talkmore%'
      or c.haystack like '%chilimobil%'
      or c.haystack like '%ice%'
      then category_ids.telecom_id
    when c.haystack like '%kredittkort%'
      or c.haystack like '%creditcard%'
      or c.haystack like '%credit card%'
      or c.haystack like '%americanexpress%'
      or c.haystack like '%american express%'
      or c.haystack like '%mastercard%'
      or c.haystack like '%visa%'
      or c.haystack like '%amex%'
      then category_ids.credit_card_id
    when c.haystack like '%abonnement%'
      or c.haystack like '%subscription%'
      or c.haystack like '%streaming%'
      or c.haystack like '%lydbok%'
      or c.haystack like '%storytel%'
      or c.haystack like '%bookbeat%'
      or c.haystack like '%viaplay%'
      or c.haystack like '%tv2play%'
      or c.haystack like '%disney%'
      or c.haystack like '%spotify%'
      or c.haystack like '%avisabonnement%'
      then category_ids.subscription_id
    else category_ids.shopping_id
  end,
  category_ids.shopping_id
)
from candidates c
cross join category_ids
where ic.id = c.id;

commit;
