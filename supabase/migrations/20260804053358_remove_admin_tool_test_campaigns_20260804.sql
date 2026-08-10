delete from public.ingestion_candidates
where title in (
  'Fly Premium: ekstra tilgjengelighet i august 2026',
  'Fly Premium: ekstra tilgjengelighet i august 2026 (test 2)'
)
and source_url like 'https://www.sas.no/eurobonus/tilbud/ekstrapoeng-flypremium-august-2026%';

delete from public.campaigns
where (
  title = 'Fly Premium: ekstra tilgjengelighet i august 2026 (test 2)'
  or (
    title = 'Fly Premium: ekstra tilgjengelighet i august 2026'
    and status in ('review', 'archived')
  )
);;
