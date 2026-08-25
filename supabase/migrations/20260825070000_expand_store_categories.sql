begin;

insert into public.campaign_categories (slug, name)
values
  ('elektronikk', 'Elektronikk'),
  ('klaer-sko', 'Klær og sko'),
  ('sport-fritid', 'Sport og fritid'),
  ('helse-skjonnhet', 'Helse og skjønnhet'),
  ('barn-familie', 'Barn og familie'),
  ('hus-hjem', 'Hus og hjem'),
  ('annet', 'Annet')
on conflict (slug) do update
set
  name = excluded.name,
  updated_at = now();

commit;
