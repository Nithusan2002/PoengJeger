# Poengjeger Admin Tool

Dette er en minimal intern webflate for Poengjeger sin redaksjonelle kandidatkø.

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

## Forutsetninger

- brukeren må finnes i Supabase Auth
- brukeren må ha intern rolle via `editorial_user_roles`
- første admin må bootstrapes via SQL Editor eller service-role

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
- leser `current_editorial_role()`
- henter `admin_ingestion_candidate_queue`
- kjører `ingest-campaign-candidates` manuelt for valgte kilder med innlogget admin/editor-token
- filtrerer på status
- setter review-status via `set_ingestion_candidate_status(...)`
- promoterer kandidater til `draft` via `promote_ingestion_candidate_to_campaign(...)`
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

## Bevisst ikke med ennå

- rolleadministrasjon i UI
- refresh-token-flyt
- full sessionsikkerhet for produksjonsdrift
- full redigering av multi-program-kampanjer og redaksjonelle vurderingstabeller
- avansert revisjonshistorikk eller flertrinnsgodkjenning for programguider

Denne flaten er ment som første operative interne MVP, ikke ferdig produksjonsverktøy.
