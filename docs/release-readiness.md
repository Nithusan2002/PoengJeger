# Release Readiness

Dette er portvokterlisten før pilot, produksjonsutrulling eller bredere intern bruk av Poengjeger.

## Bruk

Kjør denne listen sammen med `qa-security` før produksjonsutrulling og før endringer som kan publisere, varsle, hente fra eksterne kilder eller gi intern tilgang.

Rapporter bare kontroller som faktisk er utført. Merk resten som ikke kjørt med årsak.

## Produktgrenser

- MVP stemmer fortsatt med `docs/product-brief.md` og `docs/roadmap.md`.
- Appen kobler ikke til bonuskontoer, saldoer eller transaksjoner.
- Nye funksjoner har gått gjennom `product-review` når de endrer MVP, brukerflyt eller forretningsmodell.
- Kommersielt innhold er merket og påvirker ikke dokumenterte fakta skjult.

## iOS

- Feed viser bare publiserte, aktive og ikke-utløpte kampanjer.
- Kampanjedetalj viser kilde, kontrolltidspunkt, krav og redaksjonell vurdering.
- Onboarding, programvalg, filtrering og favoritter fungerer med representative backenddata.
- Loading-, empty- og error-tilstander er eksplisitte.
- Dynamic Type, VoiceOver, mørk modus og grunnleggende kontrast er kontrollert på berørte skjermer.
- Lokal konfigurasjon bruker `AppSecrets.local.xcconfig`; ingen miljøverdier ligger i versjonerte filer.

## Admin

- Bare innloggede brukere med `editor` eller `admin` i `editorial_user_roles` får bruke adminflaten.
- Første admin kan bootstrapes kontrollert, og videre rolleendringer går via dedikerte funksjoner.
- Kandidater kan avvises, markeres for review, godkjennes og promoteres til `draft`.
- Promotering publiserer aldri direkte.
- Publisering krever minst én kildehenvisning og `last_verified_at`.
- Adminverktøyet håndterer utløpt session uten å eksponere service role eller andre hemmeligheter i browseren.

## Innhenting

- Alle aktive kilder finnes i `source_registry` og er redaksjonelt godkjent.
- Hver kilde er dokumentert med `docs/source-onboarding-template.md` eller tilsvarende.
- Robots.txt, vilkår, metode, rate limit, user-agent og stoppkriterier er kontrollert.
- Connectorer skriver bare til `ingestion_candidates` og `ingestion_runs`.
- 403, 404, 429, timeout og tom respons er testet eller eksplisitt avgrenset.
- Duplikat- og endringsdeteksjon er testet med fixtures eller kontrollerte testdata.

## Innhold

- `docs/editorial-qa-checklist.md` er kjørt med representative kampanjer.
- Publiserte kampanjer har identifiserbar kilde, kontrolltidspunkt og tydelige krav.
- Manglende dato, verdi eller vilkår står som manglende, ikke gjettet.
- Redaksjonell vurdering og estimert verdi er skilt fra dokumenterte fakta.
- Programguider har status, `last_reviewed_at` og forsiktig språk uten ukontrollerte verdianslag.

## Varsler

- Varslingsflyten er avgrenset i `docs/notification-strategy.md` før push sendes.
- Brukeren har eksplisitt opt-in.
- Varsler sendes bare for publiserte og nylig kontrollerte kampanjer.
- Det finnes frekvensgrense og manuell stoppmulighet.
- Utkast, kandidater og arkiverte kampanjer kan ikke trigge varsler.

## Sikkerhet og drift

- RLS er aktivert og testet for både tillatte og avviste operasjoner på berørte tabeller.
- Service role brukes bare server-side.
- `OPENAI_API_KEY`, `INGESTION_RUN_SECRET` og Supabase service role ligger ikke i repoet, appen eller admin-browseren.
- Edge Functions logger ikke hemmeligheter, private data eller upublisert innhold unødvendig.
- Migrasjoner er kjørt i riktig rekkefølge og kan valideres i et rent miljø.
- Rollback eller manuell nødprosedyre er kjent for siste endring.

## Minimumsrapport

Før release skal svaret inneholde:

- berørte filer og migrasjoner
- skills brukt
- tester og manuelle kontroller som faktisk ble kjørt
- ikke-kjørte kontroller med årsak
- åpne risikoer
- eksplisitt anbefaling: klar, ikke klar eller klar med navngitte forbehold
