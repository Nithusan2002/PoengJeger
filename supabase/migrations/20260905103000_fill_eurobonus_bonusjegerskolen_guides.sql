do $$
declare
  v_program_id uuid;
begin
  select id
    into v_program_id
  from public.bonus_programs
  where slug = 'sas-eurobonus';

  if v_program_id is null then
    raise exception 'Missing bonus program: sas-eurobonus';
  end if;

  with guide_data(title, title_aliases, reading_time_label, body_markdown) as (
    values
      (
        'Hva er EuroBonus?',
        array['Hva er EuroBonus?', 'Hva er SAS EuroBonus?', '1. Hva er Eurobonus?', '1. Hva er EuroBonus?'],
        '4 min lesing',
        $guide$# Hva er EuroBonus?

EuroBonus er SAS sitt lojalitetsprogram. Programmet er relevant for Poengjeger fordi du kan tjene bonuspoeng både på reiser og på en del hverdagskjøp, men verdien av poengene avhenger av hvordan du bruker dem.

## Kort forklart

- Medlemskap i EuroBonus er gratis.
- Bonuspoeng kan brukes til blant annet bonusreiser, hotell, leiebil, oppgraderinger og EuroBonus Shop.
- Nivåpoeng brukes til medlemsnivåer som Sølv, Gull og Diamant. De kan ikke brukes som betalingsmiddel for bonusreiser.
- SAS er i SkyTeam, og EuroBonus kan derfor være relevant også på utvalgte partnerreiser.
- Poeng er ikke en fast valuta. Samme antall poeng kan gi svært ulik verdi på ulike reiser.

## Hva poengene kan brukes til

Start med flyreiser hvis målet er høy verdi. Bonusreiser kan gi god uttelling når kontantprisen er høy, du finner ledige bonusseter, og skatter og avgifter ikke spiser opp fordelen.

Poeng kan også brukes på hotell, leiebil, oppgraderinger, lounge, produkter og andre fordeler. Det kan være praktisk, men sjekk alltid hva du faktisk får igjen sammenlignet med kontantpris.

## Bonuspoeng og nivåpoeng

Bonuspoeng er poengene du samler for å bruke senere. Nivåpoeng handler om status. Begge kan opptjenes på kvalifiserende flyreiser, og enkelte partnere eller kort kan også gi nivåpoeng.

Hold disse adskilt når du vurderer kampanjer. En kampanje som gir mange bonuspoeng hjelper ikke nødvendigvis mot status, og nivåpoeng hjelper ikke hvis du bare trenger poeng til en reise.

## Hva er et poeng verdt?

Det finnes ingen trygg fastpris per EuroBonus-poeng. Verdien styres av rute, kabinklasse, tilgjengelighet, kampanjer, kortfordeler, skatter, avgifter og hva reisen ville kostet kontant.

En enkel tommelfingerregel er å regne før du bruker poeng: sammenlign poengpris pluss avgifter med realistisk kontantpris for samme reise. Hvis alternativet er en vare eller gavekort, bør du være ekstra kritisk.

## Når EuroBonus passer godt

- Du har et konkret reisemål eller en type reise du faktisk vil ta.
- Du kan samle poeng gjennom kjøp du uansett ville gjort.
- Du er fleksibel på dato, flyplass eller kabinklasse.
- Du sjekker vilkår før du lar kampanjer eller kortfordeler styre valget.

## Vanlige feller

- Å samle poeng uten plan for bruk.
- Å vurdere poeng som kontanter med fast verdi.
- Å glemme skatter, avgifter og begrenset bonussetetilgang.
- Å blande bonuspoeng og nivåpoeng i samme regnestykke.
- Å betale mer for et kjøp bare fordi det gir poeng.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS EuroBonus, SAS medlemsnivåer, SAS bonusreiser, Trumf overføring til EuroBonus og Eurobonusguiden Bonusjegerskolen. Eurobonusguiden er en uoffisiell side og brukes som inspirasjon, ikke som eneste faktakilde.$guide$
      ),
      (
        'Kom i gang med EuroBonus',
        array['Kom i gang med EuroBonus', 'Kom i gang', '2. Kom i gang'],
        '4 min lesing',
        $guide$# Kom i gang med EuroBonus

Målet er å gjøre kontoen klar før du handler eller reiser. Da slipper du å jakte på manglende poeng i etterkant.

## Steg 1: Opprett kontoene

- Opprett eller logg inn på SAS EuroBonus.
- Opprett Trumf hvis du handler hos NorgesGruppen eller vil kunne overføre Trumf-bonus til EuroBonus.
- Opprett ViaTrumf hvis du vil bruke netthandelsopptjening via Trumf.
- Opprett konto hos kortutsteder hvis du har SAS Amex, SAS Mastercard eller annet kort knyttet til EuroBonus.

Ikke opprett kredittkort bare for poeng før du har regnet på årsavgift, rentekostnad, omsetningskrav og egen betalingsevne.

## Steg 2: Last ned appene du faktisk trenger

For de fleste holder det å ha SAS-appen, Trumf-appen og eventuelt ViaTrumf eller kortappen. Bruk appene til å sjekke medlemsnummer, aktivere tilbud, kontrollere saldo og se om kjøp har blitt registrert.

## Steg 3: Koble kort og kontoer

Registrer betalingskort der opptjeningen krever det. For Trumf betyr dette at kort og kontonummer bør være lagt inn på Trumf-profilen. For EuroBonus-partnere kan det være nødvendig å starte kjøpet via riktig portal eller oppgi EuroBonus-nummer før betaling.

Hvis du bruker Trumf mot EuroBonus, må du velge om du vil ha engangsoverføring eller automatisk overføring. Automatisk overføring gir flere EuroBonus-poeng per Trumf-krone enn engangsoverføring, men poengene kan ikke flyttes tilbake til Trumf etterpå.

## Steg 4: Sett opp familie eller delt opptjening ved behov

Point Sharing kan være nyttig hvis flere i husstanden samler EuroBonus-poeng mot samme reisemål. Avklar hvem som skal bruke poengene, og hvilke kontoer som skal kobles før dere begynner å samle stort.

Barn kan også ha egen EuroBonus-konto. For barn bør e-post, innlogging og senere overtakelse av kontoen planlegges ryddig.

## Sjekkliste før første kjøp

- Jeg vet hvilket EuroBonus-nummer som skal brukes.
- Trumf-kort, bankkort og kontonummer er koblet der det er relevant.
- Jeg har valgt Trumf-overføring bare hvis jeg faktisk vil flytte verdien til EuroBonus.
- Jeg vet om kjøpet må starte i SAS Online Shopping, ViaTrumf eller en annen partnerportal.
- Jeg har aktivert kampanjer som krever aktivering.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS EuroBonus, SAS partnere, Trumf overføring til EuroBonus, Trumf profilflyt og Eurobonusguiden sin Kom i gang-guide. Eurobonusguiden er uoffisiell og enkelte praktiske tips må sjekkes manuelt før de brukes som harde regler.$guide$
      ),
      (
        'Kredittkort og EuroBonus',
        array['Kredittkort og EuroBonus', 'Kredittkort', '3. Kredittkort'],
        '5 min lesing',
        $guide$# Kredittkort og EuroBonus

Kredittkort kan gi rask EuroBonus-opptjening, men de kan også gjøre poengjakten dyr. Start med økonomien, ikke med poengene.

## Før du velger kort

- Betal alltid hele fakturaen ved forfall.
- Regn på årsavgift eller månedspris.
- Sjekk hvor mange poeng du faktisk får per 100 kroner.
- Les hvilke transaksjoner som ikke gir poeng.
- Vurder om kortet gir fordeler du faktisk bruker, som Companion Ticket, Fly Premium, reiseforsikring eller nivåpoeng.

Hvis du må bruke mer penger enn normalt for å nå en bonus, er kortet sannsynligvis feil verktøy.

## Dobbeldipping

Dobbeldipping betyr at samme kjøp gir poeng i flere ledd. Et typisk eksempel er å starte et nettkjøp via en partnerportal og betale med et kort som også gir EuroBonus-poeng.

Dette virker bare når vilkårene passer. Rabattkoder, gavekort, feil portal, feil betalingsmiddel eller blokkert sporing kan gjøre at bonusen ikke registreres.

## Companion Ticket og Fly Premium

Companion Ticket og Fly Premium kan gi høy verdi når de brukes på riktige bonusreiser. Verdien er størst når du finner ledige seter på reiser som ellers ville kostet mye kontant.

Samtidig krever fordelene ofte korttype, omsetning og planlegging. Ikke legg opp forbruk bare for å nå en kupong hvis du ikke har en realistisk reiseplan.

## Korttypene i korte trekk

SAS Amex-kort kan være aktuelle for høy opptjening og Companion Ticket. SAS EuroBonus Mastercard kan være aktuelt for bredere aksept og Fly Premium. Andre kort kan passe bedre hvis du prioriterer lavere kostnad, fleksibilitet eller andre fordeler.

Sjekk alltid dagens priser, renter, poengopptjening og vilkår hos kortutsteder før du søker.

## Når kort er verdt å vurdere

- Du har stabil økonomi og betaler fakturaen i tide.
- Du kan oppnå fordeler gjennom ordinært forbruk.
- Kortavgiften er lavere enn verdien du realistisk får ut.
- Du forstår hvilke kjøp som teller mot poeng, nivåpoeng og omsetningskrav.

## Vanlige feller

- Å betale renter for å tjene poeng.
- Å overdrive verdien av velkomstbonus uten å lese kravene.
- Å bruke kort der gebyrer eller valutapåslag spiser opp poengene.
- Å anta at alle transaksjoner teller.
- Å skaffe flere kort enn du klarer å følge opp.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS sin oversikt over EuroBonus-betalingskort i Norge, relevante kortutsteder-sider og Eurobonusguiden sin kredittkortguide. Kortvilkår endres ofte og finansielle produkter skal alltid kontrolleres mot utsteder før publisering eller anbefaling.$guide$
      ),
      (
        'Opptjening av EuroBonus-poeng',
        array['Opptjening av EuroBonus-poeng', 'Opptjening av bonuspoeng', 'Opptjening av poeng', '4. Opptjening av poeng', '4. Opptjening av bonuspoeng'],
        '5 min lesing',
        $guide$# Opptjening av EuroBonus-poeng

EuroBonus-opptjening bør bygges rundt kjøp du allerede skal gjøre. Poeng er en bonus på riktig handel, ikke en grunn til å handle mer.

## De viktigste kanalene

- Flyreiser med SAS og kvalifiserende partnerreiser.
- Hotell, leiebil og andre SAS-partnere.
- SAS Online Shopping og andre partnerportaler.
- Trumf og eventuell overføring til EuroBonus.
- Kredittkort som gir EuroBonus-poeng.
- Kampanjer med ekstra poeng hos partnere.

## Flyreiser

På kvalifiserende flyreiser kan du tjene både bonuspoeng og nivåpoeng. Antall poeng avhenger av flyselskap, rute, billettype, bookingklasse, medlemsnivå og om reisen er markedsført eller operert av SAS eller partner.

Legg inn riktig EuroBonus-nummer før reisen. Hvis reisen allerede er koblet til et annet lojalitetsprogram, kan det være vanskeligere å rette opp i etterkant.

## Trumf og hverdagskjøp

Trumf kan være en enkel vei til EuroBonus for norske brukere som handler hos NorgesGruppen. Engangsoverføring og automatisk overføring gir ulik poengrate. Automatisk overføring kan gi mer EuroBonus per Trumf-krone, men gjør også verdien mindre fleksibel fordi den flyttes ut av Trumf.

Bruk dette bare når du faktisk vil samle EuroBonus-poeng. Hvis du heller vil ha kontantnær bonus, kan Trumf-saldoen være mer fleksibel.

## Netthandel og portaler

Start alltid i riktig portal når vilkårene krever det. Ikke legg varer i handlekurven først hvis portalen krever at hele kjøpsreisen spores fra start.

Sjekk også om kategorier, gavekort, abonnementer, rabattkoder eller bedriftskjøp er unntatt.

## Kampanjer

Kampanjer kan gi mye ekstra, men de må være en bonus på et planlagt kjøp. Se spesielt etter:

- registreringskrav
- frist
- minimumsbeløp
- krav til portal eller lenke
- når poengene faktisk overføres
- om kampanjen er målrettet eller personlig

## Poengjeger-regelen

Før du handler: søk opp butikken eller kategorien, velg beste dokumenterte opptjeningsvei, start i riktig portal og ta vare på kvitteringen til poengene er registrert.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS EuroBonus-partnere, SAS flyopptjening, Trumf overføring til EuroBonus og Eurobonusguiden sin opptjeningsguide. Konkrete satser må alltid kontrolleres på aktuell partner- eller kampanjeside før publisering.$guide$
      ),
      (
        'Poengstrategi for EuroBonus',
        array['Poengstrategi for EuroBonus', 'Poengstrategi', 'Poeng strategi', '5. Poengstrategi', '5. Poeng strategi'],
        '4 min lesing',
        $guide$# Poengstrategi for EuroBonus

En god EuroBonus-strategi starter med målet. Deretter velger du opptjening som passer hverdagen din, økonomien din og reisene du faktisk vil ta.

## Start med målet

Velg ett konkret mål først: innenlandsreise, helgetur, familietur, Business Class, oppgradering eller status. Målet bestemmer hvor mange poeng du trenger, hvor fleksibel du må være og hvilke kampanjer som er verdt tiden.

Uten mål er det lett å ende med mange små poengkilder som aldri blir til en nyttig reise.

## Lag et poengkart

Skriv ned hvor du allerede bruker penger:

- dagligvarer
- netthandel
- flyreiser
- hotell
- leiebil
- abonnementer
- store planlagte kjøp
- betalingskort

Deretter kobler du hvert område til riktig opptjeningsvei. Målet er å samle eksisterende kjøp smartere, ikke å øke forbruket.

## Prioriter lav friksjon

Start med de grepene som ikke endrer handlemønsteret ditt: registrerte kort, riktig medlemsnummer, aktiverte tilbud, partnerportaler og varsler for relevante kampanjer.

Først etterpå bør du vurdere dyrere eller mer krevende grep som nye kort, høyere omsetningskrav eller reisevalg som påvirker pris og fleksibilitet.

## Kampanjestrategi

Følg kampanjer, men ikke la dem styre alt. De beste kampanjene treffer et kjøp du allerede planla, har tydelige vilkår og kan brukes uten stor risiko for feilsporing.

Personlige kortkampanjer, doble poeng-helger og partnerkampanjer bør lagres med frist og krav. Hvis du ikke vet når poengene kommer eller hva som er unntatt, bør kampanjen stå på vent.

## Årlig gjennomgang

Gå gjennom kort, abonnementer, bonusprogrammer og partnerbruk minst én gang i året. Kortvilkår, årsavgifter, partnere og poengsatser endres. En strategi som var god i fjor kan være svak i år.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS EuroBonus, SAS partner- og tilbudssider, Trumf overføring til EuroBonus og Eurobonusguiden sin poengstrategi-guide. Strategiråd er redaksjonelle vurderinger og må ikke presenteres som garantert verdi.$guide$
      ),
      (
        'Bonustips for EuroBonus',
        array['Bonustips for EuroBonus', 'Bonustips', '6. Bonustips'],
        '4 min lesing',
        $guide$# Bonustips for EuroBonus

Dette er små grep som kan gjøre EuroBonus enklere å bruke i praksis. Bruk dem som sjekkliste, ikke som grunn til å kjøpe noe du ikke trenger.

## Før reisen

- Sjekk bonusseter tidlig og vær fleksibel på datoer.
- Sammenlign poengpris, avgifter og kontantpris før du booker.
- Se om nærliggende flyplasser eller andre datoer gir bedre tilgjengelighet.
- Kontroller bagasje, endringsregler og kanselleringsregler før du bruker poeng.

## Underveis

Legg inn EuroBonus-nummer ved booking eller innsjekk. Ta vare på boardingkort, bookingreferanse og kvitteringer til poengene er registrert.

Hvis poeng mangler, bruk SAS sin flyt for etterregistrering der det er mulig. Vent ikke så lenge at dokumentasjon blir vanskelig å finne.

## Hverdagsgrep

- Aktiver relevante kampanjer før kjøp.
- Bruk riktig portal for netthandel.
- Hold Trumf, kort og EuroBonus-kontoer ryddig koblet.
- Ikke bruk rabattkoder hvis vilkårene sier at de kan stoppe bonus.
- Sjekk om poeng har utløpsdato og planlegg bruk i tide.

## Reisehacks med forbehold

Verktøy for bonussetesøk, kalenderoversikt og ruteplanlegging kan spare tid, men de bør bare brukes som hjelpemidler. Den endelige prisen, tilgjengeligheten og vilkårene må sjekkes hos SAS eller partner før du tar beslutningen.

Tips om eSIM, kompensasjon, hotellstatus eller tredjepartstjenester kan være nyttige på reise, men de er ikke EuroBonus-verdi i seg selv. Skill reisetips fra poengopptjening.

## Når du bør stoppe opp

- Fordelen krever kredittkortgjeld eller høyere forbruk.
- Du må handle hos en dyrere butikk for å få poeng.
- Kampanjen har uklar frist eller uklare unntak.
- Du finner ikke offisiell kilde.
- Du må dele mer persondata enn formålet tilsier.

## Kilder og kontroll

Kontrollert 2026-09-05 mot SAS EuroBonus, SAS bonusreiseinformasjon, SAS partnerinformasjon, Trumf overføring til EuroBonus og Eurobonusguiden sin bonustips-guide. Eksterne reiseverktøy, annonser og affiliateforslag er ikke redaksjonelt anbefalt uten separat kontroll.$guide$
      )
  ),
  updated as (
    update public.program_guides guide
    set
      title = guide_data.title,
      status = 'published',
      intro_text = left(regexp_replace(guide_data.body_markdown, '^# [^\n]+\n+', ''), 280),
      body_markdown = guide_data.body_markdown,
      strategy = guide_data.body_markdown,
      value_estimate_label = null,
      value_estimate_detail = null,
      expiration_summary = null,
      expiration_detail = null,
      guide_kicker = 'EUROBONUS',
      reading_time_label = guide_data.reading_time_label,
      strategy_section_title = null,
      decision_section_title = null,
      earning_decision_label = null,
      redemption_decision_label = null,
      risk_decision_label = null,
      earning_section_title = null,
      earning_section_intro = null,
      redemption_section_title = null,
      redemption_section_intro = null,
      risk_section_title = null,
      risk_section_intro = null,
      campaigns_section_title = null,
      campaigns_section_intro = null,
      earning_tips = '{}',
      redemption_tips = '{}',
      risk_notes = '{}',
      last_reviewed_at = '2026-09-05T00:00:00Z'
    from guide_data
    where guide.program_id = v_program_id
      and exists (
        select 1
        from unnest(guide_data.title_aliases) as alias(title)
        where lower(trim(guide.title)) = lower(trim(alias.title))
      )
    returning guide.title
  )
  insert into public.program_guides (
    program_id,
    title,
    status,
    intro_text,
    body_markdown,
    strategy,
    guide_kicker,
    reading_time_label,
    earning_tips,
    redemption_tips,
    risk_notes,
    last_reviewed_at
  )
  select
    v_program_id,
    guide_data.title,
    'published',
    left(regexp_replace(guide_data.body_markdown, '^# [^\n]+\n+', ''), 280),
    guide_data.body_markdown,
    guide_data.body_markdown,
    'EUROBONUS',
    guide_data.reading_time_label,
    '{}',
    '{}',
    '{}',
    '2026-09-05T00:00:00Z'
  from guide_data
  where not exists (
    select 1
    from public.program_guides guide
    where guide.program_id = v_program_id
      and exists (
        select 1
        from unnest(guide_data.title_aliases) as alias(title)
        where lower(trim(guide.title)) = lower(trim(alias.title))
      )
  );
end $$;
