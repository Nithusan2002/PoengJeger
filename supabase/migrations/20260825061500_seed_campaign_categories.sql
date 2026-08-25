begin;

insert into public.campaign_categories (slug, name)
values
  ('subscription', 'Abonnement'),
  ('dagligvare', 'Dagligvare'),
  ('hotel', 'Hotell'),
  ('credit-card', 'Kredittkort'),
  ('shopping', 'Netthandel'),
  ('reise', 'Reise'),
  ('telecom', 'Telekom')
on conflict (slug) do update
set
  name = excluded.name,
  updated_at = now();

commit;
