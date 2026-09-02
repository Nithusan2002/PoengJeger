insert into public.program_guides (
  program_id,
  title,
  status,
  intro_text,
  strategy,
  value_estimate_label,
  value_estimate_detail,
  expiration_summary,
  expiration_detail,
  guide_kicker,
  reading_time_label,
  strategy_section_title,
  decision_section_title,
  earning_decision_label,
  redemption_decision_label,
  risk_decision_label,
  earning_section_title,
  earning_section_intro,
  redemption_section_title,
  redemption_section_intro,
  risk_section_title,
  risk_section_intro,
  campaigns_section_title,
  campaigns_section_intro,
  earning_tips,
  redemption_tips,
  risk_notes,
  last_reviewed_at
)
values
  (
    (select id from public.bonus_programs where slug = 'sas-eurobonus'),
    'Slik fungerer SAS EuroBonus',
    'published',
    'EuroBonus fungerer best når du vet hva poengene skal brukes til. Start med målet ditt, finn ut omtrent hvor mange bonuspoeng du trenger, og bygg opptjeningen rundt kjøp du faktisk ville gjort.',
    'Lag et enkelt poengkart: flyreiser, dagligvarer, netthandel, hotell, leiebil, abonnementer og kortbruk. Poenget er ikke å handle mer, men å samle eksisterende kjøp i færre, riktige kanaler når pris og vilkår fortsatt er gode.',
    'Reiseverdi',
    'Verdien varierer med rute, dato, tilgjengelighet, avgifter og hva samme reise ville kostet kontant.',
    'Sjekk poengtype',
    'Bonuspoeng kan brukes til reiser og andre fordeler. Nivåpoeng teller mot medlemsnivå og følger kvalifiseringsperioden.',
    'PROGRAMGUIDE',
    '4 min lesing',
    'Slik bør du bruke det',
    'Før du går videre',
    'Tjen poeng når',
    'Bruk poeng når',
    'Stopp opp hvis',
    'Slik tjener du poeng',
    'Start med målet, og bygg opptjeningen rundt kjøp du allerede har.',
    'Slik bruker du poengene smart',
    'Bruk poengene der forskjellen mot kontantpris faktisk er tydelig.',
    'Vanlige feller',
    'Det som gjør en sterk poengmulighet svakere i praksis.',
    'Kampanjer nå',
    'Aktive kampanjer knyttet til SAS EuroBonus.',
    array[
      'Definer målet først: rabatt på en kort tur, bonusreise, oppgradering eller en større reise for flere personer.',
      'Skil mellom bonuspoeng og nivåpoeng før du vurderer en kampanje.',
      'Kartlegg de store kanalene først: fly og SkyTeam-partnere, SAS-partnere, Trumf, netthandelsportaler, hotell, leiebil og betalingskort.',
      'Start netthandel og partnerkjøp fra riktig portal eller lenke når sporing er en del av vilkårene.',
      'Bruk dobbelopptjening bare når den er enkel: riktig portal eller partner pluss et kort som gir EuroBonus-poeng.',
      'Sjekk kampanjer og velkomstbonuser, men regn med gebyrer, binding og omsetningskrav før du lar dem styre valget.'
    ],
    array[
      'Bruk poeng der kontantprisen er høy og tilgjengeligheten passer datoene dine.',
      'Sammenlign poengpris med ordinær pris, skatter, gebyrer og billettfleksibilitet.',
      'Sjekk om award flight, oppgradering eller annen poengbruk passer bedre enn å betale kontant.',
      'Ikke bind deg til opptjening hvis du ikke har en realistisk plan for bruk innen rimelig tid.',
      'Sjekk alternative avganger før du konkluderer med at en kampanje gir god verdi.'
    ],
    array[
      'Tilgjengelighet på bonusreiser kan være begrenset på populære datoer og ruter.',
      'Kampanjer kan være målrettet eller ha krav som ikke er synlige i overskriften.',
      'Poengverdi er et estimat, ikke en fast kurs.',
      'Gebyrer, skatter og manglende fleksibilitet kan spise opp mye av verdien.',
      'Kortavgifter, omsetningskrav og dyrere butikker kan koste mer enn poengene er verdt for deg.',
      'Dobbel- og trippelopptjening kan feile hvis sporing, rabattkoder, korttype eller partnerregler ikke passer.'
    ],
    '2026-08-26T00:00:00Z'
  ),
  (
    (select id from public.bonus_programs where slug = 'trumf'),
    'Slik fungerer Trumf',
    'published',
    'Trumf er enklere enn mange poengprogrammer fordi bonusen har tydelig kroneverdi. Den viktigste vurderingen er likevel om totalprisen fortsatt er god etter at bonusen er regnet inn.',
    'Bruk Trumf som rabatt på kjøp du uansett ville gjort. Ekstra bonus er mest interessant når prisen, butikkvalget og vilkårene fortsatt er fornuftige uten at bonusen må redde regnestykket.',
    'Kronebonus',
    'Trumf-bonus opptjenes i kroner. Verdien endrer seg først når du velger bruksmåte, for eksempel butikk, bankkonto eller overføring til EuroBonus.',
    'Fleksibelt',
    'Sjekk saldo, uttak og overføringsvilkår før du flytter bonus til andre programmer.',
    'PROGRAMGUIDE',
    '3 min lesing',
    'Slik bør du bruke det',
    'Før du går videre',
    'Tjen bonus når',
    'Bruk bonus når',
    'Stopp opp hvis',
    'Slik tjener du Trumf',
    'Start med handlemønsteret ditt, ikke med bonusprosenten.',
    'Slik bruker du bonusen smart',
    'Velg bruksmåten som gir mest verdi og minst friksjon for deg.',
    'Vanlige feller',
    'Detaljer som ofte avgjør om Trumf faktisk lønner seg.',
    'Kampanjer nå',
    'Aktive kampanjer knyttet til Trumf.',
    array[
      'Aktiver personlige eller tidsbegrensede kampanjer før kjøp når det kreves.',
      'Sjekk om bonusen gjelder hele handelen, bestemte varer, bestemte butikker eller netthandel via partner.',
      'Vurder totalpris først, bonus etterpå.',
      'Bruk handlelister og planlagte kjøp til å skille nyttig bonus fra mersalg.',
      'Kontroller om kuponger, rabatter eller betalingsmåte påvirker bonusgrunnlaget.'
    ],
    array[
      'Bruk saldoen som kontantbonus når det gir konkret verdi for deg.',
      'Vurder overføring til EuroBonus bare når du forstår vilkår, timing og hva poengene skal brukes til.',
      'Se etter kampanjer som gir ekstra bonus på kjøp du uansett skulle gjøre.',
      'Hold oversikt over aktiveringskrav og kampanjeperioder.',
      'Sammenlign alltid bonusen med billigste realistiske alternativ.'
    ],
    array[
      'Utvalg, butikk, medlemskrav og aktivering kan variere mellom kampanjer.',
      'Bonus kan beregnes etter rabatter eller med unntak for enkelte varer.',
      'Ikke la bonusprosent alene styre kjøpet.',
      'Høy ekstra bonus kan fortsatt være dårlig verdi hvis varen er dyrere enn hos alternativer.',
      'Overføring til andre programmer kan gjøre en fleksibel kroneverdi mindre fleksibel.'
    ],
    '2026-08-26T00:00:00Z'
  ),
  (
    (select id from public.bonus_programs where slug = 'spenn'),
    'Slik fungerer Spenn',
    'published',
    'Spenn er mest nyttig når du allerede bruker partnerne. Start med kampanjer som passer et kjøp du faktisk skal gjøre.',
    'Bruk Spenn når partneren allerede passer planene dine. Ikke jag små poeng hvis du må kjøpe noe ekstra.',
    'Partnerverdi',
    'Verdien styres av hvor du kan opptjene og bruke poengene.',
    'Følg saldo',
    'Kontroller program- og partnervilkår før større opptjening eller bruk.',
    'PROGRAMGUIDE',
    '3 min lesing',
    'Slik bør du bruke det',
    'Før du går videre',
    'Tjen poeng når',
    'Bruk poeng når',
    'Stopp opp hvis',
    'Slik tjener du poeng',
    'Start med partnerne du allerede bruker.',
    'Slik bruker du poengene smart',
    'Bruk poengene der du enkelt ser hva du får igjen.',
    'Vanlige feller',
    'Ting som kan gjøre en enkel kampanje mindre enkel.',
    'Kampanjer nå',
    'Aktive kampanjer knyttet til Spenn.',
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
on conflict do nothing;

/*
  program_guides intentionally allows multiple articles per program. The seed
  data is therefore insert-only after the initial reset.
*/
