# Design- og brukerflytretning

Dette dokumentet beskriver ønsket produkt- og designretning for Poengjeger før videre UI-implementering. Første produktfase er begrenset til EuroBonus og Trumf.

## Produktløfte

Poengjeger skal hjelpe norske bonusbrukere å sjekke beste opptjeningsvei før de handler, og forstå hvordan EuroBonus- og Trumf-økosystemene fungerer.

Appen skal føles som et rolig beslutningsverktøy for kjøpsøyeblikket, ikke som en nyhetsapp, blogg eller affiliate-katalog.

## Designprinsipper

1. Skannbar før dekorativ.
   Brukeren skal kunne vurdere de viktigste kampanjene raskt, helst på under ett minutt.

2. Fakta og vurdering skal skilles tydelig.
   Kilde, sist kontrollert, krav og vilkår skal ikke blandes med redaksjonell vurdering.

3. Dypde foran bredde.
   EuroBonus og Trumf skal oppleves komplette og nyttige før nye programmer vurderes.

4. Læring skal støtte handling.
   Programguider skal forklare konkrete beslutninger brukeren møter i kampanjer, ikke bli generelle artikler.

5. Varsler skal være sjeldne.
   Push skal bare brukes for tydelig relevante frister eller spesielt gode muligheter.

## Visuell Retning

Appen skal oppleves moderne, rolig, premium, oversiktlig og troverdig.

Retningen bør ligge nær personlig økonomi og profesjonelle reiseverktøy:

- lyse eller systemnøytrale flater
- tydelig typografisk hierarki
- kompakte lister i hovedfeed
- kort kun når innholdet trenger ramme, som guideblokker eller detaljseksjoner
- lite illustrasjon og lite dekor
- tydelige programmarkører for EuroBonus og Trumf

Fargebruk:

- Poengjeger-teal: primær handling og navigasjon
- EuroBonus-blå: EuroBonus-identitet og programmarkør
- Trumf-rød: Trumf-identitet og programmarkør
- amber/gull: frist, lagret eller høy verdi
- rød/oransje: advarsel, høy friksjon eller risiko

Farger skal brukes som signaler, ikke som store dekorflater.

## Navigasjon

Anbefalt tabstruktur:

1. Hjem
   Søk etter butikk eller kategori før kjøp. Dette er hovedfanen.

2. Utforsk
   Sekundær flate for kampanjer, kategorier og bredere sammenligning.

3. Guider
   Strukturerte læringsstier for EuroBonus og Trumf.

4. Profil
   Programvalg, varsler, lagret innhold og senere konto/premium.

Kjernefunksjonen skal fungere uten konto. Profil introduseres når brukeren ønsker lagring, varsler eller personalisering.

## Førstegangsflyt

Målet er å få brukeren raskt til relevant innhold uten å stille for mange spørsmål.

```text
Velkommen
  -> Velg programmer
  -> Velg erfaringsnivå
  -> Nå-feed
```

### Skjerm 1: Velkommen

Formål: sette forventning.

Innhold:

- "Få oversikt over EuroBonus og Trumf"
- kort forklaring: "Se relevante kampanjer, forstå vilkår og lær hvordan programmene fungerer."
- primærknapp: "Kom i gang"

Unngå:

- lang introduksjon
- markedsføringsspråk
- push-permission på første skjerm

### Skjerm 2: Velg Programmer

Brukeren velger:

- EuroBonus
- Trumf
- Begge

Default kan være begge valgt dersom brukeren ikke har sterke preferanser.

Skjermen skal forklare at valget styrer feed, guider og varsler.

### Skjerm 3: Erfaringsnivå

Brukeren velger ett nivå:

- Ny på bonus
- Bruker litt
- Erfaren

I MVP kan dette lagres lokalt og brukes til tone/innhold senere. Hvis det ikke brukes i UI ennå, kan skjermen vente.

## Hovedflyt

```text
Åpne app
  -> Hjem
  -> Søk butikk eller kategori
  -> Åpne butikkside
  -> Se vanlig opptjening, kampanjer og beste kombinasjon
  -> Åpne Slik gjør du det
  -> Start handelen via riktig portal eller destinasjon
```

Appens viktigste gjentatte brukerjobb er:

> Jeg skal handle. Hvor bør jeg starte for å tjene mest relevant EuroBonus eller Trumf?

## Hjem

Hjem skal bygge vanen "sjekk før du handler".

Prioritet:

1. Ett tydelig søkefelt for butikk, kategori eller produkt.
2. Noen få raske butikkforslag når søket er tomt.
3. Direkte søkeresultater når brukeren skriver.

Hjem skal ikke bli en artikkelfeed, abonnementsflate, generell kampanjekatalog
eller bred browse-flate. Kategorier, kampanjer og full butikkoversikt hører
hjemme i Utforsk.

## Butikkside

Butikksiden skal vise informasjon i denne rekkefølgen:

1. Vanlig opptjening.
2. Aktuelle kampanjer.
3. Alle opptjeningsmuligheter.
4. Beste kombinasjon direkte synlig.
5. "Slik gjør du det" med korte steg og direkte handoff.

Kritiske advarsler skal vises før handlingsknappen. Det skal ikke ligge en ekstra bekreftelsesskjerm mellom instruksjonene og ekstern handoff.

## Nå-Feed

Feeden skal være tett og sammenlignbar. Hver rad skal svare på:

- hva får jeg?
- hvilket program gjelder det?
- hvor lenge varer det?
- hvor interessant er det?
- hvor mye friksjon er det?

Wireframe:

```text
Nå
12 aktive · dine programmer                         [søk] [filter]

[Utløper først] [Kategori] [Mine programmer]

3x Trumf-bonus                              3 DAGER IGJEN
Meny helgehandel
Relevant · lav friksjon
TRUMF

1 000 EuroBonus-poeng                         LØPENDE
Hotellpartner-kampanje
Nisjetilbud · middels friksjon
EUROBONUS
```

Radens visuelle anker skal være verdi eller kort mulighetssignal, ikke kampanjetittel alene.

Primære kontroller:

- søk
- programfilter
- kategori
- sortering

Sortering i MVP:

- utløper først
- nyeste
- A-Å

## Kampanjedetalj

Detaljsiden skal være en beslutningsflate, ikke en artikkel.

Wireframe:

```text
[tilbake]                                      [lagre]

3x Trumf-bonus hos Meny
Relevant hvis du handler dagligvarer denne helgen.

[Verdi: 3x bonus] [Frist: 3 dager] [Friksjon: Lav]

Åpne kampanjesiden

Hvorfor interessant
Kort redaksjonell vurdering med tydelig begrunnelse.

Slik fungerer det
Hva brukeren må gjøre.

Viktigste krav
- Krever Trumf-medlemskap
- Gjelder utvalgte datoer
- Eventuelt minimumskjøp

Begrensninger
Risiko, unntak og praktiske haker.

Fakta og kilde
Primærkilde, sist kontrollert, lenke og kildegrunnlag.
```

Prioritet i detaljen:

1. konklusjon
2. verdi, frist og friksjon
3. hva brukeren må gjøre
4. krav og begrensninger
5. kilde og kontrolltidspunkt

## Lær

Lær skal være strukturert, praktisk og tett koblet til kampanjene.

Wireframe:

```text
Lær

EuroBonus
Poeng, status, partnere og hvordan du får mest verdi.
3 aktive kampanjer nå

Trumf
Dagligvarer, partnere, Trumf Visa og overføring til EuroBonus.
5 aktive kampanjer nå
```

Lær skal ikke være:

- blogg
- nyhetsseksjon
- generisk bonusleksikon
- SEO-flate i appen

## Programguide: EuroBonus

EuroBonus-guiden skal forklare økosystemet fra grunnleggende til praktisk bruk.

Wireframe:

```text
EuroBonus
3 aktive kampanjer

Kort forklaring av programmet og når det er nyttig.

[Verdi] [Utløp] [Aktive kampanjer]

Strategi
Hvordan tenke om EuroBonus i praksis.

Slik tjener du poeng
1. Flyreiser
2. Kredittkort
3. Shopping og partnere
4. Hotell og leiebil

Slik får du mest ut av poengene
1. Bonusreiser der kontantprisen er høy
2. Unngå lavverdi-bruk
3. Vurder gebyrer og tilgjengelighet

Vanlige feller
1. Forveksle bonuspoeng og statuspoeng
2. Overse utløp
3. Jakte poeng med høy kostnad

Kampanjer nå
To viktigste kampanjer + se alle
```

EuroBonus-guiden bør forklare:

- bonuspoeng
- statuspoeng og kvalifisering
- SAS og partnerstruktur
- kredittkort og shoppingpartnere
- opptjening kontra innløsning
- hva som ofte er god og dårlig verdi
- hvordan aktuelle kampanjer passer inn

## Programguide: Trumf

Trumf-guiden skal forklare hverdagsøkonomien og koblingen til EuroBonus.

Wireframe:

```text
Trumf
5 aktive kampanjer

Kort forklaring av Trumf og når det er mest nyttig.

[Verdi] [Utløp] [Aktive kampanjer]

Strategi
Hvordan bruke Trumf uten å la bonus styre dårlige kjøp.

Slik tjener du Trumf
1. Dagligvarer
2. Trumf-partnere
3. Trumf Visa
4. Netthandel

Slik får du mest ut av bonusen
1. Bruk som kontantbonus
2. Vurder overføring til EuroBonus
3. Sammenlign faktisk pris, ikke bare bonusprosent

Vanlige feller
1. Handle dyrere for bonus
2. Overse kampanjevilkår
3. Forveksle ekstra bonus med total verdi

Kampanjer nå
To viktigste kampanjer + se alle
```

## Kobling Mellom Kampanjer og Læring

Fra kampanjedetalj:

- "Hvordan fungerer EuroBonus-poeng?"
- "Hva betyr lav friksjon?"
- "Når er Trumf bedre enn EuroBonus?"

Fra programguide:

- "Aktive kampanjer nå"
- "Se alle EuroBonus-kampanjer"
- "Se alle Trumf-kampanjer"

Denne koblingen er viktigere enn en stor Lær-startside. Læring skal dukke opp når brukeren trenger den.

## Lagret

Lagret skal i MVP primært inneholde kampanjer.

Senere kan det utvides til:

- lagrede guidepunkter
- påminnelser
- kampanjer brukeren har brukt

MVP-wireframe:

```text
Lagret

3x Trumf-bonus
Meny helgehandel
3 dager igjen

1 000 EuroBonus-poeng
Hotellpartner-kampanje
Løpende
```

## Profil

Profil skal være lavmælt og praktisk.

Innhold:

- valgte programmer
- varselinnstillinger
- datakilde/status ved behov
- personvern-/kildeinformasjon senere

Profil skal ikke bli en konto- eller medlemskapsflate i MVP.

## MVP-Klassifisering

Må ha:

- Nå-feed for EuroBonus og Trumf
- kampanjedetalj med verdi, krav, frist, vurdering og kilde
- programvalg
- favoritter
- EuroBonus-guide
- Trumf-guide

Burde ha:

- begrensede varsler
- "minn meg på frist"
- erfaringsnivå i onboarding hvis det faktisk brukes

Kan vente:

- flere programmer
- kalkulatorer
- avansert personalisering
- lagrede guidepunkter
- konto eller saldo

Ikke bygg i MVP:

- sosial feed
- blogg/nyhetsflate
- automatisk booking
- automatisk saldoinnhenting
- bred programkatalog

## Suksessindikatorer

Tidlige indikatorer:

- brukere åpner kampanjedetaljer fra Nå-feed
- brukere lagrer kampanjer
- brukere åpner EuroBonus- og Trumf-guidene
- brukere går fra kampanjedetalj til relevant guide
- brukere kommer tilbake ukentlig
- redaksjonen klarer å holde EuroBonus og Trumf oppdatert uten uforholdsmessig manuelt arbeid

## Neste Tekniske Oppgave

Neste UI-oppgave bør være å justere eksisterende SwiftUI-struktur mot denne retningen:

1. Vurdere om fanen "Kampanjer" skal endres til "Nå".
2. Stramme onboarding til EuroBonus og Trumf.
3. Sikre at Lær-starten bare viser EuroBonus og Trumf i første fase.
4. Gjøre kampanjedetaljens første skjerm enda mer beslutningsorientert.
5. Koble kampanjedetalj tydeligere til relevant programguide.
