# Poengjeger Admin Tool

Dette er Poengjeger sin interne adminflate for redaksjonell drift. Den skal
holdes separat fra en offentlig produktside og skal ikke lenkes fra vanlig
brukernavigasjon.

For daglig bruk, se `docs/admin-manual.md`.

Anbefalt plassering:

- lokal utvikling: `http://localhost:4173`
- intern test/staging: en beskyttet Pages/Netlify/Cloudflare URL
- produksjonsdrift senere: `admin.poengjeger.no`

GitHub Pages kan brukes teknisk så lenge verktøyet er ren statisk frontend og
Supabase håndhever alle rettigheter med Auth, RLS og RPC-er. For bredere intern
bruk er Netlify eller Cloudflare Pages bedre fordi de kan gi enklere headers,
preview-deploys og eventuell ekstra tilgangskontroll før appen lastes.

## Lokal konfigurasjon

1. Kopier `admin-tool/config.example.js` til `admin-tool/config.local.js`
2. Sett:
   - `supabaseUrl`
   - `supabasePublishableKey`

`config.local.js` er ignorert i git og skal ikke committes.

## Start lokalt

Kjør en enkel statisk server fra repo-roten:

```bash
python3 -m http.server 4173 --directory admin-tool
```

Åpne deretter:

```text
http://localhost:4173
```

## GitHub Pages

Adminflaten kan deployes fra GitHub Actions med
`.github/workflows/admin-pages.yml`. Workflowen publiserer `admin-tool/` som en
statisk GitHub Pages-artifact og lager `config.local.js` under bygging.

Før første deploy:

1. Gå til repository settings for GitHub Pages og velg `GitHub Actions` som
   kilde.
2. Opprett repository variables:
   - `ADMIN_SUPABASE_URL`
   - `ADMIN_SUPABASE_PUBLISHABLE_KEY`
3. Bruk kun Supabase publishable/anon key. Ikke legg service-role key,
   `INGESTION_RUN_SECRET`, OpenAI-nøkkel eller andre hemmeligheter i GitHub
   Pages-bygget.

Hvis adminflaten senere bruker redirect-basert auth, må Pages-URL-en legges til
i Supabase Auth sine tillatte redirect-URL-er.

## Forutsetninger

- brukeren må finnes i Supabase Auth
- brukeren må ha intern rolle via `editorial_user_roles`
- første admin må bootstrapes via SQL Editor eller service-role
- ingen service-role key, OpenAI-nøkkel eller andre hemmeligheter skal ligge i
  `config.local.js` eller browseren
- admin-URL-en kan være kjent; sikkerheten skal ikke avhenge av skjult lenke

Eksempel for å gi første rolle:

```sql
select public.grant_editorial_role(
  p_user_id := '00000000-0000-0000-0000-000000000000',
  p_role := 'admin',
  p_grant_note := 'Bootstrap first admin'
);
```

## Hva denne første versjonen gjør

- logger inn med Supabase Auth
- fornyer utløpende Supabase-session med refresh-token og ber om ny innlogging når sessionen ikke kan fornyes
- leser `current_editorial_role()`
- henter `admin_ingestion_candidate_queue`
- kjører `ingest-campaign-candidates` manuelt for valgte kilder med innlogget admin/editor-token
- filtrerer på status
- setter review-status via `set_ingestion_candidate_status(...)`
- promoterer kampanjekandidater til `draft` via `promote_ingestion_candidate_to_campaign(...)`
- promoterer Trumf-/SAS-kandidater til draft-butikkopptjening via `promote_ingestion_candidate_to_store_earning(...)`
- viser og redigerer butikkopptjening fra `store_earning_rates`
- viser review-status for butikkopptjening med blokkerende mangler og gule kontrollpunkter
- publiserer kontrollerte butikker og satser uten SQL Editor
- viser kampanjer etter status
- redigerer draft-felt, krav og primærkilde
- foreslår redaksjonell vurdering via Edge Function uten å lagre automatisk
- lagrer eller publiserer kampanjer uten SQL Editor
- vedlikeholder `program_guides` per bonusprogram med Lær-intro, verdi-/utløpskort, tipsseksjoner, draft/published/archived-status og redaksjonelt kontrolltidspunkt

## AI-forslag

Knappen `Foreslå med AI` i kampanjeeditoren kaller Edge Function
`suggest-editorial-assessment`. Funksjonen krever innlogget admin/editor og
returnerer bare forslag til skjemafeltene. Redaktøren må fortsatt kontrollere,
lagre og publisere manuelt.

For ekte AI-forslag må Supabase-miljøet ha `OPENAI_API_KEY` som secret.
Uten nøkkel returnerer funksjonen en enkel fallback-tekst, slik at UI-flyten kan
testes uten å legge hemmeligheter lokalt.

## Manuell henting

Knappen `Hent nye kandidater` kaller Edge Function `ingest-campaign-candidates`
med brukerens Supabase-session. `INGESTION_RUN_SECRET` brukes fortsatt for
server/cron-kjøring, men legges ikke i adminverktøyet eller browseren.

## Forenklet butikk-review

Butikkfanen fungerer som første review-inbox for butikkopptjening. Hver sats
merkes som:

- `Klar` når blokkerende felt er på plass.
- `Bør sjekkes` når satsen kan publiseres, men har forbehold som `opptil`,
  kampanjetekst, manglende handoff eller intern kontrolladvarsel.
- `Mangler` når publisering er blokkert av manglende butikk, metode, sats,
  kilde eller kontrolltidspunkt.

Knappen `Publiser kontrollert` setter både butikk og sats til `published`, men
den er bare aktiv når de blokkerende feltene er fylt ut. Dette er valgt fremfor
helautomatisk publisering fordi kandidatene fortsatt kan ha uklare vilkår,
kampanjeperioder eller sporingsforbehold.

## Bevisst ikke med ennå

- rolleadministrasjon i UI
- full sessionsikkerhet for produksjonsdrift
- full redigering av multi-program-kampanjer og redaksjonelle vurderingstabeller
- avansert revisjonshistorikk eller flertrinnsgodkjenning for programguider
- automatisk publisering av nye butikkandidater uten menneskelig kontroll

Denne flaten er ment som første operative interne MVP, ikke ferdig produksjonsverktøy.
