# Poengjeger – Product Brief

## Produktidé

Poengjeger er en mobilapp som samler og prioriterer aktuelle kampanjer for bonus- og lojalitetsprogrammer.

Første produktfase skal konsentreres om:

* EuroBonus
* Trumf

Andre poengsystemer kan vurderes senere, men skal ikke prioriteres før EuroBonus- og Trumf-opplevelsen er forståelig, nyttig og redaksjonelt håndterbar.

Eksempler på senere programmer:

* Spenn
* Norwegian Reward og CashPoints
* Flying Blue
* Avios
* Marriott Bonvoy
* Hilton Honors

Brukeren velger hvilke programmer som er relevante og får en personlig kampanjefeed.

## Problemet

Informasjon om bonuskampanjer er spredt mellom:

* offisielle nettsider
* nyhetsbrev
* banker og kortutstedere
* butikker og nettbutikker
* Facebook-grupper
* forum
* personlige blogger og sosiale medier

Informasjonen kan være ustrukturert, vanskelig å finne og raskt bli utdatert.

## Verdiforslag

Poengjeger skal gjøre det mulig å forstå de viktigste relevante kampanjene på under ett minutt.

Produktet skal ikke bare samle lenker. Det skal:

* filtrere bort irrelevant informasjon
* prioritere kampanjene
* forklare hvorfor en kampanje er interessant
* vise vilkår og utløpsdato tydelig
* varsle brukeren om spesielt relevante muligheter

Tidsbesparelsen og prioriteringen er produktets viktigste verdi.

## Målgruppe

Første målgruppe er norske brukere som allerede samler bonuspoeng, men som ikke ønsker å følge alle tilgjengelige kilder manuelt.

Målgruppen inkluderer både:

* aktive bonusentusiaster
* vanlige brukere som ønsker en enklere oversikt

## Første MVP

MVP-en skal vurderes strengt.

Foreløpig kjerne:

1. Velge relevante bonusprogrammer innen første fase: EuroBonus og Trumf.
2. Se en personlig feed med aktive kampanjer.
3. Åpne en kampanje og lese vilkår, vurdering og kilde.
4. Filtrere kampanjer.
5. Lagre favoritter.
6. Motta et begrenset antall relevante varsler.
7. Lære hvordan EuroBonus- og Trumf-økosystemene fungerer, inkludert opptjening, bruk, vanlige feller og hvordan aktuelle kampanjer passer inn.

Et enkelt administrasjonsverktøy må gjøre det mulig å opprette, kontrollere, oppdatere og arkivere kampanjer.

## Foreløpig ikke i MVP

Disse funksjonene skal ikke bygges uten en ny prioriteringsbeslutning:

* tilkobling til bonuskontoer
* automatisk innhenting av privat saldo
* full reisemotor
* automatisk bestilling
* sosialt nettverk
* omfattende gamification
* avanserte AI-assistenter
* støtte for alle bonusprogrammer ved lansering
* nye bonusprogrammer før EuroBonus og Trumf er validert som første fase

## Innholdsmodell

Kampanjene samles fra offentlig tilgjengelige kilder og kvalitetssikres redaksjonelt.

Hver kampanje må ha:

* identifiserbar kilde
* tidspunkt for siste kontroll
* gyldighetsperiode når tilgjengelig
* tydelige krav
* tilknyttet bonusprogram
* status for publisering og utløp

Redaksjonelle vurderinger må skilles tydelig fra dokumenterte fakta.

## Rangering

Kampanjer kan prioriteres etter faktorer som:

* forventet poengverdi
* kostnad
* tidsbegrensning
* hvor enkelt tilbudet er å bruke
* hvor bredt tilgjengelig tilbudet er
* krav om kredittkort eller nytt kundeforhold
* kvaliteten på dokumentasjonen
* relevans for brukerens valgte programmer

Rangeringen må være forståelig. En stjernerangering alene er ikke tilstrekkelig dersom brukeren ikke får vite hva den representerer.

## Designretning

Designet skal oppleves:

* moderne
* rolig
* premium
* oversiktlig
* troverdig

Informasjon om kampanjer, vilkår og tidsfrister skal være viktigere enn dekorative elementer.

## Teknisk utgangspunkt

* SwiftUI
* iOS først
* Supabase
* PostgreSQL
* push-varsler
* lokal caching når det gir verdi
* mulig Android-støtte senere

Teknologivalgene er utgangspunkt, ikke absolutte krav. Endringer må begrunnes med produktverdi, risiko eller betydelig enklere utvikling.

## Forretningsmodell

Mulige inntektskilder:

* affiliate-lenker
* annonser
* premiumabonnement
* kommersielle samarbeid

Kommersielt innhold skal merkes tydelig og må ikke svekke troverdigheten til rangeringen.

## Suksesskriterier

Tidlige signaler:

* brukere kommer tilbake ukentlig
* brukere åpner kampanjedetaljer
* brukere lagrer eller aktiverer varsler
* brukere opplever at appen sparer tid
* innholdet kan vedlikeholdes uten uforholdsmessig manuelt arbeid

## Viktigste risikoer

* innholdet blir raskt utdatert
* redaksjonelt arbeid blir for omfattende
* brukerne foretrekker gratis forum og grupper
* rangeringene oppleves som vilkårlige
* affiliateinntekter svekker tilliten
* produktet støtter for mange programmer for tidlig
