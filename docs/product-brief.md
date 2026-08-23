# Poengjeger – Product Brief

## Produktidé

Poengjeger er en mobilapp som hjelper norske bonusbrukere å sjekke hvordan de kan tjene mest mulig relevante poeng før de handler.

Produktets viktigste vane er:

> Sjekk før du handler.

Kjerneflyten er:

1. Brukeren skal kjøpe noe.
2. Brukeren søker etter butikk eller kategori i Poengjeger.
3. Appen viser vanlig opptjening, aktive kampanjer og relevante opptjeningsmekanismer.
4. Appen viser beste redaksjonelt kvalitetssikrede kombinasjon.
5. Brukeren får korte steg og sendes videre til riktig portal eller destinasjon.

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

Poengjeger skal gjøre det mulig å forstå den beste relevante opptjeningsveien før et kjøp på under ett minutt.

Produktet skal ikke bare samle lenker. Det skal:

* vise grunnopptjening hos butikker og partnere
* filtrere bort irrelevant informasjon
* prioritere kampanjer og opptjeningsmekanismer
* forklare hvorfor en kombinasjon er interessant
* vise vilkår og utløpsdato tydelig
* vise hvordan brukeren faktisk starter handelen riktig
* varsle brukeren om spesielt relevante muligheter

Tidsbesparelsen, trygg handoff og prioriteringen er produktets viktigste verdi.

## Målgruppe

Første målgruppe er norske brukere som allerede samler bonuspoeng, men som ikke ønsker å følge alle tilgjengelige kilder manuelt.

Målgruppen inkluderer både:

* aktive bonusentusiaster
* vanlige brukere som ønsker en enklere oversikt

## Første MVP

MVP-en skal vurderes strengt.

Foreløpig kjerne:

1. Velge relevante bonusprogrammer innen første fase: EuroBonus og Trumf.
2. Søke etter butikker og kategorier før kjøp.
3. Åpne en butikkside og se vanlig opptjening først.
4. Se aktive kampanjer og alle relevante opptjeningsmekanismer.
5. Se beste kombinasjon direkte på butikksiden.
6. Åpne "Slik gjør du det" og følge korte steg før direkte handoff.
7. Se en begrenset "Populært akkurat nå"-flate for aktuelle muligheter.
8. Lære hvordan EuroBonus- og Trumf-økosystemene fungerer gjennom praktiske guider.
9. Lagre favoritter og senere kjøpsplaner når profilfunksjoner innføres.
10. Motta et begrenset antall relevante varsler.

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
* avansert automatisk kombinasjonsmotor
* betalingsintegrasjon eller komplett abonnementsløsning
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

Kjerneverdien i "sjekk før du handler" skal ikke legges bak betalingsmur. En gratis bruker skal kunne søke, forstå beste relevante opptjeningsvei og følge riktig portal eller lenke videre. Et senere premiumlag kan vurderes for avanserte guider, lagrede kjøpsplaner, mer avanserte varsler og dypere personalisering.

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
