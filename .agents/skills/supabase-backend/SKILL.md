---
name: supabase-backend
description: Design eller endre Poengjegers Supabase- og PostgreSQL-backend, inkludert skjema, migrasjoner, RLS, Edge Functions, cron, autentisering og redaksjonelle adminoperasjoner.
---

# Supabase og backend

Les `docs/data-model.md`, `docs/source-policy.md` ved innhenting, relevante migrasjoner og eksisterende RLS før endring.

1. Beskriv mål, berørte data og autorisasjonsgrenser før implementering.
2. Bruk en ny, fremoverrettet migrasjon; endre ikke en anvendt migrasjon. Definer relasjoner, constraints og indekser eksplisitt.
3. Aktiver og test RLS når klienten har direkte tilgang. Ikke stol på klientvalidering alene.
4. Hold redaksjonelle vurderinger adskilt fra kildebaserte fakta. Maskinelle funn skal gå via `ingestion_candidates` og kan bare promoteres til `draft`.
5. Hold hemmeligheter utenfor repositoryet. Ikke endre auth eller prod-tilgang uten å stoppe og forklare konsekvensene.
6. Test migrasjonens gyldighet og sentrale tillatte og avviste operasjoner. Oppdater data- og beslutningsdokumentasjon ved behov.

Rapporter skjema- og RLS-konsekvenser, migrasjon, testresultat og tilbakeværende operasjonell risiko.
