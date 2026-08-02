insert into public.bonus_programs (slug, name, issuer_name, country_code)
values
  ('sas-eurobonus', 'SAS EuroBonus', 'SAS', 'NO'),
  ('trumf', 'Trumf', 'NorgesGruppen', 'NO'),
  ('spenn', 'Spenn', 'Spenn', 'NO'),
  ('norwegian-reward', 'Norwegian Reward', 'Norwegian', 'NO'),
  ('flying-blue', 'Flying Blue', 'Air France-KLM', 'NO')
on conflict (slug) do update
set
  name = excluded.name,
  issuer_name = excluded.issuer_name,
  country_code = excluded.country_code,
  is_active = true;
