# AGENTS.md – Poengjeger

## Prosjekt

Poengjeger er en iOS-app som samler, kvalitetssikrer og prioriterer aktuelle kampanjer for bonus- og lojalitetsprogrammer.

## Operativ arbeidsmappe

Bruk `/Users/nithu/Developer/PoengJeger-working` som aktiv arbeidsmappe for kodeendringer, bygging og Xcode-feilsøking. Dette er kopien brukeren kjører i Xcode.

Les `docs/product-brief.md` før produktrelaterte eller arkitektoniske endringer.

## Grunnregler

- Bygg den enkleste løsningen som oppfyller behovet.
- Ikke utvid MVP uten å dokumentere hvorfor.
- Skill mellom dokumenterte fakta, redaksjonelle vurderinger, estimater og brukerens antakelser.
- Ikke gjett manglende kampanjeinformasjon.
- Ikke publiser automatisk innhold med usikker kilde eller uklare vilkår.
- Ikke legg hemmeligheter i repositoryet.
- Bruk migrasjoner for databaseendringer; vurder relasjoner, constraints, indekser og RLS.
- Vurder tester ut fra risiko og omfang. Kjør relevante tester ved kodeendringer, skjemaendringer, sikkerhetskritiske endringer, større brukerflyter eller når brukeren ber om det. Ikke bruk tid eller tokens på testkjøring for rene dokumentasjons-/instruksjonsendringer, små analyser eller statusspørsmål. Ikke påstå at tester er kjørt når de ikke er det; rapporter kort når tester bevisst er hoppet over.
- Oppdater `docs/decisions.md` ved større tekniske eller produktmessige beslutninger, og `docs/roadmap.md` når planlagt omfang påvirkes.

## Teknisk utgangspunkt

- SwiftUI og iOS først.
- Supabase og PostgreSQL.
- Redaksjonell kvalitetssikring av kampanjer.
- Ingen tilgang til brukernes bonuskontoer, saldi eller transaksjoner.

## Skills

Bruk relevante Skills fra `.agents/skills/` for arbeidsområdet.

| Arbeid | Påkrevd Skill |
| --- | --- |
| Ny funksjon, MVP-endring eller større brukerflyt | `product-review` før implementering |
| SwiftUI, navigasjon, state, tilgjengelighet eller iOS-tester | `ios-swiftui` |
| Skjema, migrasjoner, RLS, Edge Functions, cron, auth eller adminoperasjoner | `supabase-backend` |
| Ny kampanjekilde, innhenting, connector, endrings- eller duplikatdeteksjon | `campaign-monitoring` |
| Kampanjeinnhold, oppsummering, vilkår, tagging, rangering eller kommersielt innhold | `content-quality` |
| Nye funksjoner, ekstern data, bakgrunnsjobber eller sikkerhetskritiske endringer | `qa-security` |
| Pilot, produksjonsutrulling, release readiness eller go/no-go | `release-readiness` etter relevante fag-Skills |

`qa-security` og `release-readiness` er obligatoriske før produksjonsutrulling.

## Arbeidsrekkefølge

For nye brukerfunksjoner: produktvurdering, iOS-/UX-vurdering, backend ved behov, implementering, QA.

For automatisk kampanjeinnhenting: kampanjeovervåking, innholds- og kildekvalitet, backend og lagring, QA, manuell redaksjonell godkjenning.

For pilot eller produksjon: relevante fag-Skills, QA/security, release-readiness og eksplisitt go/no-go.

## Stopp før

Forklar situasjonen før irreversible databaseendringer, sletting av vesentlig kode eller data, endringer i autentisering eller tilgangskontroll, håndtering av hemmeligheter, produksjonsutrulling eller større avvik fra produktbriefen.

## Ferdigdefinisjon

Rapporter hva som ble endret, berørte filer, Skills brukt når relevant, tester kjørt eller hvorfor tester ble hoppet over, antakelser samt gjenværende risiko eller oppfølging.
