with target_rates(store_name, requirement_summary, warning_text) as (
  values
    ('BookBeat', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kilden oppgir prøveperiode for nye kunder og at nye kunder tilsvarer ett kjøp per 360 dager. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Bodystore', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 4,6 % for ny kunde og 2,3 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Gymgrossisten', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 4,6 % for ny kunde og 2,3 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Storytel', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kilden oppgir at nye kunder tilsvarer ett kjøp per 360 dager. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Bladkongen', 'Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Hvis kjøpet er et abonnement, er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Vistaprint', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 6,2 % for ny kunde og 1,9 % for eksisterende kunde. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Fabel', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kjøp med rabattkode kan gjøre at Trumf-bonus ikke spores. Kontroller vilkårene hos Trumf før kjøp.'),
    ('ZOO', 'Høyeste Trumf-sats gjelder ny kunde. Øvrige kjøp har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 6,2 % for ny kunde og 1,5 % for hele nettbutikken. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Click&Boat', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 4,6 % for ny kunde og 2,3 % for eksisterende kunde. Kjøpet bekreftes innen 90 dager etter fullført opphold.'),
    ('Autodeler', 'Høyeste Trumf-sats gjelder ny kunde. Dekk og kjøp fra eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 6,2 % for ny kunde, 3,1 % for eksisterende kunde og 0,7 % for dekk. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('G-Star', 'Høyeste Trumf-sats gjelder nye kunder som kjøper fullprisvarer. Salgsprodukter og eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 9,3 % for ny kunde på fullprisvarer, 4,6 % for ny kunde på salgsprodukter, 6,2 % for eksisterende kunde på fullprisvarer og 1,1 % for eksisterende kunde på salgsprodukter.'),
    ('Direct Ferries', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder og Corsica Ferries har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 3,1 % for ny kunde, 1,5 % for eksisterende kunde og 0,7 % for Corsica Ferries. Ved båtreise starter behandlingstiden først etter at reisen er gjennomført.'),
    ('Omio', 'Gjelder nye kunder. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kilden oppgir at kjøpet kan bli avvist ved kansellering av booking. Rabattkoder kan gjøre at Trumf-bonus ikke spores.')
)
update public.store_earning_rates rate
set
  requirement_summary = target.requirement_summary,
  warning_text = target.warning_text,
  checked_at = now(),
  updated_at = now()
from target_rates target
join public.stores store on store.name = target.store_name
join public.earning_methods method on method.slug = 'trumf'
where rate.store_id = store.id
  and rate.earning_method_id = method.id;

with target_combinations(store_name, warning_text) as (
  values
    ('BookBeat', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Kilden oppgir at nye kunder tilsvarer ett kjøp per 360 dager. Beregningen forutsetter automatisk Trumf-overføring til EuroBonus.'),
    ('Bodystore', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Gymgrossisten', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Storytel', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Kilden oppgir at nye kunder tilsvarer ett kjøp per 360 dager. Beregningen forutsetter automatisk Trumf-overføring til EuroBonus.'),
    ('Bladkongen', 'Ved abonnement er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Vistaprint', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Fabel', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('ZOO', 'Høyeste Trumf-sats gjelder ny kunde; øvrige kjøp har lavere sats. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Click&Boat', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Kjøpet bekreftes innen 90 dager etter fullført opphold.'),
    ('Autodeler', 'Høyeste Trumf-sats gjelder ny kunde. Dekk og kjøp fra eksisterende kunder har lavere sats. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('G-Star', 'Høyeste Trumf-sats gjelder nye kunder som kjøper fullprisvarer. Salgsprodukter og eksisterende kunder har lavere sats.'),
    ('Direct Ferries', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder og Corsica Ferries har lavere sats. Ved båtreise starter behandlingstiden først etter at reisen er gjennomført.'),
    ('Omio', 'Gjelder nye kunder. Kjøpet kan bli avvist ved kansellering av booking. Rabattkoder kan gjøre at Trumf-bonus ikke spores.')
)
update public.earning_combinations combo
set
  warning_text = target.warning_text,
  last_verified_at = now(),
  updated_at = now()
from target_combinations target
join public.stores store on store.name = target.store_name
where combo.store_id = store.id
  and exists (
    select 1
    from public.earning_combination_rates combo_rate
    join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
    join public.earning_methods method on method.id = rate.earning_method_id
    where combo_rate.combination_id = combo.id
      and method.slug = 'trumf'
  );

update public.stores store
set
  last_verified_at = now(),
  updated_at = now()
where store.name in (
  'BookBeat',
  'Bodystore',
  'Gymgrossisten',
  'Storytel',
  'Bladkongen',
  'Vistaprint',
  'Fabel',
  'ZOO',
  'Click&Boat',
  'Autodeler',
  'G-Star',
  'Direct Ferries',
  'Omio'
);
