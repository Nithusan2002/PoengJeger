begin;

insert into public.campaign_categories (id, slug, name)
values
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0101', 'credit-card', 'Kredittkort'),
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102', 'shopping', 'Netthandel'),
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0103', 'telecom', 'Telekom'),
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0104', 'subscription', 'Abonnement'),
  ('1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0105', 'hotel', 'Hotell')
on conflict (id) do update
set
  slug = excluded.slug,
  name = excluded.name;

insert into public.campaign_sources (id, name, source_type, base_url)
values
  ('2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0201', 'SAS', 'official', 'https://www.sas.no'),
  ('2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0202', 'Trumf', 'official', 'https://www.trumf.no'),
  ('2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0203', 'Norwegian Reward', 'official', 'https://www.norwegian.com/no/reward/')
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
  is_active,
  last_checked_at
)
values
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0301',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0201',
    'html_page',
    'https://www.sas.no/eurobonus/tilbud',
    'sas_eurobonus_offers',
    720,
    true,
    '2026-08-02T10:00:00Z'
  ),
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0302',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0202',
    'html_page',
    'https://www.trumf.no/',
    'trumf_frontpage_offers',
    360,
    true,
    '2026-08-02T10:00:00Z'
  ),
  (
    '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0303',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0203',
    'html_page',
    'https://www.norwegian.com/no/reward/',
    'norwegian_reward_partners',
    720,
    true,
    '2026-08-02T10:00:00Z'
  )
on conflict (id) do update
set
  campaign_source_id = excluded.campaign_source_id,
  ingest_kind = excluded.ingest_kind,
  base_url = excluded.base_url,
  parser_key = excluded.parser_key,
  poll_interval_minutes = excluded.poll_interval_minutes,
  is_active = excluded.is_active,
  last_checked_at = excluded.last_checked_at;

delete from public.campaign_geo_restrictions
where campaign_id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

delete from public.campaign_editorial_assessments
where campaign_id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

delete from public.campaign_requirements
where campaign_id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

delete from public.campaign_programs
where campaign_id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

delete from public.campaign_source_references
where campaign_id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

delete from public.campaigns
where id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

insert into public.campaigns (
  id,
  title,
  summary,
  details,
  status,
  start_date,
  end_date,
  last_verified_at,
  primary_program_id,
  category_id,
  editorial_score,
  editorial_summary,
  is_featured
)
select
  campaign_id,
  title,
  summary,
  details,
  'review',
  start_date,
  end_date,
  '2026-08-02T10:00:00Z'::timestamptz,
  primary_program_id,
  category_id,
  editorial_score,
  editorial_summary,
  is_featured
from (
  values
    (
      '4a99a49d-3a3d-40ab-af4d-eade4d0f0401'::uuid,
      'SAS Amex Elite: 50 000 EuroBonus-poeng i velkomstbonus',
      'Offisiell SAS-kampanje for Amex Elite i Norge med 50 000 EuroBonus-poeng i velkomstbonus.',
      'SAS oppgir at Amex Elite i Norge gir 50 000 EuroBonus-poeng i velkomstbonus. Kortet gir også 20 poeng per 100 kr brukt og 2 for 1-reiser med SAS og SkyTeam.',
      null::timestamptz,
      null::timestamptz,
      (select id from public.bonus_programs where slug = 'sas-eurobonus'),
      '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0101'::uuid,
      88.0::numeric,
      'Høy engangsverdi for brukere som faktisk kan oppfylle kortkravene og har nytte av 2 for 1-fordelen.',
      true
    ),
    (
      '4a99a49d-3a3d-40ab-af4d-eade4d0f0402'::uuid,
      'EuroBonus Online Shopping: opptil 100 poeng per 100 kr',
      'SAS viser et løpende partner-tilbud der medlemmer kan tjene opptil 100 poeng per 100 kr via shoppingportalen.',
      'På SAS-siden for medlemstilbud oppgis at EuroBonus Online Shopping gir opptil 100 poeng per 100 kr når du logger inn i portalen før du handler hos tilknyttede butikker.',
      null::timestamptz,
      null::timestamptz,
      (select id from public.bonus_programs where slug = 'sas-eurobonus'),
      '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102'::uuid,
      72.0::numeric,
      'Bra som påfyllskampanje når du allerede skal handle, men faktisk verdi avhenger av butikk og rate den dagen du kjøper.',
      false
    ),
    (
      '4a99a49d-3a3d-40ab-af4d-eade4d0f0403'::uuid,
      'Talkmore via Trumf: 1 000 kr i Trumf-bonus til 11. august 2026',
      'Trumf fronter en tidsbegrenset kampanje med 1 000 kr i velkomstbonus og 4 % Trumf-bonus på mobilregningen hos Talkmore.',
      'Trumf oppgir at nye Talkmore-kunder får 1 000 kr i Trumf-bonus som velkomstgave, i tillegg til 4 % Trumf-bonus på mobilregningen. Kampanjen gjelder til og med 11. august 2026.',
      '2026-08-01T00:00:00Z'::timestamptz,
      '2026-08-11T21:59:59Z'::timestamptz,
      (select id from public.bonus_programs where slug = 'trumf'),
      '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0103'::uuid,
      84.0::numeric,
      'Sterk kortsiktig verdi fordi bonusen er kontantnær og kan kombineres med senere poengoverføring fra Trumf.',
      true
    ),
    (
      '4a99a49d-3a3d-40ab-af4d-eade4d0f0404'::uuid,
      'Nextory via Norwegian Reward: 100 CashPoints og 60 dager gratis',
      'Offisiell partnerkampanje hos Norwegian Reward for nye Nextory-kunder.',
      'Norwegian Reward oppgir at nye Nextory-kunder får 100 CashPoints i velkomstbonus, 60 dager gratis og deretter 10 % CashPoints hver måned abonnementet løper.',
      null::timestamptz,
      null::timestamptz,
      (select id from public.bonus_programs where slug = 'norwegian-reward'),
      '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0104'::uuid,
      66.0::numeric,
      'Lav terskel og enkel gevinst for brukere som uansett vurderer lydboktjeneste, men totalverdien er begrenset.',
      false
    ),
    (
      '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'::uuid,
      'Strawberry via Norwegian Reward: Spenn på hver hotellnatt og medlemsrabatt',
      'Offisiell Strawberry-side hos Norwegian Reward med Spenn-opptjening og 5–15 % medlemsrabatt.',
      'Norwegian Reward beskriver at Strawberry-opphold gir Spenn på hver hotellnatt, gratis avbestilling og 5–15 % medlemsrabatt på hotell, i tillegg til enkelte medlemsfordeler som 2 for 1 på frokost hver mandag.',
      null::timestamptz,
      null::timestamptz,
      (select id from public.bonus_programs where slug = 'spenn'),
      '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0105'::uuid,
      63.0::numeric,
      'Relevant for brukere som faktisk booker hotell i Norden, men Spenn-verdien er mindre eksplisitt enn i en ren velkomstbonus.',
      false
    )
) as seeded_campaigns (
  campaign_id,
  title,
  summary,
  details,
  start_date,
  end_date,
  primary_program_id,
  category_id,
  editorial_score,
  editorial_summary,
  is_featured
);

insert into public.campaign_programs (campaign_id, program_id)
values
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
    (select id from public.bonus_programs where slug = 'sas-eurobonus')
  ),
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
    (select id from public.bonus_programs where slug = 'sas-eurobonus')
  ),
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
    (select id from public.bonus_programs where slug = 'trumf')
  ),
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
    (select id from public.bonus_programs where slug = 'norwegian-reward')
  ),
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0405',
    (select id from public.bonus_programs where slug = 'spenn')
  ),
  (
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0405',
    (select id from public.bonus_programs where slug = 'norwegian-reward')
  );

insert into public.campaign_requirements (id, campaign_id, text, sort_order)
values
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0501', '4a99a49d-3a3d-40ab-af4d-eade4d0f0401', 'Du må søke om SAS Amex Elite i Norge via SAS/Amex-lenken.', 0),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0502', '4a99a49d-3a3d-40ab-af4d-eade4d0f0401', 'Vurder månedsavgiften på 575 kr opp mot faktisk bruk av kortet og reisefordelene.', 1),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0503', '4a99a49d-3a3d-40ab-af4d-eade4d0f0402', 'Du må logge inn i EuroBonus Online Shopping før du går videre til butikken.', 0),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0504', '4a99a49d-3a3d-40ab-af4d-eade4d0f0402', 'Poengsats varierer mellom butikker og kan endres uten varsel.', 1),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0505', '4a99a49d-3a3d-40ab-af4d-eade4d0f0403', 'Du må være ny Talkmore-kunde og registrere kjøpet via Trumf-kampanjen.', 0),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0506', '4a99a49d-3a3d-40ab-af4d-eade4d0f0403', 'Kampanjen gjelder til og med 11. august 2026.', 1),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0507', '4a99a49d-3a3d-40ab-af4d-eade4d0f0404', 'Gjelder nye Nextory-kunder; tidligere kunder må ha vært uten abonnement i minst seks måneder.', 0),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0508', '4a99a49d-3a3d-40ab-af4d-eade4d0f0404', 'Prøveperioden inkluderer 30 timer med lytting og lesing.', 1),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0509', '4a99a49d-3a3d-40ab-af4d-eade4d0f0405', 'Bestillingen må gjøres via Strawberry-partnersiden hos Norwegian Reward.', 0),
  ('5baa5aae-4a4e-41bc-b05e-fbef5e0f0510', '4a99a49d-3a3d-40ab-af4d-eade4d0f0405', 'Spenn krediteres innen 14 dager etter oppholdet.', 1);

insert into public.campaign_source_references (
  id,
  campaign_id,
  source_id,
  url,
  title,
  checked_at,
  evidence_note
)
values
  (
    '6cbb6bbf-5b5f-42cd-c16f-0cfc6f0f0601',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0201',
    'https://www.sas.no/eurobonus/betalingskort/norge',
    'Tjen poeng med SAS EuroBonus-betalingskort',
    '2026-08-02T10:00:00Z',
    'Kontrollert 2. august 2026: SAS oppgir 50 000 Bonuspoeng i velkomstbonus for Amex Elite i Norge.'
  ),
  (
    '6cbb6bbf-5b5f-42cd-c16f-0cfc6f0f0602',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0201',
    'https://www.sas.no/eurobonus/tilbud',
    'Tilbud for EuroBonus-medlemmer',
    '2026-08-02T10:00:00Z',
    'Kontrollert 2. august 2026: SAS viser EuroBonus Online Shopping med opptil 100 poeng per 100 kr.'
  ),
  (
    '6cbb6bbf-5b5f-42cd-c16f-0cfc6f0f0603',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0202',
    'https://www.trumf.no/',
    'Trumf-forsiden',
    '2026-08-02T10:00:00Z',
    'Kontrollert 2. august 2026: Trumf fronter 1 000 kr i Trumf-bonus hos Talkmore, pluss 4 % bonus på mobilregning, gyldig til og med 11. august 2026.'
  ),
  (
    '6cbb6bbf-5b5f-42cd-c16f-0cfc6f0f0604',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0203',
    'https://www.norwegian.com/no/reward/vare-partnere/nextory/',
    'Prøv Nextory lydbøker gratis og få CashPoints',
    '2026-08-02T10:00:00Z',
    'Kontrollert 2. august 2026: Norwegian Reward oppgir 100 CashPoints, 60 dager gratis og 10 % CashPoints løpende.'
  ),
  (
    '6cbb6bbf-5b5f-42cd-c16f-0cfc6f0f0605',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0405',
    '2e77e27b-1e1b-4f89-8d2b-c8bc2b0d0203',
    'https://www.norwegian.com/no/reward/vare-partnere/strawberry/',
    'Book ditt neste hotellopphold med Strawberry',
    '2026-08-02T10:00:00Z',
    'Kontrollert 2. august 2026: Norwegian Reward beskriver Spenn på hver hotellnatt og 5–15 % medlemsrabatt hos Strawberry.'
  );

insert into public.campaign_editorial_assessments (
  id,
  campaign_id,
  score,
  reason_why_it_matters,
  estimated_value_text,
  difficulty_level,
  availability_scope,
  risk_note
)
values
  (
    '7dcc7cc0-6c60-43de-d270-1d0d7d0f0701',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
    88,
    'Stor velkomstbonus i et program mange norske bonusjegere faktisk bruker aktivt.',
    'Høy verdi hvis du kan utnytte både velkomstbonus og 2 for 1-fordel.',
    'medium',
    'regional',
    'Månedsavgiften er høy, så denne passer best for brukere som kan realisere reisefordelene.'
  ),
  (
    '7dcc7cc0-6c60-43de-d270-1d0d7d0f0702',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
    72,
    'Gir enkel, lavfriksjons opptjening på kjøp brukeren kanskje allerede planlegger.',
    'Middels verdi; faktisk uttelling varierer mye mellom butikker.',
    'low',
    'broad',
    'Poengraten er uttrykt som opptil-sats og må dobbeltsjekkes før hvert kjøp.'
  ),
  (
    '7dcc7cc0-6c60-43de-d270-1d0d7d0f0703',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
    84,
    'Stor og tidsbegrenset velkomstbonus i et norsk hverdagsprogram med enkel verdi.',
    '1 000 kr i Trumf-bonus pluss løpende 4 % på mobilregningen.',
    'medium',
    'regional',
    'Krever faktisk bytte av mobilabonnement og passer bare nye Talkmore-kunder.'
  ),
  (
    '7dcc7cc0-6c60-43de-d270-1d0d7d0f0704',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
    66,
    'Enkel partnerkampanje som kan gi litt ekstra verdi uten reisebestilling.',
    '100 CashPoints og 60 dager gratis i prøveperioden.',
    'low',
    'broad',
    'Relevant bare hvis brukeren faktisk ønsker eller kan bruke lydboktjenesten.'
  ),
  (
    '7dcc7cc0-6c60-43de-d270-1d0d7d0f0705',
    '4a99a49d-3a3d-40ab-af4d-eade4d0f0405',
    63,
    'Nyttig for hotellbrukere som vil samle Spenn uten å fly.',
    'Spenn på hver hotellnatt, pluss 5–15 % medlemsrabatt og enkelte fordeler hos Strawberry.',
    'low',
    'regional',
    'Den eksakte Spenn-opptjeningen er ikke oppgitt på siden, så verdien må bekreftes ved booking.'
  );

insert into public.campaign_geo_restrictions (id, campaign_id, country_code)
values
  ('8edd8dd1-7d71-44ef-e381-2e1e8e0f0801', '4a99a49d-3a3d-40ab-af4d-eade4d0f0401', 'NO'),
  ('8edd8dd1-7d71-44ef-e381-2e1e8e0f0802', '4a99a49d-3a3d-40ab-af4d-eade4d0f0402', 'NO'),
  ('8edd8dd1-7d71-44ef-e381-2e1e8e0f0803', '4a99a49d-3a3d-40ab-af4d-eade4d0f0403', 'NO'),
  ('8edd8dd1-7d71-44ef-e381-2e1e8e0f0804', '4a99a49d-3a3d-40ab-af4d-eade4d0f0404', 'NO'),
  ('8edd8dd1-7d71-44ef-e381-2e1e8e0f0805', '4a99a49d-3a3d-40ab-af4d-eade4d0f0405', 'NO');

update public.campaigns
set
  status = 'published',
  last_verified_at = '2026-08-02T10:00:00Z',
  updated_at = now()
where id in (
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0401',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0402',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0403',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0404',
  '4a99a49d-3a3d-40ab-af4d-eade4d0f0405'
);

commit;
