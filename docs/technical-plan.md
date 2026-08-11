# Poengjeger – Technical Plan

## 1. Formål

Dette dokumentet beskriver en konkret teknisk plan for Poengjeger MVP basert på:
- `AGENTS.md`
- `docs/product-brief.md`

Status: Dette er et plan- og arkitekturdokument. Flere deler er nå implementert eller konkretisert i migrasjoner, iOS-kode, `admin-tool/`, `docs/data-model.md`, `docs/admin-tool-mvp.md`, `docs/ingestion-connectors.md` og `docs/release-readiness.md`. Ved konflikt er migrasjoner og gjeldende kode teknisk sannhetskilde, mens nyere operative dokumenter styrer arbeidsflyt.

## 2. Bekreftede krav

Følgende er eksplisitt bekreftet i prosjektgrunnlaget:
- iOS bygges først.
- Appen skal bygges i SwiftUI.
- Backendens utgangspunkt er Supabase og PostgreSQL.
- Kampanjer opprettes og kvalitetssikres redaksjonelt.
- Appen skal ikke kobles til brukerens bonuskontoer.
- Appen skal ikke hente private saldi eller transaksjoner.
- MVP skal minst støtte:
  - valg av relevante bonusprogrammer
  - personlig feed med aktive kampanjer
  - kampanjedetaljer med vilkår, vurdering og kilde
  - filtrering
  - favoritter
  - et begrenset antall relevante varsler
- Det må finnes et enkelt administrasjonsverktøy for å opprette, kontrollere, oppdatere og arkivere kampanjer.
- Kildeintegritet må ivaretas:
  - identifiserbar kilde
  - tidspunkt for siste kontroll
  - tydelig skille mellom fakta og redaksjonelle vurderinger

## 3. Antakelser

Dette er antakelser som bør bekreftes før implementasjon:
- Første lansering retter seg mot norske brukere og norsk språk.
- Administrasjonsflyten kan i første omgang være et internt webbasert verktøy bygget med Supabase som backend.
- Push-varsler brukes bare for manuelt utvalgte kampanjer eller enkle regler, ikke avansert personalisering i MVP.
- Brukere må kunne ha konto for å synkronisere favoritter, preferanser og varsler på tvers av enheter.
- Første versjon trenger ikke offline-first, men bør tåle kortvarig nettutfall med lokal cache av sist hentede feed.
- Kampanjer rangeres med en enkel, forklarbar redaksjonell score, ikke en kompleks algoritme.

## 4. Anbefalt SwiftUI-arkitektur

Anbefaling:
- Bruk en enkel feature-orientert, lagdelt arkitektur.
- Hold UI, domene og datatilgang adskilt.
- Unngå tung "clean architecture" med unødvendige abstraheringsnivåer i MVP.

Foreslått struktur:
- Presentation:
  - SwiftUI views
  - view models / state objects
  - navigasjon
- Domain:
  - entiteter
  - use cases
  - domeneregler for filtrering, rangering og validering av visning
- Data:
  - repositories
  - Supabase API-klient
  - DTO-er og mapping
  - lokal cache

Konkrete valg:
- `NavigationStack` for appnavigasjon.
- MVVM per feature, men uten egne view models der enkel `@State` eller `@Observable` er tilstrekkelig.
- Repository-protokoller i domain/data-grense kun der de faktisk gir testbarhet eller flere implementasjoner.
- Swift Concurrency (`async/await`) for all IO.
- En delt `AppEnvironment` / dependency container for services og repositories.
- Lokal cache kun for feed, preferanser og favoritter, ikke full kompleks synkroniseringsmotor.

Hvorfor:
- Lav kompleksitet.
- God testbarhet for domenelogikk.
- Enkel vei til senere Android/API-utvidelse uten å overdesigne nå.

## 5. Foreslått modul- og mappestruktur

Anbefaling:
- Start som ett Xcode-prosjekt med interne grupper/mapper.
- Vent med separate Swift Packages eller mange moduler til kompileringstid, eierskap eller gjenbruk faktisk krever det.

Foreslått struktur:

Poengjeger/
- App/
  - `PoengjegerApp.swift`
  - `AppEnvironment.swift`
  - `RootView.swift`
- Core/
  - DesignSystem/
  - Networking/
  - Persistence/
  - Utilities/
- Features/
  - Onboarding/
  - Feed/
  - CampaignDetail/
  - Filters/
  - Favorites/
  - Notifications/
  - Settings/
- Domain/
  - Models/
  - UseCases/
  - Services/
- Data/
  - Repositories/
  - Remote/
  - Local/
  - Mappers/
- AdminSupport/
  - shared admin/domain constants if needed
- Resources/
- Tests/
  - Unit/
  - Integration/
  - SnapshotOrUITests/

Supabase-relatert repo-struktur:
- `supabase/migrations/`
- `supabase/seed/`
- `supabase/policies/` hvis prosjektet ønsker å splitte SQL-filer
- `docs/`

## 6. Første versjon av domenemodellen

### Kjerneentiteter

`BonusProgram`
- `id`
- `slug`
- `name`
- `issuerName`
- `countryCode`
- `isActive`

`Campaign`
- `id`
- `title`
- `summary`
- `details`
- `status`
- `startDate`
- `endDate`
- `lastVerifiedAt`
- `sourceId`
- `primaryProgramId`
- `editorialScore`
- `editorialSummary`
- `isFeatured`
- `createdAt`
- `updatedAt`

`CampaignProgramLink`
- kobler kampanje til ett eller flere bonusprogrammer

`CampaignRequirement`
- `id`
- `campaignId`
- `text`
- `sortOrder`

`CampaignCategory`
- `id`
- `slug`
- `name`

`CampaignSource`
- `id`
- `name`
- `sourceType`
- `baseUrl`

`CampaignSourceReference`
- `id`
- `campaignId`
- `sourceId`
- `url`
- `title`
- `checkedAt`
- `evidenceNote`

`EditorialAssessment`
- `id`
- `campaignId`
- `score`
- `reasonWhyItMatters`
- `estimatedValueText`
- `difficultyLevel`
- `availabilityScope`
- `riskNote`

`GeoRestriction`
- `id`
- `campaignId`
- `countryCode`

`UserProfile`
- `id`
- `preferredLocale`
- `notificationsEnabled`

`UserProgramPreference`
- `userId`
- `programId`

`UserFavoriteCampaign`
- `userId`
- `campaignId`
- `savedAt`

`NotificationSubscription`
- `id`
- `userId`
- `programId`
- `campaignCategoryId`
- `isEnabled`

`IngestionCandidate`
- `id`
- `sourceId`
- `sourceUrl`
- `detectedAt`
- `title`
- `summary`
- `rawContent`
- `normalizedHash`
- `suggestedProgramId`
- `suggestedCategoryId`
- `status`
- `reviewedBy`
- `reviewedAt`
- `reviewNote`
- `promotedCampaignId`

### Domeneregler

Bekreftede eller anbefalte regler:
- En kampanje kan ikke publiseres uten minst én kildehenvisning.
- En kampanje kan ikke publiseres uten `lastVerifiedAt`.
- Redaksjonell vurdering må lagres separat fra dokumenterte fakta.
- Kampanjer kan være knyttet til flere bonusprogrammer.
- Feed skal vise bare publiserte, aktive og ikke-arkiverte kampanjer.
- Utløpte kampanjer skal ikke vises i standardfeed.
- Automatisert eller halvautomatisert kildeinnhenting skal aldri publisere direkte til `campaigns` i MVP.
- Alle maskinelt oppdagede kampanjespor skal gjennom en kandidatstatus før redaksjonell godkjenning.

## 7. Forslag til Supabase-datamodell

Anbefaling:
- Bruk PostgreSQL som sannhetskilde.
- Normaliser moderat.
- Unngå EAV-lignende modell i MVP.

Foreslåtte tabeller:
- `bonus_programs`
- `campaign_categories`
- `source_registry`
- `ingestion_runs`
- `ingestion_candidates`
- `campaigns`
- `campaign_programs`
- `campaign_requirements`
- `campaign_sources`
- `campaign_source_references`
- `campaign_editorial_assessments`
- `campaign_geo_restrictions`
- `user_profiles`
- `user_program_preferences`
- `user_favorite_campaigns`
- `notification_subscriptions`
- `admin_users` eller bruk rollemetadata i auth
- `campaign_audit_log`

Viktige kolonner i `campaigns`:
- `id uuid pk`
- `title text not null`
- `summary text not null`
- `details text not null`
- `status text not null check (status in ('draft','review','published','expired','archived'))`
- `start_date timestamptz null`
- `end_date timestamptz null`
- `last_verified_at timestamptz not null`
- `primary_program_id uuid null references bonus_programs`
- `category_id uuid null references campaign_categories`
- `editorial_score numeric(5,2) null`
- `editorial_summary text null`
- `is_featured boolean not null default false`
- `created_by uuid null`
- `updated_by uuid null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Viktige constraints og indekser:
- indeks på `campaigns(status, end_date)`
- indeks på `ingestion_candidates(status, detected_at desc)`
- unik constraint på `ingestion_candidates(normalized_hash)` når hash finnes
- indeks på `campaign_programs(program_id, campaign_id)`
- indeks på `campaign_source_references(campaign_id)`
- unik constraint på `bonus_programs(slug)`
- unik constraint på `campaign_categories(slug)`
- unik constraint på `user_favorite_campaigns(user_id, campaign_id)`
- check på at `end_date >= start_date` når begge finnes

RLS-anbefaling:
- Lesetilgang for appbrukere kun til publiserte kampanjer og relevante relasjoner.
- Skrivetilgang til kampanjeinnhold kun for admin/editor-roller.
- Brukere kan kun lese/skrive egne preferanser, favoritter og varslingsinnstillinger.
- Ikke stol på klientfiltering for skjerming av upublisert innhold.
- `source_registry`, `ingestion_runs` og `ingestion_candidates` skal ikke være lesbare for vanlige appbrukere i MVP.

### Minimal ingest-modell for MVP

Bekreftede krav:
- Kampanjer skal opprettes og kvalitetssikres redaksjonelt.
- Kilde og kontrolltidspunkt må dokumenteres før publisering.

Antakelser:
- Første automatisering vil følge et lite antall prioriterte kilder, ikke hele markedet.
- Første adminflate kan være et enkelt internt webgrensesnitt eller Supabase-basert flyt.

Anbefaling:
- Legg inn en tydelig mellomstasjon mellom kildefunn og publisert kampanje.
- Hold ingest-pipelinen enkel, observerbar og lett å overstyre manuelt.

Foreslåtte ingest-tabeller:

`source_registry`
- definerer hvilke kilder som overvåkes
- felt:
  - `id`
  - `name`
  - `source_type` med verdier som `api`, `rss`, `newsletter`, `html_page`, `manual`
  - `base_url`
  - `poll_interval_minutes`
  - `parser_key`
  - `is_active`
  - `last_checked_at`

`ingestion_runs`
- én rad per kjøring mot en kilde
- felt:
  - `id`
  - `source_id`
  - `started_at`
  - `finished_at`
  - `status`
  - `candidate_count`
  - `error_message`

`ingestion_candidates`
- rått eller normalisert funn som ennå ikke er publisert
- felt:
  - `id`
  - `source_id`
  - `source_url`
  - `detected_at`
  - `title`
  - `summary`
  - `raw_content`
  - `normalized_hash`
  - `suggested_program_id`
  - `suggested_category_id`
  - `status` med verdier som `new`, `needs_review`, `approved`, `rejected`, `promoted`
  - `reviewed_by`
  - `reviewed_at`
  - `review_note`
  - `promoted_campaign_id`
  - `created_at`
  - `updated_at`

Domeneregler for kandidater:
- Nye automatiske funn lagres i `ingestion_candidates`, ikke i `campaigns`.
- `normalized_hash` brukes for enkel deduplisering av samme funn fra samme eller lignende kilder.
- `promoted` betyr at kandidaten er koblet til en faktisk `campaign`.
- Avviste kandidater beholdes for sporbarhet og for å redusere gjentatte falske treff.

## 8. Nødvendig administrasjonsflyt for kampanjeinnhold

MVP trenger ikke et avansert CMS. Følgende flyt er nødvendig:

### Eksisterende kampanjeflyt

1. Opprette kampanjeutkast
- registrere tittel, sammendrag, detaljer, bonusprogram, kategori og foreløpig gyldighet

2. Legge inn kilder
- én eller flere kilder med URL
- kontrolltidspunkt
- evidensnotat ved behov

3. Legge inn redaksjonell vurdering
- hvorfor kampanjen er interessant
- grov verdi/nytte
- eventuelle begrensninger eller forbehold

4. Kvalitetskontroll
- sjekkliste før publisering:
  - kilde finnes
  - siste kontrolltidspunkt finnes
  - vilkår finnes
  - publiseringsstatus satt riktig
  - utløpsinformasjon vurdert

5. Publisering
- status endres fra `draft/review` til `published`

6. Re-verifisering
- redaktør ser kampanjer som snart utløper eller ikke er kontrollert nylig

7. Arkivering eller utløp
- kampanjer flyttes til `expired` eller `archived`
- behold historikk i audit-logg

### Minimal review-flyt for `ingestion_candidates`

Bekreftede krav:
- Redaksjonen må kontrollere innhold før publisering.

Antakelser:
- Første versjon brukes av et lite internt team.
- Redaksjonen tåler å promotere kandidat til kampanje manuelt i MVP.

Anbefaling:
- Bygg en liten review-kø før mer avansert sluttbruker-UI.

Foreslått flyt:

1. Kilde overvåkes
- en jobb, feed eller manuell import leser en definert kilde

2. Kandidat opprettes
- relevant innhold lagres i `ingestion_candidates`
- systemet lagrer råtekst, kilde-URL og oppdaget tidspunkt

3. Review-kø vises for admin
- admin ser kandidater med status `new` eller `needs_review`
- listen bør minst vise tittel, kilde, tidspunkt og mulig bonusprogram

4. Kandidat vurderes
- admin kan:
  - avvise
  - markere for videre kontroll
  - godkjenne som grunnlag for kampanje

5. Kandidat promoteres til kampanje
- admin oppretter eller oppdaterer en rad i `campaigns`
- tilhørende `campaign_source_references` opprettes samtidig
- kandidaten settes til `promoted` og kobles til `promoted_campaign_id`

6. Kampanjen går gjennom vanlig publiseringsflyt
- status starter som `draft` eller `review`
- publisering krever fortsatt kildehenvisning og `last_verified_at`

Anbefaling:
- Adminverktøy kan være en enkel intern webflate eller Supabase-baserte skjemaer.
- Ikke bygg et fullverdig redaksjonssystem i iOS-appen.

## 9. Anbefalt implementeringsrekkefølge

### Fase 1 – Fundament
- Opprette Xcode-prosjekt og grunnstruktur
- Sette opp Supabase-prosjekt, migrasjoner og RLS
- Definere kjernetabeller og seed-data for noen få bonusprogrammer
- Lage grunnleggende design tokens og navigasjon

### Fase 2 – Innholdsmodell og admin
- Bygge første migrasjoner for kampanjer, kilder, vurderinger og minimale ingest-tabeller
- Etablere enkel review-kø for `ingestion_candidates`
- Etablere enkel administrasjonsflyt for å opprette og publisere kampanjer
- Legge inn eksempeldata manuelt
- Verifisere at publiseringsregler faktisk håndheves i databasen

### Fase 3 – Ekte innhold og validering
- Legge inn 3–5 ekte kampanjer med komplette kilder og vurderinger
- Verifisere at iOS-appen fungerer mot publiserte Supabase-data
- Justere feed- og detaljmodellen etter reelle kampanjer
- Teste manuell promotering fra kandidat til kampanje

### Fase 4 – Brukergrunnlag i app
- Onboarding for valg av bonusprogrammer
- Lagre brukerpreferanser
- Enkel autentisering hvis nødvendig for favoritter og varsler

### Fase 5 – Kjerneopplevelse
- Personlig kampanjefeed
- Filtrering
- Kampanjedetaljer
- Favoritter

### Fase 6 – Varsler og robusthet
- Begrensede push-varsler
- Lokal caching av feed og preferanser
- Empty/error/loading states
- Basistester for domene og repository-lag

### Fase 7 – Polering før pilot
- Tilgjengelighet
- ytelsesjustering
- redaksjonell arbeidsflytforbedring
- instrumentering av sentrale brukerhendelser

## 10. Viktige sikkerhets- og vedlikeholdsrisikoer

### Sikkerhetsrisikoer
- Upubliserte kampanjer kan lekke hvis RLS eller API-filtrering er feil.
- Admin-endepunkter kan bli for brede hvis editor- og brukerroller ikke skilles tydelig.
- Push-varsler kan avsløre innhold som ennå ikke skulle vært publisert hvis pipeline er svak.
- Affiliate- eller kommersielle koblinger kan svekke tillit hvis merking ikke håndheves.

### Vedlikeholdsrisikoer
- Redaksjonelt arbeid kan bli flaskehals hvis re-verifisering ikke støttes av gode lister og statusfelt.
- Uten en kandidatkø vil senere automatisering lett skape blanding av råfunn og verifisert innhold.
- For kompleks rangering vil være vanskelig å forklare og vedlikeholde.
- For mange bonusprogrammer tidlig øker datakvalitetskostnaden kraftig.
- For mye fleksibilitet i datamodellen tidlig kan gi svak konsistens.
- Hvis kildebevis og kontrolltidspunkt ikke er obligatoriske, svekkes hele produktets troverdighet.

## 11. Funksjoner som bør fjernes fra første MVP

Anbefaling:
- Fjern eller utsett alt som ikke er nødvendig for å validere tidsbesparelse og innholdsverdi.

Bør fjernes fra første MVP:
- avansert personalisert rangeringsmotor
- automatisk kampanjeinnhenting fra mange kilder uten manuell review
- komplekse varslingsregler per bruker
- sosial deling eller community-funksjoner
- gamification
- premiumabonnement
- annonser
- Android-støtte
- full offline-støtte
- omfattende analyse av brukerpoengverdi per person
- intern admin-app på iOS
- støtte for "alle" bonusprogrammer ved lansering

## 12. Konklusjon

Anbefalt MVP er et redaksjonelt kuratert kampanjeprodukt med:
- enkel SwiftUI-app
- moderat normalisert Supabase-modell
- tydelig skille mellom fakta og vurdering
- begrenset, trygg adminflyt
- få, forklarbare funksjoner

Dette gir høyest sannsynlighet for å validere kjerneverdien raskt uten å bygge unødvendig kompleksitet.
