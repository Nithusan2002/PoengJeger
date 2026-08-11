# Notification Strategy

Dette dokumentet avgrenser første varslingsflyt for Poengjeger. Varsler er en MVP-funksjon, men skal holdes enkle og redaksjonelt trygge.

## Prinsipper

- Varsler skal spare brukeren tid, ikke kopiere hele feeden.
- Varsler skal bare sendes etter eksplisitt opt-in.
- Varsler skal aldri sendes for `draft`, `review`, `archived`, `expired` eller `ingestion_candidates`.
- Varsler skal ikke baseres på private bonuskontoer, saldoer eller transaksjoner.
- Redaksjonell kontroll og `last_verified_at` må være på plass før en kampanje kan varsles.

## Første tillatte triggere

- Manuelt valgt fremhevet kampanje for et program brukeren følger.
- Kort frist for en publisert kampanje, når fristen er tydelig dokumentert.
- Høy redaksjonell relevans for et valgt program eller valgt kategori.

## Ikke bygg først

- Sanntidsvarsler for alle nye kandidater.
- Kompleks personlig rangeringsmodell.
- Varsler basert på eksterne private brukerdata.
- Automatisk reaktivering av varsler for arkiverte eller utløpte kampanjer.
- Sponsede push-varsler uten ny produkt- og tillitsvurdering.

## Datakrav

En kampanje kan bare varsles når den har:

- status `published`
- minst én kildehenvisning
- `last_verified_at`
- programtilknytning
- tydelig frist eller eksplisitt løpende status
- redaksjonell begrunnelse for hvorfor varselet er relevant

## Brukervalg

Første modell:

- globalt varselvalg i `user_profiles.notifications_enabled`
- valgfrie abonnementer i `notification_subscriptions` per program eller kategori
- mulighet til å slå av varsler uten å slette programvalg eller favoritter

## Frekvensgrenser

MVP bør ha konservative grenser:

- maksimalt ett kampanjevarsel per bruker per dag
- maksimalt tre kampanjevarsler per bruker per uke
- ingen nattlige varsler
- manuell sperre for kampanjer som ikke skal varsles selv om de er publisert

## Admin- og QA-krav

Før push sendes:

- redaktør bekrefter kilde og frist
- systemet bekrefter at kampanjen fortsatt er `published`
- systemet bekrefter at `end_date` ikke er passert hvis dato finnes
- systemet bekrefter at brukeren har opt-in og relevant abonnement
- QA bekrefter at utkast, kandidater og arkiverte kampanjer ikke kan trigge varsel

## Åpne beslutninger

- Om første sending skal være helt manuell eller regelbasert med manuell godkjenning.
- Hvilken push-leverandør som skal brukes i iOS.
- Om varslingshistorikk skal lagres fra første versjon.
- Hvor gammel `last_verified_at` kan være før kampanjen ikke lenger kan varsles.
