# Datamodell

Dette dokumentet beskriver gjeldende databasegrunnlag. Migrasjonene i `supabase/migrations/` er den tekniske sannhetskilden.

## Kampanjeinnhold

- `bonus_programs`: støttede bonusprogrammer.
- `program_guides`: redaksjonelle strategiguider per bonusprogram med publiseringsstatus, Markdown-body (`body_markdown`), automatisk utdrag/legacy-intro og siste kontrolltidspunkt. Eldre strukturerte guidefelter finnes fortsatt som fallback for eksisterende innhold.
- `campaign_categories`: kampanjekategorier.
- `stores`: butikker og partnere brukeren kan søke opp før kjøp, med kategori, publiseringsstatus, URL og siste kontrolltidspunkt.
- `earning_methods`: opptjeningsmekanismer som EuroBonus Shopping, Trumf, betalingskort eller tidsbegrenset kampanje.
- `store_earning_rates`: stabil grunnopptjening eller aktiv sats for en butikk og metode, med krav, kilde og handoff-URL.
- `earning_combinations`: redaksjonelt definerte beste kombinasjoner for en butikk. MVP bruker dette fremfor automatisk optimalisering.
- `earning_combination_steps`: ordnede steg for "Slik gjør du det".
- `campaigns`: publiseringslivssyklus, kjerneinnhold, datoer, primærprogram og redaksjonell kortvurdering.
- `campaign_programs`: kobler en kampanje til flere programmer.
- `campaign_requirements`: ordnede krav for en kampanje.
- `campaign_sources` og `campaign_source_references`: kildeidentitet, URL, kontrolltidspunkt og bevisnotat.
- `campaign_editorial_assessments`: redaksjonell beslutningslabel, kort konklusjon, hvem kampanjen passer/ikke passer for, begrunnelse, estimat, vanskelighetsgrad, tilgjengelighet og risiko.
- `campaign_geo_restrictions`: landbegrensninger.
- `campaign_audit_log`: statusendringer for kampanjer.

En publisert kampanje krever minst én kildehenvisning, `last_verified_at`, minst én kobling til bonusprogram og redaksjonell beslutning med kort konklusjon. Nye kildehenvisninger må bruke `https://`-URL. Dette håndheves i databasen for redaksjonell lagring.

Publisert butikkopptjening har egne minimumsvakter: publiserte butikker må ha siste kontrolltidspunkt, publiserte satser må ha satslabel, kravtekst, kilde-URL, kildetittel og kontrolltidspunkt, og publiserte kombinasjoner må ha tittel, totalverdi, sammendrag og siste kontrolltidspunkt. `store_earning_publication_quality_issues` viser publiserte butikk-, sats- og kombinasjonsrader som fortsatt bør kontrolleres før pilot.

Publiserte programguider kan leses av klienten for aktive bonusprogrammer. Utkast og arkiverte guider er kun tilgjengelige for redaksjonelle adminbrukere.

Publiserte butikker, opptjeningsmetoder, satser og kombinasjoner kan leses av klienten. Utkast, arkiverte rader og redaksjonell administrasjon er begrenset til redaksjonelle roller via RLS.

## Brukerdata

- `user_profiles`: språk og varslingsvalg.
- `editorial_user_roles`: interne roller for adminverktøyet (`editor`, `admin`).
- `user_program_preferences`: valgte bonusprogrammer.
- `user_favorite_campaigns`: lagrede kampanjer.
- `notification_subscriptions`: valgfrie program- eller kategoriabonnementer.
- `product_events`: pseudonyme produktanalytics-events for å validere MVP-bruk og premium-kandidater. Klienten kan bare skrive events; lesetilgang er begrenset til redaksjonelle medlemmer.

Brukerdata er knyttet til Supabase Auth og omfattes av RLS. Appen lagrer ikke bonuskontoer, private saldi eller transaksjoner.

## Innhentings- og redaksjonsflyt

- `source_registry`: godkjente innhentingskilder og kontrollkonfigurasjon.
- `ingestion_runs`: utførte kildekontroller og feilstatus.
- `ingestion_candidates`: maskinelt eller halvautomatisk oppdagede kandidater.

En kandidat går fra `new` via redaksjonell vurdering til enten `rejected` eller `promoted`. Promotering oppretter kun en `draft`-kampanje eller en `draft`-rad for butikkopptjening; publisering er et separat redaksjonelt steg.

Adminverktøyet autoriseres via Supabase Auth og databasebaserte roller i `editorial_user_roles`. Redaksjonelle innholdsoperasjoner bruker `public.is_editorial_member()`, mens sensitive adminoperasjoner kan bruke `public.is_admin_role()`. `public.is_admin()` finnes fortsatt som bakoverkompatibel alias for redaksjonelt medlemskap. Rolleendringer kan gå via dedikerte funksjoner for granting og revoking.

## Endringsregler

Bruk en ny migrasjon ved skjemaendringer. Dokumenter formål, relasjoner, constraints, indekser og RLS-konsekvenser i beslutningsloggen når endringen er vesentlig.
