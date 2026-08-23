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
  ('720b66db-0478-4a6e-8e18-2d07da1b0101', 'elkjop', 'Elkjøp', '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'published', 'https://www.elkjop.no', array['elektronikk', 'tv', 'mobil', 'data'], '2026-08-23T10:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0102', 'komplett', 'Komplett', '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'published', 'https://www.komplett.no', array['elektronikk', 'pc', 'gaming'], '2026-08-23T10:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0103', 'meny', 'Meny', '51ec3b45-91d1-4fa1-95c4-16120e16c111', 'published', 'https://meny.no', array['dagligvare', 'mat', 'trumf'], '2026-08-23T10:00:00Z'),
  ('720b66db-0478-4a6e-8e18-2d07da1b0104', 'hotels-com', 'Hotels.com', '3a850a1a-96f1-4ae1-8cd9-4eb49aa7a113', 'published', 'https://no.hotels.com', array['hotell', 'reise', 'overnatting'], '2026-08-23T10:00:00Z')
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
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0201', 'eurobonus-shopping', 'EuroBonus Shopping', 'portal', (select id from public.bonus_programs where slug = 'sas-eurobonus'), 'published', 'Start handelen via EuroBonus Shopping-portalen.'),
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0202', 'trumf', 'Trumf', 'loyalty', (select id from public.bonus_programs where slug = 'trumf'), 'published', 'Opptjening via Trumf-medlemskap eller Trumf-partner.'),
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0203', 'sas-mastercard-premium', 'SAS Mastercard Premium', 'card', (select id from public.bonus_programs where slug = 'sas-eurobonus'), 'published', 'Kortopptjening for brukere som allerede har riktig kort.'),
  ('830c77ec-1589-4b7f-9f29-3e18eb2c0204', 'aktuell-kampanje', 'Aktuell kampanje', 'campaign', null, 'published', 'Tidsbegrenset forbedring eller engangsbonus.')
on conflict (id) do update
set slug = excluded.slug,
    name = excluded.name,
    method_type = excluded.method_type,
    program_id = excluded.program_id,
    status = excluded.status,
    description = excluded.description;

insert into public.store_earning_rates (
  id, store_id, earning_method_id, status, rate_label, normal_rate_label, value_summary,
  requirement_summary, warning_text, handoff_url, source_url, source_title, checked_at,
  starts_at, ends_at, sort_order, is_base_rate
)
values
  ('940d88fd-269a-4c80-a030-4f29fc3d0301', '720b66db-0478-4a6e-8e18-2d07da1b0101', '830c77ec-1589-4b7f-9f29-3e18eb2c0201', 'published', '10 poeng / 100 kr', null, 'Vanlig opptjening via EuroBonus Shopping.', 'Start via EuroBonus Shopping før du går til Elkjøp.', 'Ikke bruk en annen rabattportal etter at handelen er startet.', 'https://www.sas.no/eurobonus/partners/shopping/', 'https://www.sas.no/eurobonus/partners/shopping/', 'EuroBonus Shopping', '2026-08-23T10:00:00Z', null, null, 10, true),
  ('940d88fd-269a-4c80-a030-4f29fc3d0302', '720b66db-0478-4a6e-8e18-2d07da1b0101', '830c77ec-1589-4b7f-9f29-3e18eb2c0204', 'published', '20 poeng / 100 kr', '10 poeng / 100 kr', 'Midlertidig forbedret opptjening hos Elkjøp.', 'Må startes via EuroBonus Shopping i kampanjeperioden.', 'Kontroller at Elkjøp fortsatt vises med forhøyet sats før kjøp.', 'https://www.sas.no/eurobonus/partners/shopping/', 'https://www.sas.no/eurobonus/partners/shopping/', 'EuroBonus Shopping', '2026-08-23T10:00:00Z', '2026-08-23T00:00:00Z', '2026-08-28T21:59:59Z', 20, false),
  ('940d88fd-269a-4c80-a030-4f29fc3d0303', '720b66db-0478-4a6e-8e18-2d07da1b0101', '830c77ec-1589-4b7f-9f29-3e18eb2c0203', 'published', '5 poeng / 100 kr', null, 'Kortopptjening dersom du allerede har SAS Mastercard Premium.', 'Krever SAS Mastercard Premium og vanlig kortbruk.', null, null, 'https://saseurobonusmastercard.no', 'SAS EuroBonus Mastercard', '2026-08-23T10:00:00Z', null, null, 30, false),
  ('940d88fd-269a-4c80-a030-4f29fc3d0304', '720b66db-0478-4a6e-8e18-2d07da1b0102', '830c77ec-1589-4b7f-9f29-3e18eb2c0201', 'published', '15 poeng / 100 kr', null, 'Vanlig opptjening via EuroBonus Shopping.', 'Start via EuroBonus Shopping før du går til Komplett.', 'Ikke bruk annen portal eller rabattlenke underveis.', 'https://www.sas.no/eurobonus/partners/shopping/', 'https://www.sas.no/eurobonus/partners/shopping/', 'EuroBonus Shopping', '2026-08-23T10:00:00Z', null, null, 10, true),
  ('940d88fd-269a-4c80-a030-4f29fc3d0305', '720b66db-0478-4a6e-8e18-2d07da1b0103', '830c77ec-1589-4b7f-9f29-3e18eb2c0202', 'published', '1 % Trumf', null, 'Vanlig Trumf-opptjening på dagligvarer.', 'Bruk Trumf-medlemskap i kassen.', null, 'https://www.trumf.no', 'https://www.trumf.no', 'Trumf', '2026-08-23T10:00:00Z', null, null, 10, true),
  ('940d88fd-269a-4c80-a030-4f29fc3d0306', '720b66db-0478-4a6e-8e18-2d07da1b0104', '830c77ec-1589-4b7f-9f29-3e18eb2c0201', 'published', '18 poeng / 100 kr', null, 'Opptjening via EuroBonus Shopping.', 'Start via EuroBonus Shopping før booking.', 'Les hotellvilkår og avbestilling før du betaler.', 'https://www.sas.no/eurobonus/partners/shopping/', 'https://www.sas.no/eurobonus/partners/shopping/', 'EuroBonus Shopping', '2026-08-23T10:00:00Z', null, null, 10, true)
on conflict (id) do update
set status = excluded.status,
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
    is_base_rate = excluded.is_base_rate;

insert into public.earning_combinations (
  id, store_id, status, title, total_value_label, summary, easier_alternative_label,
  warning_text, primary_handoff_url, last_verified_at, sort_order
)
values
  ('a51e990e-37ab-4d91-b141-503afd4e0401', '720b66db-0478-4a6e-8e18-2d07da1b0101', 'published', 'Beste kombinasjon', '25 EuroBonus-poeng / 100 kr', 'Start via EuroBonus Shopping mens forhøyet sats gjelder, og betal med SAS Mastercard Premium hvis du allerede har kortet.', '20 poeng / 100 kr uten kort', 'Ikke bruk annen rabattportal etter at du har startet handelen.', 'https://www.sas.no/eurobonus/partners/shopping/', '2026-08-23T10:00:00Z', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0402', '720b66db-0478-4a6e-8e18-2d07da1b0102', 'published', 'Beste kombinasjon', '15 EuroBonus-poeng / 100 kr', 'Start via EuroBonus Shopping og fullfør hos Komplett i samme økt.', null, 'Ikke bruk en annen portal underveis.', 'https://www.sas.no/eurobonus/partners/shopping/', '2026-08-23T10:00:00Z', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0403', '720b66db-0478-4a6e-8e18-2d07da1b0103', 'published', 'Beste kombinasjon', '1 % Trumf', 'Bruk Trumf-medlemskap ved betaling. Vurder totalpris før bonus.', null, null, 'https://www.trumf.no', '2026-08-23T10:00:00Z', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0404', '720b66db-0478-4a6e-8e18-2d07da1b0104', 'published', 'Beste kombinasjon', '18 EuroBonus-poeng / 100 kr', 'Start via EuroBonus Shopping før booking og sjekk hotellvilkår før betaling.', null, 'Avbestilling og poengopptjening kan avhenge av romtype og vilkår.', 'https://www.sas.no/eurobonus/partners/shopping/', '2026-08-23T10:00:00Z', 10)
on conflict (id) do update
set status = excluded.status,
    title = excluded.title,
    total_value_label = excluded.total_value_label,
    summary = excluded.summary,
    easier_alternative_label = excluded.easier_alternative_label,
    warning_text = excluded.warning_text,
    primary_handoff_url = excluded.primary_handoff_url,
    last_verified_at = excluded.last_verified_at,
    sort_order = excluded.sort_order;

delete from public.earning_combination_rates
where combination_id in (
  'a51e990e-37ab-4d91-b141-503afd4e0401',
  'a51e990e-37ab-4d91-b141-503afd4e0402',
  'a51e990e-37ab-4d91-b141-503afd4e0403',
  'a51e990e-37ab-4d91-b141-503afd4e0404'
);
insert into public.earning_combination_rates (combination_id, store_earning_rate_id, sort_order)
values
  ('a51e990e-37ab-4d91-b141-503afd4e0401', '940d88fd-269a-4c80-a030-4f29fc3d0302', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0401', '940d88fd-269a-4c80-a030-4f29fc3d0303', 20),
  ('a51e990e-37ab-4d91-b141-503afd4e0402', '940d88fd-269a-4c80-a030-4f29fc3d0304', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0403', '940d88fd-269a-4c80-a030-4f29fc3d0305', 10),
  ('a51e990e-37ab-4d91-b141-503afd4e0404', '940d88fd-269a-4c80-a030-4f29fc3d0306', 10);

delete from public.earning_combination_steps
where combination_id in (
  'a51e990e-37ab-4d91-b141-503afd4e0401',
  'a51e990e-37ab-4d91-b141-503afd4e0402',
  'a51e990e-37ab-4d91-b141-503afd4e0403',
  'a51e990e-37ab-4d91-b141-503afd4e0404'
);
insert into public.earning_combination_steps (id, combination_id, text, sort_order)
values
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0501', 'a51e990e-37ab-4d91-b141-503afd4e0401', 'Start hos EuroBonus Shopping.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0502', 'a51e990e-37ab-4d91-b141-503afd4e0401', 'Gå videre til Elkjøp fra portalen.', 20),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0503', 'a51e990e-37ab-4d91-b141-503afd4e0401', 'Betal med SAS Mastercard Premium hvis du allerede har kortet.', 30),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0504', 'a51e990e-37ab-4d91-b141-503afd4e0401', 'Fullfør kjøpet før kampanjen utløper.', 40),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0505', 'a51e990e-37ab-4d91-b141-503afd4e0402', 'Start hos EuroBonus Shopping.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0506', 'a51e990e-37ab-4d91-b141-503afd4e0402', 'Gå videre til Komplett og fullfør i samme økt.', 20),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0507', 'a51e990e-37ab-4d91-b141-503afd4e0403', 'Bruk Trumf-medlemskap når du handler hos Meny.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0508', 'a51e990e-37ab-4d91-b141-503afd4e0403', 'Sjekk at bonusen er registrert etter kjøpet.', 20),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0509', 'a51e990e-37ab-4d91-b141-503afd4e0404', 'Start hos EuroBonus Shopping.', 10),
  ('b62faa1f-48bc-4ea2-b252-614b0f5f0510', 'a51e990e-37ab-4d91-b141-503afd4e0404', 'Gå videre til Hotels.com og kontroller hotellvilkårene.', 20);

commit;
