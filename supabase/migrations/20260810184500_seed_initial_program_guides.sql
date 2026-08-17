insert into public.bonus_programs (slug, name, issuer_name, country_code)
values
  ('sas-eurobonus', 'SAS EuroBonus', 'SAS', 'NO'),
  ('trumf', 'Trumf', 'NorgesGruppen', 'NO'),
  ('spenn', 'Spenn', 'Spenn', 'NO')
on conflict (slug) do update
set
  name = excluded.name,
  issuer_name = excluded.issuer_name,
  country_code = excluded.country_code;

insert into public.program_guides (
  program_id,
  status,
  strategy,
  earning_tips,
  redemption_tips,
  risk_notes,
  last_reviewed_at
)
values
  (
    (select id from public.bonus_programs where slug = 'sas-eurobonus'),
    'published',
    'EuroBonus passer best når du kan samle nok poeng til reiser eller fordeler du faktisk vil bruke. Vurder kampanjer opp mot fleksibilitet, gebyrer og om reisen allerede er relevant.',
    array[
      'Prioriter kampanjer der du uansett skal kjøpe reisen, varen eller tjenesten.',
      'Se etter kombinasjoner av kort, partner og tidsbegrenset kampanje, men kontroller vilkårene før du handler.',
      'Vær ekstra kritisk til tilbud som krever nytt kredittkort eller høyt minimumsforbruk.'
    ],
    array[
      'Bruk poeng der kontantprisen er høy og tilgjengeligheten passer dine datoer.',
      'Sammenlign poengbruk med ordinær pris, skatter, gebyrer og fleksibilitet.',
      'Ikke bind deg til opptjening hvis du ikke har en realistisk plan for bruk.'
    ],
    array[
      'Tilgjengelighet på bonusreiser kan være begrenset.',
      'Kampanjer kan være målrettet eller ha krav som ikke er synlige i overskriften.',
      'Poengverdi er et estimat, ikke en fast kurs.'
    ],
    '2026-08-10T00:00:00Z'
  ),
  (
    (select id from public.bonus_programs where slug = 'trumf'),
    'published',
    'Trumf er ofte mest nyttig når bonusen kommer fra dagligvarekjøp du allerede ville gjort. Høy prosentbonus er mindre verdt hvis varen er dyrere enn alternativet.',
    array[
      'Aktiver kampanjer før kjøp når det kreves.',
      'Sjekk om bonusen gjelder hele handelen eller bare utvalgte varer.',
      'Vurder totalpris først, bonus etterpå.'
    ],
    array[
      'Bruk saldoen der den gir konkret verdi for deg, eller overfør bare når vilkårene passer.',
      'Følg med på kampanjer som gjør ordinære kjøp mer lønnsomme uten ekstra friksjon.',
      'Hold oversikt over aktiveringskrav og kampanjeperioder.'
    ],
    array[
      'Utvalg, butikk og medlemskrav kan variere.',
      'Bonus kan beregnes etter rabatter eller med unntak for enkelte varer.',
      'Ikke la bonusprosent alene styre kjøpet.'
    ],
    '2026-08-10T00:00:00Z'
  ),
  (
    (select id from public.bonus_programs where slug = 'spenn'),
    'published',
    'Spenn bør vurderes som et partnerprogram der verdien avhenger av om du allerede bruker relevante partnere. Kampanjer med lav friksjon og planlagt kjøp er mest interessante.',
    array[
      'Knytt kjøpet til riktig partnerflyt før betaling.',
      'Prioriter kampanjer på reise, hotell eller handel du allerede har behov for.',
      'Sjekk om kampanjen krever registrering, appbruk eller en bestemt lenke.'
    ],
    array[
      'Sammenlign poengbruk med kontantpris før du bruker saldo.',
      'Bruk poeng på kjøp der alternativverdien er tydelig for deg.',
      'Unngå å spre opptjening hvis du ikke når nyttige innløsningsnivåer.'
    ],
    array[
      'Partnerkrav kan gjøre en enkel kampanje mindre enkel i praksis.',
      'Verdien av poengbruk kan variere mellom partnere.',
      'Kampanjer kan kreve korrekt sporing for at bonusen skal registreres.'
    ],
    '2026-08-10T00:00:00Z'
  )
on conflict (program_id) do update
set
  status = excluded.status,
  strategy = excluded.strategy,
  earning_tips = excluded.earning_tips,
  redemption_tips = excluded.redemption_tips,
  risk_notes = excluded.risk_notes,
  last_reviewed_at = excluded.last_reviewed_at;
