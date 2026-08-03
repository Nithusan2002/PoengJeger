# Admin Tool MVP

## Formål

Dette dokumentet definerer den minste forsvarlige versjonen av et separat internt adminverktøy for Poengjeger.

Målet er å gi redaksjonen en praktisk arbeidsflate for å vurdere `ingestion_candidates`, opprette `draft`-kampanjer og vedlikeholde publisert innhold, uten å legge adminansvar inn i sluttbrukerappen.

## Bekreftede krav

- Sluttbrukerappen skal fokusere på konsum av kampanjer, ikke redaksjonelt arbeid.
- Kampanjer skal kvalitetssikres redaksjonelt før publisering.
- Maskinelt eller halvautomatisk oppdaget innhold skal gå via `ingestion_candidates`.
- Kandidater kan promoteres til `draft`, ikke publiseres direkte.
- Supabase/PostgreSQL er backend-utgangspunktet.

## Antakelser

- Første redaksjonelle brukere er et svært lite internt team.
- MVP-en trenger ikke avansert CMS-funksjonalitet, kun arbeidsflyt for review og publisering.
- Adminverktøyet kan være web-basert uten krav om offentlig tilgjengelig frontend for eksterne brukere.
- Supabase Auth kan brukes for intern innlogging og rollebasert tilgang.

## Anbefaling

Bygg et lite separat adminverktøy som webflate over de eksisterende Supabase-primitivene, i stedet for å bygge live adminflyt i iOS-appen.

Begrunnelse:

- Tydeligere sikkerhetsgrense mellom publikumsklient og intern drift.
- Enklere RLS og autorisasjon.
- Bedre arbeidsflate for tabeller, review, filtrering og redigering.
- Mindre produktstøy i iOS-MVP-en.

## Brukerproblem

Redaksjonen trenger i dag database- eller SQL-basert arbeid for å håndtere kandidater og kampanjer. Det er for tungvint til daglig drift og øker risikoen for feil, treg publisering og ujevn datakvalitet.

## Målgruppe

- Intern redaksjon
- Eventuell grunnlegger/operatør som kvalitetssikrer innhold

## Må ha i MVP

### 1. Innlogging og tilgang

- Innlogging med Supabase Auth
- Kun brukere med admin-rolle får tilgang
- Ingen anonym eller publiserbar klienttilgang til adminoperasjoner

### 2. Kandidatkø

- Liste over `ingestion_candidates`
- Filtrering på status: `new`, `needs_review`, `approved`, `rejected`, `promoted`
- Vise kilde, oppdaget tidspunkt, foreslått program og kategori
- Åpne kandidatdetaljer med råinnhold og review-notater

### 3. Review-handlinger

- Sett status til `needs_review`
- Godkjenn kandidat
- Avvis kandidat
- Lagre review-notat

### 4. Promotering til draft

- Promoter godkjent kandidat til `draft`-kampanje
- Tillat enkel overstyring av program og kategori før promotering
- Vis tydelig at promotering ikke publiserer kampanjen

### 5. Draft-redigering

- Rediger tittel, kort beskrivelse og detaljtekst
- Rediger krav og vilkår
- Knytt kampanjen til program og kategori
- Registrer eller oppdater `last_verified_at`
- Lagre redaksjonell begrunnelse

### 6. Publiseringskontroll

- Endre status mellom `draft`, `published` og `archived`
- Ikke tillat publisering uten kilde og `last_verified_at`
- Vis hvem som sist oppdaterte innholdet hvis data finnes

## Burde ha

- Enkel søkefunksjon i kandidatkø og kampanjer
- Varsel-/oppgavetelling for kandidater som venter review
- Liste over utløpende eller snart utdaterte kampanjer

## Kan vente

- Masseoperasjoner
- Kommentartråder
- Diff-visning mellom kandidat og ferdig kampanje
- Full revisjonshistorikk i UI
- E-post- eller Slack-varsler

## Ikke bygg i første admin-MVP

- Generisk CMS for alle typer innhold
- Komplett analytics-dashboard
- Avansert workflow-motor
- AI-basert auto-publisering
- Adminfunksjoner for sluttbrukere, abonnement eller betaling

## Foreslått skjermliste

### `Login`

- Supabase Auth for interne brukere

### `Queue`

- Standard startskjerm
- Kandidatkø med filtre og status

### `Candidate Detail`

- Rå kandidatdata
- Kilde og lenke
- Review-notat
- Statusendring
- Promotering til draft

### `Draft Editor`

- Redigering av kampanjeutkast
- Validering før publisering

### `Published / Archive`

- Enkel liste for vedlikehold av aktive og arkiverte kampanjer

## Datatilgang

Adminverktøyet bør bruke Supabase på to nivåer:

- Lesing via views eller direkte tabeller med RLS
- Skriving via eksplisitte RPC-er eller tydelig avgrensede tabelloperasjoner

Anbefalt første oppsett:

- `admin_ingestion_candidate_queue` for køvisning
- `set_ingestion_candidate_status(...)` for review
- `promote_ingestion_candidate_to_campaign(...)` for promotering
- direkte redigering av `campaigns` og relaterte tabeller kun for admin-brukere

## Autorisasjonsmodell

Anbefalt minste modell:

- Egen `profiles`- eller rolle-tabell knyttet til `auth.users`
- Funksjon som `public.is_admin()` brukes i RLS og RPC-er
- Alle admintabeller og admin-RPC-er krever innlogget admin
- iOS-appen fortsetter å bruke publiserbar nøkkel og kun publisert lesetilgang

## Valideringsregler

En kampanje skal ikke kunne publiseres uten:

- minst én kilde
- `last_verified_at`
- status satt eksplisitt til `published`
- tittel
- sammendrag eller beskrivelse som gjør kampanjen forståelig

## Suksessindikatorer

- Tid fra ny kandidat til ferdig `draft` reduseres betydelig mot SQL-flyt
- Redaksjonen kan håndtere kandidat-review uten SQL Editor i det daglige
- Ingen kampanjer publiseres uten kilde og kontrolltidspunkt
- iOS-appen trenger ikke intern adminlogikk for å holde MVP-fokus

## Viktige risikoer

- Adminverktøyet blir for bredt og forsinker kjerneproduktet
- Auth/RLS blir feil konfigurert og gir for bred tilgang
- For mange manuelle felter gjør review tregt
- Kampanjemodellen kan fortsatt være for tynn for komplekse tilbud

## Neste tekniske oppgave

Den neste konkrete oppgaven bør være å definere live admin-auth og RLS-grenser for dette verktøyet:

1. modell for admin-rolle i Supabase
2. RLS-policyer for `ingestion_candidates`, `campaigns` og relevante relasjoner
3. hvilke operasjoner som går via RPC versus direkte tabellskriving
4. minste skjema for draft-redigering og publiseringsvalidering
