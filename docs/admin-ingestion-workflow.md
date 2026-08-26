# Admin Ingestion Workflow

## Formål

Dette dokumentet beskriver den minste redaksjonelle flyten som trengs for å gå fra `ingestion_candidates` til en publiserbar `campaign`.

Målet er å unngå direkte publisering fra maskinelt oppdaget innhold, samtidig
som butikkorienterte funn fra kilder som Trumf Netthandel og SAS EuroBonus
Shopping kan bli redaksjonelle utkast til butikkopptjening.

## Bekreftede grenser

- Kandidater skal ikke publiseres direkte.
- Publiserte kampanjer må fortsatt ha verifisert kilde og `last_verified_at`.
- Admin-flyten har både databaseprimitiver og en første intern webflate i `admin-tool/`.
- SQL Editor skal være fallback for bootstrap, feilsøking og nødoperasjoner, ikke normal daglig review.

## Flyt

1. Ny kandidat havner i `ingestion_candidates` med status `new`.
2. Redaksjonen vurderer kandidaten i admin-køen.
3. Kandidaten settes til:
   - `approved`
   - `rejected`
4. Når kandidaten er relevant, promoteres den enten til en `draft`-kampanje
   eller til `draft`-butikkopptjening.
5. Redaksjonen fullfører kampanjen:
   - forbedrer tittel og sammendrag
   - legger til krav
   - legger til redaksjonell vurdering
   - kontrollerer kildegrunnlag
   - setter `last_verified_at`
6. Først deretter kan kampanjen settes til `published`.

For butikkopptjening gjelder samme prinsipp: `promote_ingestion_candidate_to_store_earning(...)`
oppretter eller oppdaterer en butikk som `draft` og oppretter en
`store_earning_rates`-rad som `draft`. Butikk og sats må fortsatt kontrolleres
og publiseres eksplisitt av redaksjonen.

## Nye databaseprimitiver

Migrasjonen `20260803110000_add_admin_ingestion_workflow.sql` legger til:

- `public.admin_ingestion_candidate_queue`
  - en lesbar kø-visning for kandidater med kildedata og forslag
- `public.set_ingestion_candidate_status(...)`
  - setter review-status på en kandidat
- `public.promote_ingestion_candidate_to_campaign(...)`
  - oppretter en `draft`-kampanje fra en kandidat og kobler med første kilde
- `public.promote_ingestion_candidate_to_store_earning(...)`
  - oppretter eller gjenbruker butikk og lager en `draft`-sats fra Trumf/SAS-kandidat

## Testkandidat i repoet

Det finnes nå en kontrollert seed-fil for å teste køen:

- `supabase/seed/ingestion_candidates.sql`

Den oppretter én kandidat i status `new` for SAS EuroBonus, ment for manuell review og promotering til `draft`.

## Slik tar du dette i bruk

For daglig review brukes det interne adminverktøyet:

```bash
python3 -m http.server 4173 --directory admin-tool
```

Åpne `http://localhost:4173`, logg inn med Supabase Auth, og kontroller at brukeren har rolle i `editorial_user_roles`.

Hvis du kjører via CLI mot remote prosjekt, trenger du først prosjektlink og databasepassord.

Eksempel:

```bash
supabase link --project-ref vxshbidckvfzxohcpprq
supabase db push
```

Deretter kan du kjøre seed-SQL i Supabase SQL Editor eller via CLI.

Hvis du ikke vil bruke CLI ennå, er den enkleste veien:

1. Åpne Supabase SQL Editor.
2. Kjør migrasjonen `20260803110000_add_admin_ingestion_workflow.sql`.
3. Kjør `supabase/seed/ingestion_candidates.sql`.
4. Kjør `select * from public.admin_ingestion_candidate_queue order by detected_at desc;`

Merk:
- Review-/promote-funksjonene er laget for å fungere fra adminverktøy/RPC og fra Supabase SQL Editor.
- I SQL Editor kan `reviewed_by` være tom fordi handlingen ikke går via en sluttbruker-token. `reviewed_at` og status brukes derfor som minimumsspor i denne første admin-MVP-en.
- Promote oppretter fortsatt bare `draft`, ikke `published`.

## Eksempler

Se kø:

```sql
select *
from public.admin_ingestion_candidate_queue
where status in ('new', 'approved')
order by detected_at desc;
```

Legg inn notat på en kandidat som må vurderes nærmere, og la den stå som `new`:

```sql
select public.set_ingestion_candidate_status(
  '00000000-0000-0000-0000-000000000000',
  'new',
  'Trenger manuell kontroll av vilkår og dato.'
);
```

Godkjenn kandidat for videre arbeid:

```sql
select public.set_ingestion_candidate_status(
  '00000000-0000-0000-0000-000000000000',
  'approved',
  'Relevant for MVP-programmer.'
);
```

Avvis kandidat:

```sql
select public.set_ingestion_candidate_status(
  '00000000-0000-0000-0000-000000000000',
  'rejected',
  'Ikke kampanje, bare generell informasjonsside.'
);
```

Promoter kandidat til draft-kampanje:

```sql
select public.promote_ingestion_candidate_to_campaign(
  p_candidate_id := '00000000-0000-0000-0000-000000000000'
);
```

Promoter kandidat til draft-butikkopptjening:

```sql
select public.promote_ingestion_candidate_to_store_earning(
  p_candidate_id := '00000000-0000-0000-0000-000000000000'
);
```

Promoter med overstyrt butikknavn, kategori og sats:

```sql
select public.promote_ingestion_candidate_to_store_earning(
  p_candidate_id := '00000000-0000-0000-0000-000000000000',
  p_store_name := 'Komplett',
  p_category_id := '22222222-2222-2222-2222-222222222222',
  p_rate_label := '15 EuroBonus-poeng per 100 kr',
  p_review_note := 'Kontrollert mot SAS Online Shopping-feed.'
);
```

Promoter med overstyrt program/kategori:

```sql
select public.promote_ingestion_candidate_to_campaign(
  p_candidate_id := '00000000-0000-0000-0000-000000000000',
  p_primary_program_id := '11111111-1111-1111-1111-111111111111',
  p_category_id := '22222222-2222-2222-2222-222222222222',
  p_review_note := 'Promotert med manuell kategorisering.'
);
```

## Viktige begrensninger

- Promote-funksjonen oppretter bare `draft`, aldri `published`.
- Den kopierer bare inn minimumsdata:
  - tittel
  - sammendrag
  - rådetaljer
  - primærprogram hvis kjent
  - kategori hvis kjent
  - én kildehenvisning
- Krav, geobegrensninger, score og redaksjonell vurdering må fortsatt fylles ut separat.
- Butikkopptjening-promotering er foreløpig støttet for `trumf_netthandel` og
  `sas_eurobonus_shopping`, fordi disse kildene produserer butikk-/satsfunn.

## Neste naturlige utvidelse

Neste steg er ikke å bygge admin inn i iOS-klienten. Forbedre i stedet det separate adminverktøyet med tryggere sesjonshåndtering, rolleadministrasjon, bedre lister for utløpende innhold og release-kontrollene i `docs/release-readiness.md`.
