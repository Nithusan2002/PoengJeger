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
9. Publiser kampanjen.
10. Last iOS-appen på nytt og bekreft at kampanjen vises i feeden for riktig program.

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
- Favorittknappen lagrer og fjerner kampanjen lokalt.

## Måling

Registrer for hver testkampanje:

- tid fra kandidat til draft
- tid fra draft til publisert
- om SQL Editor måtte brukes
- antall felter som måtte korrigeres etter iOS-kontroll
- om kampanjen kunne forstås i feeden uten å åpne detaljsiden
