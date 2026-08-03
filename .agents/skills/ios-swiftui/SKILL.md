---
name: ios-swiftui
description: Implementer eller vurder SwiftUI-skjermer, navigasjon, state, lokal caching, varsler, tilgjengelighet og iOS-tester for Poengjeger.
---

# iOS og SwiftUI

Les `docs/product-brief.md`, berørt feature-kode, domenemodeller og tester før endring.

1. Beskriv brukeroppgaven og velg den minste endringen som løser den.
2. Følg eksisterende feature-orienterte lagdeling: UI i `Features`, regler i `Domain`, datatilgang i `Data`.
3. Bruk `NavigationStack`, Swift Concurrency og eksisterende `AppEnvironment` når relevant. Ikke legg til avhengigheter uten tydelig behov.
4. Modellér loading-, empty- og error-tilstander eksplisitt. Ikke skjul feil med data som ser ekte ut.
5. Støtt Dynamic Type, VoiceOver, tilstrekkelig kontrast og mørk modus der skjermen bruker farger.
6. Test viktig domenelogikk og UI-tilstander i forhold til endringens risiko.

Rapporter berørt brukerflyt, tilgjengelighetsvalg, testdekning og eventuelle backendforutsetninger.
