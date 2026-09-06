begin;

update public.stores
set
  search_keywords = (
    select array(
      select distinct keyword
      from unnest(search_keywords || array['kontaktlinser', 'linser', 'optikk']) as keyword
      where nullif(trim(keyword), '') is not null
      order by keyword
    )
  ),
  updated_at = now()
where lower(name) in ('lensway', 'lenson');

commit;
