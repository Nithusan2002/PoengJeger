---
name: release-readiness
description: Kontroller Poengjeger før pilot, produksjonsutrulling eller bredere intern bruk. Bruk ved release readiness, go/no-go, produksjonsklargjøring, pilotstart, deploy, varsler, adminflate, ekstern innhenting, RLS eller sikkerhetskritiske endringer.
---

# Release Readiness

Les `docs/release-readiness.md`, `docs/product-brief.md`, `docs/roadmap.md`, berørt kode, migrasjoner, Edge Functions, adminverktøy og relevante QA-/policy-dokumenter.

1. Avgrens hva som skal releases: iOS, adminverktøy, Supabase-migrasjoner, Edge Functions, innhold, varsler eller kildeinnhenting.
2. Kjør relevante under-skills først:
   - `qa-security` for sikkerhet, RLS, eksterne kilder, admin, bakgrunnsjobber eller produksjon.
   - `ios-swiftui` for iOS-endringer.
   - `supabase-backend` for database, RLS, auth, Edge Functions eller cron.
   - `campaign-monitoring` for nye eller endrede kilder.
   - `content-quality` for kampanjer, programguider, rangering eller kommersielt innhold.
3. Bruk `docs/release-readiness.md` som portvokterliste. Ikke marker et punkt som bestått uten faktisk kontroll.
4. Kontroller at upublisert innhold, kandidater, hemmeligheter og service role ikke kan nå sluttbrukerappen eller browserbasert adminklient.
5. Kontroller at release ikke utvider MVP uten beslutning i `docs/decisions.md` og eventuell oppdatering av `docs/roadmap.md`.
6. Gi eksplisitt anbefaling: `klar`, `ikke klar` eller `klar med forbehold`.

Lever: scope, kontroller som er kjørt, testresultat, ikke-kjørte kontroller med årsak, åpne risikoer, go/no-go-anbefaling og neste nødvendige oppgave.
