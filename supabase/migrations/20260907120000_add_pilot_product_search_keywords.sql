with keyword_updates(store_name, keywords) as (
  values
    ('Acer', array['laptop', 'pc', 'datamaskin']::text[]),
    ('Komplett', array['laptop', 'pc', 'datamaskin']::text[]),
    ('Lenovo', array['laptop', 'pc', 'datamaskin']::text[]),
    ('Proshop', array['laptop', 'pc', 'datamaskin']::text[]),
    ('AEG', array['vaskemaskin', 'hvitevarer']::text[]),
    ('Bosch', array['vaskemaskin', 'hvitevarer']::text[]),
    ('Siemens Home', array['vaskemaskin', 'hvitevarer']::text[]),
    ('Lufthansa', array['fly', 'flybilletter']::text[]),
    ('Qatar Airways', array['fly', 'flybilletter']::text[]),
    ('lastminute.com', array['fly', 'flybilletter']::text[]),
    ('Omio', array['fly', 'flybilletter']::text[]),
    ('Trip.com', array['fly', 'flybilletter']::text[]),
    ('Adidas', array['sko', 'jakke', 'klær']::text[]),
    ('ASICS', array['sko']::text[]),
    ('Footshop', array['sko']::text[]),
    ('Helly Hansen', array['jakke', 'klær']::text[]),
    ('Lindex', array['jakke', 'klær', 'barneklær']::text[]),
    ('Viking Footwear', array['sko']::text[]),
    ('CAIA', array['sminke', 'makeup']::text[]),
    ('Kicks', array['sminke', 'makeup']::text[]),
    ('Lyko', array['sminke', 'makeup']::text[]),
    ('Makeup Mekka', array['sminke', 'makeup']::text[]),
    ('Sephora', array['sminke', 'makeup']::text[]),
    ('Vita', array['sminke', 'makeup']::text[]),
    ('Guttelus', array['barneklær', 'barneklaer']::text[]),
    ('PatPat', array['barneklær', 'barneklaer']::text[]),
    ('Polarn O. Pyret', array['barneklær', 'barneklaer']::text[]),
    ('BookBeat', array['lydbok', 'lydbøker', 'lydboker']::text[]),
    ('Fabel', array['lydbok', 'lydbøker', 'lydboker']::text[]),
    ('Nextory', array['lydbok', 'lydbøker', 'lydboker']::text[]),
    ('Storytel', array['lydbok', 'lydbøker', 'lydboker']::text[]),
    ('Dyrekassen', array['hundemat', 'kattemat', 'dyremat']::text[]),
    ('PetXL', array['hundemat', 'kattemat', 'dyremat']::text[]),
    ('VetZoo', array['hundemat', 'kattemat', 'dyremat']::text[])
)
update public.stores as store
set
  search_keywords = (
    select array_agg(distinct keyword order by keyword)
    from unnest(store.search_keywords || keyword_updates.keywords) as keyword
  ),
  updated_at = now()
from keyword_updates
where lower(store.name) = lower(keyword_updates.store_name);
