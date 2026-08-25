begin;

with category_ids as (
  select
    max(id) filter (where slug = 'dagligvare') as dagligvare_id,
    max(id) filter (where slug = 'elektronikk') as elektronikk_id,
    max(id) filter (where slug = 'klaer-sko') as klaer_sko_id,
    max(id) filter (where slug = 'sport-fritid') as sport_fritid_id,
    max(id) filter (where slug = 'helse-skjonnhet') as helse_skjonnhet_id,
    max(id) filter (where slug = 'barn-familie') as barn_familie_id,
    max(id) filter (where slug = 'hus-hjem') as hus_hjem_id,
    max(id) filter (where slug = 'bil-motor') as bil_motor_id,
    max(id) filter (where slug = 'boker-medier') as boker_medier_id,
    max(id) filter (where slug = 'dyr-kjaeledyr') as dyr_kjaeledyr_id,
    max(id) filter (where slug = 'programvare') as programvare_id,
    max(id) filter (where slug = 'hotel') as hotel_id,
    max(id) filter (where slug = 'reise') as reise_id,
    max(id) filter (where slug = 'telecom') as telecom_id,
    max(id) filter (where slug = 'credit-card') as credit_card_id,
    max(id) filter (where slug = 'subscription') as subscription_id,
    max(id) filter (where slug = 'annet') as annet_id,
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
  where ic.promoted_campaign_id is null
    and ic.promoted_store_earning_rate_id is null
    and ic.status in ('new', 'needs_review', 'approved')
    and sr.parser_key in ('trumf_netthandel', 'sas_eurobonus_shopping', 'remember_reward')
)
update public.ingestion_candidates ic
set suggested_category_id = coalesce(
  case
    when c.haystack similar to '%(dagligvare|grocery|matkasse|matvarer|meny|kiwi|spar|joker|oda|kolonial|godtlevert|adamsmatkasse|adams matkasse|morgenlevering|foodstuff)%'
      then category_ids.dagligvare_id
    when c.haystack similar to '%(programvare|software|security|antivirus|vpn|avast|avg|norton|mcafee)%'
      then category_ids.programvare_id
    when c.haystack similar to '%(elektronikk|electronics|computer|data|gaming|mobiltelefon|hvitevarer|komplett|power|elkjøp|elkjop|netonnet|dustin|proshop)%'
      or c.haystack like '% pc %'
      or c.haystack like '% tv %'
      or c.haystack like '% lyd %'
      or c.haystack similar to '%(acer|aeg|bosch|dyson|electrolux|elektroimportoren|elektroimportøren|elon|batteriexperten|harman kardon|foto.no|fotoknudsen|inkclub|inkmann|ideal of sweden|estore|hamphi|jbl|lenovo|minifinder)%'
      then category_ids.elektronikk_id
    when c.haystack similar to '%(klaer|klær|fashion|mote|clothing|shoes|sneakers|boots|zalando|boozt|nelly|ellos|dressmann|cubus|bikbok)%'
      or c.haystack like '% sko %'
      or c.haystack like '% h m %'
      or c.haystack like '% hm %'
      or c.haystack similar to '%(adidas|aimn|aim n|asics|bjorn borg|björn borg|bonprix|bubbleroom|chicastore|edblad|berg watches|daniel wellington|bagbrokers|farfetch|floyd|g-star|gina tricot|guttelus|haglöfs|helly hansen|hunkemoller|hunkemöller|emp|gullfunn|j.lindeberg|jlindeberg|junkyard|kouture|lindex|miinto)%'
      or c.haystack like '% db %'
      then category_ids.klaer_sko_id
    when c.haystack similar to '%(sport|fritid|trening|fitness|outdoor|friluft|sykkel|ski|jakt|fiske|lopeshop|løpeshop|fjellsport|xxl|gymgrossisten|milrab)%'
      or c.haystack like '% tur %'
      or c.haystack similar to '%(e-wheels|evoride|myprotein|new balance)%'
      then category_ids.sport_fritid_id
    when c.haystack similar to '%(helse|skjønnhet|skjonnhet|beauty|apotek|pharmacy|hudpleie|makeup|kosmetikk|parfyme|blivakker|bangerhead|lyko|coverbrands|farmasiet|apotekhjem|barbershop|bodystore|dentaworks|fredrik & louisa|fredrik-and-louisa|glowid|hudprodukter|kayani|kicks|kondomeriet|l''occitane|loccitane|lenson|lensway|libresse|maxa)%'
      or c.haystack like '% hair %'
      then category_ids.helse_skjonnhet_id
    when c.haystack similar to '%(barn|baby|familie|kids|leker|toys|barneklær|barneklaer|jollyroom|lekmer|babymarkt|babyshop|navnelapper|beckmann|lappeliten|lego|mimmis)%'
      then category_ids.barn_familie_id
    when c.haystack similar to '%(interiør|interior|mobel|møbel|furniture|hage|garden|bygg|verktoy|verktøy|kjokken|kjøkken|kitchen|lampe|ledlys|lyskilder|jernia|clas ohlson|princess|kitchn|kitch''n|kitchenone)%'
      or c.haystack like '% hus %'
      or c.haystack like '% hjem %'
      or c.haystack like '% home %'
      or c.haystack like '% lys %'
      or c.haystack like '% kid %'
      or c.haystack similar to '%(bad & stil|bad.no|bakeren og kokken|drømmerom|ekstralys|fyrklövern|grønt fokus|høie|homeroom|husqvarna|inzpero|karcher|kärcher|kokkeglede|lexington|lightup|lunehjem|newport)%'
      then category_ids.hus_hjem_id
    when c.haystack similar to '%(bil|motor|bildeler|autodeler|autodoc|autodude|bilxtra|dekk|dekkonline|eurodel)%'
      then category_ids.bil_motor_id
    when c.haystack similar to '%(bok|boker|bøker|bokia|blad|bladkongen|magasin|media|medier|fabel|kinogavekort|kinoklubben)%'
      then category_ids.boker_medier_id
    when c.haystack similar to '%(dyr|kjaeledyr|kjæledyr|pet|pets|dyrekassen|zooplus|vetzoo|i-love-dogs|i love dogs)%'
      then category_ids.dyr_kjaeledyr_id
    when c.haystack similar to '%(hotel|hotell|hotels|overnatting|strawberry|scandic|thon|radisson|booking)%'
      then category_ids.hotel_id
    when c.haystack similar to '%(reise|travel|flight|ferie|cruise|leiebil|rentalcar|hertz|avis leiebil|norwegian)%'
      or c.haystack like '% fly %'
      or c.haystack like '% tog %'
      or c.haystack like '% buss %'
      or c.haystack like '% vy %'
      or c.haystack similar to '%(auto europe|budget|click&boat|direct ferries|campanyon|fjord line|getyourguide|go city|havila kystruten|interhome|lastminute|lufthansa|nazar)%'
      then category_ids.reise_id
    when c.haystack similar to '%(telekom|mobil|mobile|bredband|broadband|telia|telenor|onecall|talkmore|chilimobil)%'
      or c.haystack like '% ice %'
      then category_ids.telecom_id
    when c.haystack similar to '%(kredittkort|creditcard|credit card|americanexpress|american express|mastercard|amex)%'
      or c.haystack like '% visa %'
      then category_ids.credit_card_id
    when c.haystack similar to '%(abonnement|subscription|streaming|lydbok|storytel|bookbeat|viaplay|tv2play|disney|spotify|avisabonnement|match.com)%'
      then category_ids.subscription_id
    else coalesce(category_ids.annet_id, category_ids.shopping_id)
  end,
  category_ids.shopping_id
)
from candidates c
cross join category_ids
where ic.id = c.id;

commit;
