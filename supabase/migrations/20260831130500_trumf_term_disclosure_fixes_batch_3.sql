with target_rates(store_name, requirement_summary, warning_text) as (
  values
    ('Proteinfabrikken', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 4,6 % for ny kunde og 2,3 % for eksisterende kunde. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Goboken', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kjøp med rabattkode kan gjøre at Trumf-bonus ikke spores. Kontroller vilkårene hos Trumf før kjøp.'),
    ('Vivara', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 4,8 % for ny kunde og 1,7 % for eksisterende kunde. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('SkyShowtime', 'Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser lavere sats for månedsabonnement og høyere sats for årsabonnement. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Albert', 'Gjelder nye kunder. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Det gis ikke Trumf-bonus dersom abonnementet sies opp i prøveperioden. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('EMP', 'Høyeste Trumf-sats gjelder ny kunde. Eksisterende kunder har lavere sats. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kildekontroll viser 5,4 % for ny kunde og 3,1 % for eksisterende kunde. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Oslo Skin Lab', 'Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Hvis kjøpet er et abonnement, er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Helly Hansen', 'Trumf-satsen gjelder ny kunde. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Kjøp gjennom Helly Hansen Pro Program gir ikke bonus. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Strim', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Start handelen via Trumf Netthandel for at Trumf-bonusen skal spores.', 'Det gis ikke Trumf-bonus dersom abonnementet sies opp i prøveperioden. Kildekontroll viser ulike faste satser avhengig av valgt abonnementspakke.')
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
    ('Proteinfabrikken', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Goboken', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Vivara', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('SkyShowtime', 'Ved abonnement er kun første betaling bonusberettiget. Ulike abonnementstyper kan gi ulik fast Trumf-bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Albert', 'Gjelder nye kunder. Det gis ikke Trumf-bonus dersom abonnementet sies opp i prøveperioden. Beregningen forutsetter automatisk Trumf-overføring til EuroBonus.'),
    ('EMP', 'Høyeste Trumf-sats gjelder ny kunde; eksisterende kunder har lavere sats. Kjøp gjort i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Oslo Skin Lab', 'Ved abonnement er kun første betaling bonusberettiget. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Helly Hansen', 'Trumf-satsen gjelder ny kunde. Kjøp gjennom Helly Hansen Pro Program eller i forhandlerens app gir ikke bonus. Rabattkoder kan gjøre at Trumf-bonus ikke spores.'),
    ('Strim', 'Gjelder nye kunder. Ved abonnement er kun første betaling bonusberettiget. Det gis ikke Trumf-bonus dersom abonnementet sies opp i prøveperioden.')
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
  'Proteinfabrikken',
  'Goboken',
  'Vivara',
  'SkyShowtime',
  'Albert',
  'EMP',
  'Oslo Skin Lab',
  'Helly Hansen',
  'Strim'
);
