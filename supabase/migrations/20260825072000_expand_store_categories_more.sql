begin;

insert into public.campaign_categories (slug, name)
values
  ('bil-motor', 'Bil og motor'),
  ('boker-medier', 'Bøker og medier'),
  ('dyr-kjaeledyr', 'Dyr og kjæledyr'),
  ('programvare', 'Programvare')
on conflict (slug) do update
set
  name = excluded.name,
  updated_at = now();

commit;
