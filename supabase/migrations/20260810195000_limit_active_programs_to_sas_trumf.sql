update public.bonus_programs
set is_active = slug in ('sas-eurobonus', 'trumf')
where slug in (
  'sas-eurobonus',
  'trumf',
  'spenn',
  'flying-blue',
  'norwegian-reward',
  'norwegian-cashpoints',
  'avios'
);
