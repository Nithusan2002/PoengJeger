begin;

delete from public.ingestion_candidates
where id in (
  '5b10b50e-4b4e-41bc-b05e-ebde5e0f0501'
);

insert into public.ingestion_candidates (
  id,
  source_registry_id,
  source_url,
  detected_at,
  title,
  summary,
  raw_content,
  normalized_hash,
  suggested_program_id,
  suggested_category_id,
  status,
  metadata
)
values (
  '5b10b50e-4b4e-41bc-b05e-ebde5e0f0501',
  '3f88f38c-2f2c-4f9a-9e3c-d9cd3c0e0301',
  'https://www.sas.no/eurobonus/tilbud/ekstrapoeng-flypremium-august-2026',
  '2026-08-03T08:00:00Z'::timestamptz,
  'Fly Premium: ekstra tilgjengelighet i august 2026',
  'Mulig ny SAS-kampanje med ekstra tilgjengelighet for Fly Premium-kunder.',
  'SAS-siden beskriver ekstra tilgjengelighet for bonusreiser i august 2026 for medlemmer med Fly Premium. Vilkår og faktisk målgruppe må kvalitetssikres redaksjonelt før eventuell publisering.',
  'seed-fly-premium-august-2026',
  (select id from public.bonus_programs where slug = 'sas-eurobonus'),
  '1d66d16a-0d0a-4e78-9c1a-b7ab1a0c0102',
  'new',
  jsonb_build_object(
    'seed_kind', 'manual_test_candidate',
    'created_for', 'admin_ingestion_workflow',
    'expected_action', 'review_then_promote_to_draft'
  )
);

commit;
