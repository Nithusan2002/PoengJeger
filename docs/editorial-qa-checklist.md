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

1. Sett status til `needs_review` hvis usikkerheten må undersøkes.
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
