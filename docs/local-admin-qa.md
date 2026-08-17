# Lokal admin-QA

Dette dokumentet beskriver en trygg lokal flyt for å kontrollere adminverktøyet uten remote- eller produksjonsdata.

## Forutsetninger

- Colima/Docker kjører.
- Supabase lokal stack kjører med `supabase start`.
- Adminverktøyet åpnes mot lokal Supabase, ikke remote.
- Lokal testbruker skal bare brukes lokalt.

## Start lokal stack

```bash
colima start
supabase start
```

Les lokale nøkler ved behov:

```bash
supabase status -o env
```

## Opprett lokal adminbruker

Bruk vanlig signup-endepunkt for å opprette en ekte lokal Supabase Auth-bruker. Eksempel:

```bash
ANON_KEY="$(supabase status -o env | awk -F= '/^ANON_KEY=/{gsub(/"/, "", $2); print $2}')"

curl -sS http://127.0.0.1:54321/auth/v1/signup \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"local-ui-editor@example.test","password":"local-admin-pass-2026"}'
```

Gi brukeren lokal redaksjonell rolle:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
insert into public.editorial_user_roles (user_id, role, grant_note)
select id, 'admin', 'Local browser admin UI QA'
from auth.users
where email = 'local-ui-editor@example.test'
on conflict (user_id) do update
set
  role = excluded.role,
  revoked_at = null,
  grant_note = excluded.grant_note,
  updated_at = now();
SQL
```

Ikke sett passord ved å oppdatere `auth.users.encrypted_password` direkte. Det kan gi ugyldige credentials fordi lokal Auth kan bruke et annet token- og passordformat enn forventet.

## Start adminverktøy lokalt

For vanlig lokal bruk kan `admin-tool/config.local.js` peke på lokal Supabase:

```js
window.ADMIN_TOOL_CONFIG = {
  supabaseUrl: "http://127.0.0.1:54321",
  supabasePublishableKey: "<PUBLISHABLE_KEY from supabase status -o env>"
};
```

Start statisk server:

```bash
python3 -m http.server 4173 --directory admin-tool
```

Åpne:

```text
http://127.0.0.1:4173
```

## QA-data

Den lokale femkampanje-QA-en bruker:

```text
metadata.qa_run = editorial-five-campaigns-2026-08-16
```

Forventet resultat:

- Fire kandidater med status `promoted`.
- En kandidat med status `rejected`.
- Fire publiserte kampanjer i kampanjeflaten.
- Feed-API viser bare de fire publiserte kampanjene.

Kontrollspørringer:

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "
select status, count(*)
from public.ingestion_candidates
where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
group by status
order by status;"
```

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c "
select c.status, count(*)
from public.campaigns c
join public.ingestion_candidates ic on ic.promoted_campaign_id = c.id
where ic.metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
group by c.status
order by c.status;"
```

## Rydding

Rydd lokal QA-data bare når den ikke trengs for videre visuell kontroll.

```bash
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" <<'SQL'
begin;

delete from public.campaign_geo_restrictions
where campaign_id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.campaign_editorial_assessments
where campaign_id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.campaign_requirements
where campaign_id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.campaign_programs
where campaign_id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.campaign_source_references
where campaign_id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.campaigns
where id in (
  select promoted_campaign_id
  from public.ingestion_candidates
  where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16'
    and promoted_campaign_id is not null
);

delete from public.ingestion_candidates
where metadata ->> 'qa_run' = 'editorial-five-campaigns-2026-08-16';

commit;
SQL
```
