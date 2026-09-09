# Redaksjonell QA-sjekkliste

Bruk denne sjekklisten for den komplette adminflyten før nye kilder, varsler eller bredere programstøtte bygges.

## Formål

Verifiser at redaksjonen kan gå fra kandidat til publisert kampanje uten SQL Editor, og at sluttbrukerappen viser bare kvalitetssikret, aktivt innhold.

## Representative kampanjer

Test minst fem kampanjer:

- Trumf Netthandel med tydelig prosentsats og kilde.
- SAS EuroBonus eller tilsvarende programkampanje med poengverdi.
- Kampanje uten kjent sluttdato.
- Kampanje med kort frist, helst under tre dager.
- Kampanje som skal avvises på grunn av uklare vilkår, mulig duplikat eller lav kildekvalitet.

## Golden path

For hver publiserbar kampanje:

1. Kjør innhenting eller opprett kandidat i `ingestion_candidates`.
2. Åpne kandidaten i adminverktøyet.
3. Kontroller kilde-URL, kildebevis og oppdaget tidspunkt.
4. Sett riktig program, kategori og review-notat.
5. Promoter kandidaten til `draft`.
6. Rediger tittel, sammendrag, detaljer og krav.
7. Registrer minst en kildehenvisning og `last_verified_at`.
8. Legg inn redaksjonell vurdering som tydelig skiller fakta fra vurdering.
9. Sett beslutning, kort konklusjon, hvem kampanjen passer for og eventuelt hvem den ikke passer for.
10. Publiser kampanjen.
11. Last iOS-appen på nytt og bekreft at kampanjen vises i feeden for riktig program.

## Avvisningsflyt

For kampanjen som ikke skal publiseres:

1. La kandidaten stå som `new` hvis usikkerheten må undersøkes senere.
2. Sett status til `rejected` når avvisningsgrunn er bekreftet.
3. Skriv review-notat som forklarer om problemet er kilde, vilkår, duplikat, målretting eller lav relevans.
4. Bekreft at kandidaten ikke kan dukke opp i iOS-feeden.

## Publiseringskontroll

En publisert kampanje skal ha:

- identifiserbar kilde
- `last_verified_at`
- tydelig gyldighetsperiode eller eksplisitt løpende status
- minst ett krav eller en tydelig forklaring på hvorfor krav ikke er kjent
- programtilknytning
- redaksjonell beslutning og kort konklusjon
- redaksjonell begrunnelse
- ingen kommersiell merking skjult i vurderingsteksten

## iOS-kontroll

Bekreft i appen:

- Feed viser bare `published`, aktive og ikke-utløpte kampanjer.
- Programfilter skjuler kampanjer utenfor valgte programmer.
- "Alle programmer" viser publiserte kampanjer på tvers av aktive programmer.
- Søk finner tekst i tittel, sammendrag og redaksjonelt sammendrag.
- Kategori-filter viser bare valgt kategori.
- Kampanjedetalj viser kilde, kontrolltidspunkt, krav og redaksjonell vurdering.
- Kampanjedetalj viser kort konklusjon og hvem kampanjen passer for uten at brukeren må åpne kilde-/detaljseksjonen.
- Favorittknappen lagrer og fjerner kampanjen lokalt.

## Måling

Registrer for hver testkampanje:

- tid fra kandidat til draft
- tid fra draft til publisert
- om SQL Editor måtte brukes
- antall felter som måtte korrigeres etter iOS-kontroll
- om kampanjen kunne forstås i feeden uten å åpne detaljsiden

## QA-logg

### 2026-08-17 lokal admin- og feedkontroll

Omfang:

- Lokal Supabase mot `http://127.0.0.1:54321`.
- Fem representative QA-kandidater merket med `metadata.qa_run = editorial-five-campaigns-2026-08-16`.
- Fire kandidater promotert til draft og publisert.
- En kandidat avvist på grunn av uklar kilde, uklare vilkår og mulig målretting.
- Adminverktøyet ble åpnet lokalt i browser og viste fem kandidater i køen og fire publiserte kampanjer.
- Feed-API med publishable key returnerte de fire publiserte QA-kampanjene og ikke den avviste kandidaten.
- `PoengjegerTests/ScannableFeedUseCaseTests` passerte på `iPhone 16 Pro, iOS 18.6`.

Resultat:

- Redaksjonell flyt fungerer lokalt fra kandidat til publisert kampanje via samme RPC-er som adminverktøyet bruker.
- Publiserte QA-kampanjer hadde programkobling, kilde, krav, `last_verified_at` og redaksjonell vurdering.
- Kort-frist-kampanjen hadde `end_date = 2026-08-18`.

Begrensninger:

- Dette var lokal QA, ikke staging eller produksjon.
- QA-data ble opprettet direkte med SQL/RPC-er og deretter kontrollert i adminverktøyet; alle klikk for manuell redigering ble ikke gjennomført i browser.
- Lokal QA-data står igjen for videre visuell kontroll med mindre den ryddes manuelt.

Se også `docs/local-admin-qa.md`.

### 2026-09-09 delvis pilot mot konfigurert backend

Omfang:

- iOS-appen ble bygget og startet på iPhone 17 Pro-simulator med iOS 26.5.
- `ScannableFeedUseCaseTests`, `StoreEarningUseCaseTests` og
  `AdminIngestionUseCaseTests` passerte.
- `scripts/smoke-ios-supabase.mjs` returnerte `200 OK` for programmer, guider,
  kampanjer og butikker mot den konfigurerte Supabase-backenden.
- Hjem, kategorisøk etter elektronikk, butikkside, «Slik gjør du det»,
  Poengnytt og kampanjedetalj ble kontrollert manuelt.
- Mørk modus og Dynamic Type på `accessibility-extra-large` ble kontrollert.
- Adminverktøyets innloggingsflate lastet korrekt fra en separat lokal server.

Funn:

- Telia vises med «Din beste opptjeningsvei», men «Slik gjør du det» viser
  «Stegene mangler». En opptjeningskombinasjon uten bekreftede handlingssteg bør
  ikke presenteres som en komplett beste vei.
- Ved `accessibility-extra-large` blir mye av første Poengnytt-kort skjult bak
  tabbaren. Kampanjedetaljen krever også ny kontroll av scrolling og tilgang til
  innholdet nederst på skjermen.

Begrensninger:

- Full kandidat → draft → publisering ble ikke kjørt. Lokal Supabase-stack og
  CLI var ikke tilgjengelig, mens adminverktøyet var konfigurert mot et eksternt
  prosjekt som ikke var eksplisitt klassifisert som staging.
- Ingen eksterne data ble opprettet, endret eller slettet i denne kontrollen.
- Visuell kontroll ble gjort på iOS 26.5, ikke prosjektets dokumenterte iOS
  18.6-referansesimulator.

Oppfølging samme dag:

- Publiserte kombinasjoner uten bekreftede handlingssteg filtreres nå ut som
  ufullstendige. Telia viser dokumentert opptjening og forklarer at ingen trygg
  kombinasjon er bekreftet, uten å tilby en misvisende «Slik gjør du det»-flyt.
- Poengnytt-kortet bryter metadata og informasjonsbrikker over flere linjer ved
  behov, og sammendraget forkortes ikke ved tilgjengelighetsstørrelser.
- Ny domenetest dekker kombinasjoner uten handlingssteg. De målrettede
  `StoreEarningUseCaseTests`- og `ScannableFeedUseCaseTests`-suitene passerte.

### 2026-09-09 lokal ende-til-ende-pilot

Omfang:

- Lokal Supabase-stack, lokalt adminverktøy og iPhone 17 Pro-simulator med iOS
  26.5. Produksjonsprosjektet ble ikke endret.
- Fem representative kandidater merket med
  `metadata.qa_run = editorial-five-campaigns-2026-09-09` ble behandlet manuelt
  i adminverktøyet.
- Tre kampanjer ble publisert, én ble beholdt som draft og én ble avvist med
  begrunnelse.
- Lokal feed-smoke returnerte `200 OK` for programmer, guider, kampanjer og
  butikker.

Resultat:

- Poengnytt viste de tre publiserte QA-kampanjene: «5 % Trumf-bonus»,
  «3 000 EuroBonus-poeng» og «Løpende Trumf-fordel».
- Kampanjen «Dobbel EuroBonus i 48 timer» ble korrekt skjult fordi den fortsatt
  var draft. Den avviste kandidaten «Uklar målrettet bonus» var heller ikke
  synlig i appen.
- Kandidatkøen endte med fire promoterte kandidater og én avvist kandidat.
- `git diff --check`, `ScannableFeedUseCaseTests` og
  `StoreEarningUseCaseTests` passerte.

Oppfølging og fullføring:

- Adminskjemaet og den atomiske lagringsflyten fikk valgfrie felt for
  `start_date` og `end_date`, med validering av at sluttdato ikke er før
  startdato både i klienten og databasen.
- 48-timerskampanjen ble publisert gjennom adminflaten med periode fra
  9. september 2026 kl. 16:00 til 11. september 2026 kl. 16:00.
- Poengnytt viste deretter alle fire publiserte QA-kampanjer. 48-timerskampanjen
  ble prioritert som «Siste sjanse» med «2 dager igjen», mens den avviste
  kandidaten fortsatt ikke var synlig.
- Databasekontrollen avviste både omvendt datoperiode og en innlogget bruker
  uten redaksjonell rolle. Den lokale feed-smoken passerte etter publisering.
- App- og smoke-konfigurasjonen tillater nå ukryptert HTTP bare mot loopback
  (`localhost`, `127.0.0.1` og `::1`). Eksterne endepunkter krever fortsatt
  HTTPS.
