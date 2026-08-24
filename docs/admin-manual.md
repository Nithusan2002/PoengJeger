# Poengjeger Adminmanual

Denne manualen forklarer den daglige adminflyten for staging/admin-MVP.
Adminflaten brukes til å hente kandidater, kontrollere innhold og publisere
kampanjer, butikker, opptjeningssatser og programguider.

## Grunnregler

- Publiser bare innhold som har identifiserbar kilde og kontrolltidspunkt.
- Ikke gjett manglende verdi, dato, vilkår eller begrensninger.
- Bruk `draft` når noe er opprettet, men ikke ferdig kontrollert.
- Bruk `published` bare når innholdet kan vises i appen.
- Bruk `archived` når noe ikke lenger skal vises eller vedlikeholdes.
- Service-role keys, OpenAI-nøkler og andre hemmeligheter skal aldri inn i
  adminflaten eller browseren.

## Logg Inn

1. Åpne admin-URL-en.
2. Logg inn med Supabase Auth-brukeren din.
3. Kontroller at session-pill viser `ADMIN` eller `EDITOR`.

Hvis du får tilgangsfeil, mangler brukeren rolle i `editorial_user_roles`.

## Hent Nye Kandidater

Øverst ligger `Dagens jobb`. Bruk den som startpunkt:

1. Trykk `Hent 10 nye` for å hente en liten batch fra valgt kilde.
2. Trykk `Nye funn`, `Butikk-drafts` eller `Kampanje-drafts` for å hoppe rett
   til det som må behandles.

For manuell henting i køfanen:

1. Gå til fanen `Kø`.
2. Velg kilde:
   - `SAS EuroBonus Shopping`
   - `Trumf Netthandel`
3. Velg lav `Limit`, for eksempel `10`.
4. Trykk `Hent nye kandidater`.
5. Se gjennom kandidatene før promotering.

Køen åpner som standard på status `Ny`, slik at du starter på ubehandlede funn.
Bytt til `Alle` bare når du skal finne gamle, avviste eller promoterte rader.

Kandidater er ikke publisert innhold. De er funn som må vurderes.

## Kandidatkø

Bruk `Kø` til å bestemme hva et funn skal bli.

Vanlige valg:

- `Sett til needs_review`: bruk når funnet trenger mer manuell kontroll.
- `Godkjenn`: bruk når funnet ser relevant ut, men ikke nødvendigvis skal
  publiseres ennå.
- `Avvis`: bruk for irrelevante, dupliserte eller uklare funn.
- `Promoter til draft`: bruk for ordinære kampanjer.
- `Promoter til butikkopptjening`: bruk for SAS/Trumf-butikkrater.

For SAS/Trumf-butikkfunn bør du vanligvis promotere til butikkopptjening, ikke
kampanje, med mindre funnet faktisk er en tidsbegrenset kampanje med egne vilkår.

Når du promoterer til butikkopptjening, åpner adminflaten automatisk den nye
draften i `Butikker`. Da kan du kontrollere og publisere uten å lete etter raden.

## Butikkopptjening

Gå til `Butikker` for å kontrollere og publisere butikkrater.

Butikkfanen åpner som standard på `Draft`, altså nye rader som må behandles.

Hver sats får en review-status:

- `Klar`: blokkerende felt er på plass.
- `Bør sjekkes`: kan publiseres, men har gule kontrollpunkter.
- `Mangler`: kan ikke publiseres før røde mangler er løst.

Blokkerende felt:

- Butikknavn
- Opptjeningsmetode
- Rate-label
- Kilde-URL med `https://`
- Kontrolltidspunkt

Gule kontrollpunkter:

- Manglende handoff-URL
- Manglende kravtekst
- Tekst med `opptil`
- Kampanjetekst eller manglende sluttdato
- Intern advarsel om at raden må kontrolleres

## Publiser Butikkopptjening

1. Åpne en `Draft`-sats i `Butikker`.
2. Kontroller butikk, metode, sats, kilde og handoff.
3. Fjern eller omskriv intern advarsel hvis raden er ferdig kontrollert.
4. Sett kontrolltidspunkt hvis det mangler.
5. Trykk `Publiser kontrollert` hvis du bare vil publisere raden, eller
   `Publiser og neste draft` hvis du vil fortsette direkte til neste utkast.

Publisering setter både butikken og satsen til `published`. Etter publisering
kan innholdet vises i iOS-appen.

## Kampanjer

Gå til `Kampanjer` for redigering av kampanjeutkast.

Kampanjefanen åpner som standard på `Draft`, slik at du ser upubliserte
kampanjeutkast først.

Før publisering må kampanjen ha:

- Tittel
- Kort beskrivelse
- Detaljtekst
- Bonusprogram
- Kilde
- Sist verifisert
- Beslutningslabel
- Kort konklusjon
- Redaksjonell begrunnelse

Bruk `Foreslå med AI` som et skrivehjelpemiddel, ikke som fasit. Kontroller alltid
tekst, vilkår og kilde før publisering.

## Programguider

Gå til `Lær` for å vedlikeholde programguider.

Før publisering bør guiden ha:

- Intro
- Strategitekst
- Verdi-kort
- Utløp-kort
- Minst ett opptjeningstips
- Minst ett brukstips
- Minst ett risikonotat
- Sist redaksjonelt kontrollert

Programguider vises i appens Lær-opplevelse når de er `published`.

## Etter Publisering

Etter at du publiserer kampanje eller butikkopptjening:

1. Kjør iOS-appen mot samme Supabase-miljø.
2. Force quit appen hvis gammel data eller feilmelding henger igjen.
3. Kontroller at innholdet vises med riktig tekst og lenker.
4. Ved Supabase-feil, kjør:

```bash
node scripts/smoke-ios-supabase.mjs
```

Smoke-testen sjekker at iOS sine Supabase-queryer fortsatt fungerer mot miljøet.

## Når Du Skal Stoppe

Ikke publiser videre før du har kontrollert manuelt hvis:

- Kilden mangler eller ikke er offisiell.
- Satsen sier `opptil` uten tydelig forklaring.
- Sluttdato eller kampanjeperiode er uklar.
- Tilbudet kan være målrettet.
- Det kan være duplikat av eksisterende butikk eller kampanje.
- Handoff-lenken ikke peker til riktig portal.
- Innholdet gjelder finansielle produkter eller nye kundeforhold.

Bruk heller `needs_review`, `draft` eller `rejected` enn å publisere usikkert
innhold.
