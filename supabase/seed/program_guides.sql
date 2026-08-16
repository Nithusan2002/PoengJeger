insert into public.program_guides (
  program_id,
  status,
  intro_text,
  strategy,
  value_estimate_label,
  value_estimate_detail,
  expiration_summary,
  expiration_detail,
  earning_tips,
  redemption_tips,
  risk_notes,
  last_reviewed_at
)
values
  (
    (select id from public.bonus_programs where slug = 'sas-eurobonus'),
    'published',
    'EuroBonus er nyttig når du har en konkret plan for opptjening og bruk. Guiden hjelper deg å vurdere kampanjer opp mot fleksibilitet, gebyrer og faktisk reisebehov.',
    'EuroBonus passer best når du kan samle nok poeng til reiser eller fordeler du faktisk vil bruke. Vurder kampanjer opp mot fleksibilitet, gebyrer og om reisen allerede er relevant.',
    'Varierer',
    'Verdien avhenger av reisemål, tilgjengelighet, avgifter og alternativ kontantpris.',
    'Sjekk vilkår',
    'Kontroller alltid gjeldende utløpsregler hos SAS før du lar saldo ligge lenge.',
    array[
      'Prioriter kampanjer der du uansett skal kjøpe reisen, varen eller tjenesten.',
      'Se etter kombinasjoner av kort, partner og tidsbegrenset kampanje, men kontroller vilkårene før du handler.',
      'Vær ekstra kritisk til tilbud som krever nytt kredittkort eller høyt kortbruk.'
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
    'Trumf er lett å forstå fordi bonusen kan brukes som penger. Totalprisen bør likevel styre valget.',
    'Trumf er ofte mest nyttig når bonusen kommer fra dagligvarekjøp du allerede ville gjort. Høy prosentbonus er mindre verdt hvis varen er dyrere enn alternativet.',
    '1 kr = 1 kr',
    'Trumf-bonus er konkret kroneverdi, men kampanjeverdi må vurderes mot totalpris.',
    'Lett å bruke',
    'Sjekk saldo og overføringsvilkår før du flytter bonus til andre programmer.',
    array[
      'Aktiver kampanjer før kjøp når det kreves.',
      'Sjekk om bonusen gjelder hele handelen eller bare utvalgte varer.',
      'Vurder totalpris først, bonus etterpå.'
    ],
    array[
      'Bruk saldoen der den gir konkret verdi for deg, eller overfør bare når vilkårene passer.',
      'Se etter kampanjer som gir ekstra bonus på kjøp du uansett skulle gjøre.',
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
    'Spenn er mest nyttig når du allerede bruker partnerne. Start med kampanjer som passer et kjøp du faktisk skal gjøre.',
    'Bruk Spenn når partneren allerede passer planene dine. Ikke jag små poeng hvis du må kjøpe noe ekstra.',
    'Partnerverdi',
    'Verdien styres av hvor du kan opptjene og bruke poengene.',
    'Følg saldo',
    'Kontroller program- og partnervilkår før større opptjening eller bruk.',
    array[
      'Knytt kjøpet til riktig partnerflyt før betaling.',
      'Prioriter kampanjer på reise, hotell eller handel du allerede har behov for.',
      'Sjekk om kampanjen krever registrering, appbruk eller en bestemt lenke.'
    ],
    array[
      'Sammenlign poengbruk med kontantpris før du bruker saldo.',
      'Bruk poeng der du enkelt ser hva du får igjen.',
      'Ikke spre poengene for mye hvis saldoen aldri blir stor nok til noe nyttig.'
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
  intro_text = excluded.intro_text,
  strategy = excluded.strategy,
  value_estimate_label = excluded.value_estimate_label,
  value_estimate_detail = excluded.value_estimate_detail,
  expiration_summary = excluded.expiration_summary,
  expiration_detail = excluded.expiration_detail,
  earning_tips = excluded.earning_tips,
  redemption_tips = excluded.redemption_tips,
  risk_notes = excluded.risk_notes,
  last_reviewed_at = excluded.last_reviewed_at;
