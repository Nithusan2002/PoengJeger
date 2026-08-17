insert into public.bonus_programs (slug, name, issuer_name, country_code, is_active)
values
  ('sas-eurobonus', 'SAS EuroBonus', 'SAS', 'NO', true),
  ('trumf', 'Trumf', 'NorgesGruppen', 'NO', true),
  ('spenn', 'Spenn', 'Spenn', 'NO', false),
  ('norwegian-reward', 'Norwegian Reward', 'Norwegian', 'NO', false),
  ('flying-blue', 'Flying Blue', 'Air France-KLM', 'NO', false)
on conflict (slug) do update
set
  name = excluded.name,
  issuer_name = excluded.issuer_name,
  country_code = excluded.country_code,
  is_active = excluded.is_active;
