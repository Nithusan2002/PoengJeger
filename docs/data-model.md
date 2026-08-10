# Datamodell

Dette dokumentet beskriver gjeldende databasegrunnlag. Migrasjonene i `supabase/migrations/` er den tekniske sannhetskilden.

## Kampanjeinnhold

- `bonus_programs`: støttede bonusprogrammer.
- `program_guides`: redaksjonelle strategiguider per bonusprogram med publiseringsstatus, intro, nøkkelfelter for verdi/utløp, tipsseksjoner og siste kontrolltidspunkt.
- `campaign_categories`: kampanjekategorier.
- `campaigns`: publiseringslivssyklus, kjerneinnhold, datoer, primærprogram og redaksjonell kortvurdering.
- `campaign_programs`: kobler en kampanje til flere programmer.
- `campaign_requirements`: ordnede krav for en kampanje.
- `campaign_sources` og `campaign_source_references`: kildeidentitet, URL, kontrolltidspunkt og bevisnotat.
- `campaign_editorial_assessments`: redaksjonell begrunnelse, estimat, vanskelighetsgrad, tilgjengelighet og risiko.
- `campaign_geo_restrictions`: landbegrensninger.
- `campaign_audit_log`: statusendringer for kampanjer.

En publisert kampanje krever minst én kildehenvisning og `last_verified_at`. Dette håndheves i databasen.

Publiserte programguider kan leses av klienten for aktive bonusprogrammer. Utkast og arkiverte guider er kun tilgjengelige for redaksjonelle adminbrukere.

## Brukerdata

- `user_profiles`: språk og varslingsvalg.
- `editorial_user_roles`: interne roller for adminverktøyet (`editor`, `admin`).
- `user_program_preferences`: valgte bonusprogrammer.
- `user_favorite_campaigns`: lagrede kampanjer.
- `notification_subscriptions`: valgfrie program- eller kategoriabonnementer.

Brukerdata er knyttet til Supabase Auth og omfattes av RLS. Appen lagrer ikke bonuskontoer, private saldi eller transaksjoner.

## Innhentings- og redaksjonsflyt

- `source_registry`: godkjente innhentingskilder og kontrollkonfigurasjon.
- `ingestion_runs`: utførte kildekontroller og feilstatus.
- `ingestion_candidates`: maskinelt eller halvautomatisk oppdagede kandidater.

En kandidat går fra `new` via redaksjonell vurdering til enten `rejected` eller `promoted`. Promotering oppretter kun en `draft`-kampanje; publisering er et separat redaksjonelt steg.

Adminverktøyet autoriseres via Supabase Auth og databasebaserte roller i `editorial_user_roles`. Eksisterende admin-RLS og RPC-er bruker `public.is_admin()`, som nå kan lese aktiv rolle fra databasen. Rolleendringer kan gå via dedikerte funksjoner for granting og revoking.

## Endringsregler

Bruk en ny migrasjon ved skjemaendringer. Dokumenter formål, relasjoner, constraints, indekser og RLS-konsekvenser i beslutningsloggen når endringen er vesentlig.
