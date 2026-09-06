# Poengjeger

Poengjeger er en norsk iOS-app som hjelper bonusbrukere å finne den beste relevante opptjeningsveien før de handler. Første produktfase er avgrenset til EuroBonus og Trumf.

Appens kjerneflyt er **sjekk før du handler**: søk etter en butikk eller kategori, se vanlig opptjening og aktive kampanjer, og følg redaksjonelt kvalitetssikrede steg til riktig portal.

## Status

Prosjektet er under aktiv MVP-utvikling. Innhold kan hentes inn automatisk til en kandidatkø, men publiseres aldri uten redaksjonell kontroll.

MVP-en omfatter blant annet:

- butikksøk og kategorier
- opptjeningssatser og aktive kampanjer
- redaksjonelt definerte kombinasjoner
- Poengnytt og programguider
- en separat intern adminflate for innholdsarbeid

Poengjeger kobler ikke til brukernes bonuskontoer og leser ikke saldo eller transaksjoner.

## Teknologi

- SwiftUI og Swift 6
- iOS 18 eller nyere
- Supabase og PostgreSQL
- Supabase Edge Functions for kontrollert innhenting
- statisk webverktøy for intern administrasjon

## Kom i gang med iOS-appen

1. Klon repositoryet.
2. Kopier `Poengjeger/Config/AppSecrets.example.xcconfig` til `Poengjeger/Config/AppSecrets.local.xcconfig`.
3. Fyll inn `SUPABASE_HOST` og `SUPABASE_PUBLISHABLE_KEY` i den lokale filen.
4. Åpne `Poengjeger.xcodeproj` i Xcode.
5. Velg `Poengjeger`-scheme og kjør appen i en iOS 18-simulator eller på en enhet.

`AppSecrets.local.xcconfig` er ignorert av git. Ikke legg service-role-nøkler, ingest-hemmeligheter eller andre private nøkler i appen eller repositoryet.

## Backend

Supabase-oppsettet ligger i `supabase/`:

- `migrations/` inneholder versjonerte databaseendringer
- `seed/` inneholder lokale eksempel- og MVP-data
- `functions/` inneholder Edge Functions

Lokalt Supabase-miljø krever Supabase CLI og Docker. Fra repo-roten:

```bash
supabase start
supabase db reset
```

Bruk alltid en ny migrasjon ved skjemaendringer. Ikke rediger produksjonsdata eller tilgangskontroll uten å vurdere constraints, indekser og RLS.

## Adminverktøy

Den interne redaksjonsflaten ligger i `admin-tool/`. Se [admin-tool/README.md](admin-tool/README.md) for lokalt oppsett, autentisering og sikkerhetsforutsetninger.

## Prosjektstruktur

```text
Poengjeger/       SwiftUI-appen
PoengjegerTests/  Enhets- og flyttester
admin-tool/       Intern redaksjonell webflate
supabase/         Migrasjoner, seed-data og Edge Functions
scripts/          Kontroll-, ingest- og smoke-skript
docs/             Produkt-, design- og teknisk dokumentasjon
```

## Viktige dokumenter

- [Produktbrief](docs/product-brief.md) – målgruppe, verdiforslag og MVP-avgrensning
- [Roadmap](docs/roadmap.md) – nåværende omfang og neste valideringer
- [Arkitekturbeslutninger](docs/decisions.md) – begrunnede produkt- og teknologivalg
- [Teknisk plan](docs/technical-plan.md) – arkitektur og implementeringsretning
- [Redaksjonell policy](docs/editorial-policy.md) – krav til fakta, vurderinger og publisering
- [Designsystem](docs/design-system.md) – visuelle tokens og UI-prinsipper

## Grunnprinsipper

- Bygg den enkleste løsningen som dekker et validert behov.
- Skill dokumenterte fakta fra redaksjonelle vurderinger og estimater.
- Ikke gjett manglende kampanjevilkår eller publiser innhold med uklar kilde.
- Hold EuroBonus og Trumf som første fase til opplevelsen er validert.
- Behandle kildekvalitet, utløpsdatoer og redaksjonell kontroll som produktfunksjoner.

## Lisens

Se [LICENSE](LICENSE).
