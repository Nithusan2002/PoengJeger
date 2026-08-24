begin;

insert into public.campaign_categories (id, slug, name)
values
  ('51ec3b45-91d1-4fa1-95c4-16120e16c111', 'dagligvare', 'Dagligvare'),
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'shopping', 'Netthandel'),
  ('3a850a1a-96f1-4ae1-8cd9-4eb49aa7a113', 'reise', 'Reise')
on conflict (id) do update
set slug = excluded.slug,
    name = excluded.name;

insert into public.stores (id, slug, name, category_id, status, website_url, search_keywords, last_verified_at)
values
  ('720b66db-0478-4a6e-8e18-2d07da1b0101', 'elkjop', 'Elkjøp', '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'published', 'https://www.elkjop.no', array['elektronikk', 'tv', 'mobil', 'data'], '2026-08-24T13:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0102', 'komplett', 'Komplett', '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'published', 'https://www.komplett.no', array['elektronikk', 'pc', 'gaming'], '2026-08-24T13:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0103', 'meny', 'MENY', '51ec3b45-91d1-4fa1-95c4-16120e16c111', 'published', 'https://meny.no', array['dagligvare', 'mat', 'trumf'], '2026-08-24T13:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0104', 'hotels-com', 'Hotels.com', '3a850a1a-96f1-4ae1-8cd9-4eb49aa7a113', 'published', 'https://no.hotels.com', array['hotell', 'reise', 'overnatting'], '2026-08-24T13:00:00Z')
on conflict (id) do update
set slug = excluded.slug,
    name = excluded.name,
    category_id = excluded.category_id,
    status = excluded.status,
    website_url = excluded.website_url,
    search_keywords = excluded.search_keywords,
    last_verified_at = excluded.last_verified_at;

insert into public.earning_methods (id, slug, name, method_type, program_id, status, description)
values
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0201', 'sas-eurobonus-online-shopping', 'EuroBonus Online Shopping', 'portal', (select id from public.bonus_programs where slug = 'sas-eurobonus'), 'published', 'Opptjening via SAS EuroBonus Online Shopping.'),
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0202', 'trumf', 'Trumf', 'loyalty', (select id from public.bonus_programs where slug = 'trumf'), 'published', 'Opptjening via Trumf-medlemskap eller Trumf-partner.')
on conflict (slug) do update
set name = excluded.name,
    method_type = excluded.method_type,
    program_id = excluded.program_id,
    status = excluded.status,
    description = excluded.description,
    updated_at = now();

delete from public.earning_combination_steps
where combination_id in (
  select id
  from public.earning_combinations
  where title = 'Beste kombinasjon'
    and store_id in (
      '720b66db-0478-4a6e-8e18-2d07da1b0101',
      '720b66db-0478-4a6e-8e18-2d07da1b0102',
      '720b66db-0478-4a6e-8e18-2d07da1b0103',
      '720b66db-0478-4a6e-8e18-2d07da1b0104'
    )
);

delete from public.earning_combination_rates
where combination_id in (
  select id
  from public.earning_combinations
  where title = 'Beste kombinasjon'
    and store_id in (
      '720b66db-0478-4a6e-8e18-2d07da1b0101',
      '720b66db-0478-4a6e-8e18-2d07da1b0102',
      '720b66db-0478-4a6e-8e18-2d07da1b0103',
      '720b66db-0478-4a6e-8e18-2d07da1b0104'
    )
)
or store_earning_rate_id in (
  select ser.id
  from public.store_earning_rates ser
  join public.earning_methods em on em.id = ser.earning_method_id
  where ser.store_id in (
      '720b66db-0478-4a6e-8e18-2d07da1b0101',
      '720b66db-0478-4a6e-8e18-2d07da1b0102',
      '720b66db-0478-4a6e-8e18-2d07da1b0103',
      '720b66db-0478-4a6e-8e18-2d07da1b0104'
    )
    and em.slug in ('sas-eurobonus-online-shopping', 'trumf')
);

delete from public.earning_combinations
where title = 'Beste kombinasjon'
  and store_id in (
    '720b66db-0478-4a6e-8e18-2d07da1b0101',
    '720b66db-0478-4a6e-8e18-2d07da1b0102',
    '720b66db-0478-4a6e-8e18-2d07da1b0103',
    '720b66db-0478-4a6e-8e18-2d07da1b0104'
  );

delete from public.store_earning_rates
where id in (
  '940d88fd-269a-4c80-a030-4f29fc3d0301',
  '940d88fd-269a-4c80-a030-4f29fc3d0302',
  '940d88fd-269a-4c80-a030-4f29fc3d0303',
  '940d88fd-269a-4c80-a030-4f29fc3d0306'
)
or id in (
  select ser.id
  from public.store_earning_rates ser
  join public.earning_methods em on em.id = ser.earning_method_id
  where ser.store_id in (
      '720b66db-0478-4a6e-8e18-2d07da1b0101',
      '720b66db-0478-4a6e-8e18-2d07da1b0102',
      '720b66db-0478-4a6e-8e18-2d07da1b0103',
      '720b66db-0478-4a6e-8e18-2d07da1b0104'
    )
    and em.slug in ('sas-eurobonus-online-shopping', 'trumf')
);

insert into public.store_earning_rates (
  id, store_id, earning_method_id, status, rate_label, normal_rate_label, value_summary,
  requirement_summary, warning_text, handoff_url, source_url, source_title, checked_at,
  starts_at, ends_at, sort_order, is_base_rate
)
values
  (
    '940d88fd-269a-4c80-a030-4f29fc3d0304',
    '720b66db-0478-4a6e-8e18-2d07da1b0102',
    (select id from public.earning_methods where slug = 'sas-eurobonus-online-shopping'),
    'published',
    '15 EuroBonus-poeng per 100 kr',
    '15 EuroBonus-poeng per 100 kr',
    'SAS Online Shopping oppgir 15 poeng per 100 kr for Komplett i norsk SAS-feed.',
    'Start kjøpet via SAS EuroBonus Online Shopping for at poengene skal spores.',
    'SAS-feedet oppgir at poeng ikke utbetales for forhåndsbestillinger av PS5.',
    'https://onlineshopping.flysas.com/nb-NO/butikker/komplett-1/01896310-4cf5-73e3-ba30-14f26f67ddb9',
    'https://onlineshopping.loyaltykey.com/api/v1/shops?filter%5Bchannel%5D=SAS&filter%5Blanguage%5D=nb&filter%5Bcountry%5D=no&filter%5Bamount%5D=5000',
    'SAS EuroBonus Online Shopping norsk butikkfeed',
    '2026-08-24T13:00:00Z',
    null,
    null,
    10,
    true
  ),
  (
    '940d88fd-269a-4c80-a030-4f29fc3d0305',
    '720b66db-0478-4a6e-8e18-2d07da1b0103',
    (select id from public.earning_methods where slug = 'trumf'),
    'published',
    '1 % Trumf',
    '1 % Trumf',
    'Vanlig Trumf-opptjening på dagligvarer.',
    'Bruk Trumf-medlemskap når du handler hos MENY.',
    'Trumf oppgir unntak for blant annet pant, spill, gavekort og post i butikk.',
    'https://www.trumf.no/trumf-pay',
    'https://www.trumf.no/trumf-pay',
    'Trumf Pay',
    '2026-08-24T13:00:00Z',
    null,
    null,
    10,
    true
  )
on conflict (id) do update
set earning_method_id = excluded.earning_method_id,
    status = excluded.status,
    rate_label = excluded.rate_label,
    normal_rate_label = excluded.normal_rate_label,
    value_summary = excluded.value_summary,
    requirement_summary = excluded.requirement_summary,
    warning_text = excluded.warning_text,
    handoff_url = excluded.handoff_url,
    source_url = excluded.source_url,
    source_title = excluded.source_title,
    checked_at = excluded.checked_at,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    sort_order = excluded.sort_order,
    is_base_rate = excluded.is_base_rate,
    updated_at = now();

insert into public.earning_combinations (
  id, store_id, status, title, total_value_label, summary, easier_alternative_label,
  warning_text, primary_handoff_url, last_verified_at, sort_order
)
values
  (
    'a51e990e-37ab-4d91-b141-503afd4e0402',
    '720b66db-0478-4a6e-8e18-2d07da1b0102',
    'published',
    'Beste kombinasjon',
    '15 EuroBonus-poeng per 100 kr',
    'Start hos SAS EuroBonus Online Shopping før du handler hos Komplett.',
    null,
    'SAS-feedet oppgir at poeng ikke utbetales for forhåndsbestillinger av PS5.',
    'https://onlineshopping.flysas.com/nb-NO/butikker/komplett-1/01896310-4cf5-73e3-ba30-14f26f67ddb9',
    '2026-08-24T13:00:00Z',
    10
  ),
  (
    'a51e990e-37ab-4d91-b141-503afd4e0403',
    '720b66db-0478-4a6e-8e18-2d07da1b0103',
    'published',
    'Beste kombinasjon',
    '1 % Trumf',
    'Bruk Trumf-medlemskap ved betaling. Vurder totalpris før bonus.',
    null,
    'Trumf oppgir unntak for blant annet pant, spill, gavekort og post i butikk.',
    'https://www.trumf.no/trumf-pay',
    '2026-08-24T13:00:00Z',
    10
  )
on conflict (id) do update
set status = excluded.status,
    title = excluded.title,
    total_value_label = excluded.total_value_label,
    summary = excluded.summary,
    easier_alternative_label = excluded.easier_alternative_label,
    warning_text = excluded.warning_text,
    primary_handoff_url = excluded.primary_handoff_url,
    last_verified_at = excluded.last_verified_at,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.earning_combination_rates (combination_id, store_earning_rate_id, sort_order)
values
  ('a51e990e-37ab-4d91-b141-503afd4e0402', '940d88fd-269a-4c80-a030-4f29fc3d0304', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0403', '940d88fd-269a-4c80-a030-4f29fc3d0305', 10)
on conflict (combination_id, store_earning_rate_id) do update
set sort_order = excluded.sort_order;

insert into public.earning_combination_steps (id, combination_id, text, sort_order)
values
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0505', 'a51e990e-37ab-4d91-b141-503afd4e0402', 'Gå via SAS EuroBonus Online Shopping før du handler hos Komplett.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0506', 'a51e990e-37ab-4d91-b141-503afd4e0402', 'Fullfør kjøpet i samme nettleserøkt og kontroller at kjøpet spores i EuroBonus.', 20),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0507', 'a51e990e-37ab-4d91-b141-503afd4e0403', 'Bruk Trumf-medlemskap når du handler hos MENY.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0508', 'a51e990e-37ab-4d91-b141-503afd4e0403', 'Sjekk at bonusen er registrert etter kjøpet.', 20)
on conflict (id) do update
set text = excluded.text,
    sort_order = excluded.sort_order,
    updated_at = now();

commit;
