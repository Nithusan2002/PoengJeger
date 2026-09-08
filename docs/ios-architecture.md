# iOS-arkitektur

Dette dokumentet er den operative arkitekturstandarden for Poengjegers iOS-app. Målet er en enkel, feature-orientert MVVM-arkitektur som gir tydelige grenser og god testbarhet uten å overdesigne MVP-en.

## Lag og ansvar

### View

SwiftUI-views skal primært:

- rendre tilstand og sende brukerhandlinger videre
- eie kortvarig, rent visuell state som fokus, navigasjon, sheet-visning og ekspanderte seksjoner
- modellere loading-, empty- og error-tilstander eksplisitt
- ivareta Dynamic Type, VoiceOver, kontrast, mørk modus og redusert bevegelse

Views skal ikke eie omfattende filtrering, rangering, formattering, IO-koordinering eller feature-spesifikke analytics-regler.

### ViewModel

Bruk en feature-spesifikk `@Observable` ViewModel når skjermen har ett eller flere av disse behovene:

- flere samvirkende state-verdier
- avledet presentasjonsdata eller omfattende formattering
- asynkrone brukerhandlinger
- loading-, empty-, error- eller processing-state som tilhører funksjonen
- analytics-koordinering knyttet til brukerhandlinger
- logikk som bør enhetstestes uten å rendre SwiftUI

En ViewModel skal være `@MainActor` når den eier UI-observert state. Den skal ikke bli et nytt globalt miljø. Avhengigheter sendes inn eksplisitt, og domeneregler delegeres til use cases eller domenemodeller.

En egen ViewModel er ikke nødvendig for en enkel komponent som bare renderer input og har én lokal visuell `@State`.

### Domain

`Domain` inneholder modeller, use cases og forretningsregler som søk, rangering, gyldighet og kombinasjonsvalg. Domenelogikk skal være uavhengig av SwiftUI og datakilden og testes direkte.

### Data

`Data` implementerer repositories, Supabase-kommunikasjon, mapping og caching. Views skal ikke bruke `URLSession`, Supabase eller konkrete repository-implementasjoner direkte.

### AppEnvironment

`AppEnvironment` er appens dependency container og eier delt app-/session-state samt overordnet lasting. Det skal ikke samle skjermspesifikke filtre, presentasjonsregler eller lokal UI-state. Feature-ViewModels kan koordinere kall gjennom miljøet inntil en smalere dependency er naturlig.

## Filstruktur

Hver feature ligger samlet under `Features/<Feature>`:

```text
Features/Feed/
  FeedView.swift
  FeedViewModel.swift
  FeedComponents.swift
  FeedPresentation.swift
```

- Hold hovedviewet fokusert på skjermens struktur.
- Flytt større, selvstendige SwiftUI-komponenter til `<Feature>Components.swift`.
- Flytt ren presentasjonslogikk til ViewModel eller en navngitt presenter/helper.
- Ikke opprett ekstra protokoller eller mapper uten et konkret test-, variasjons- eller gjenbruksbehov.

## Endringspraksis

- Refaktorer trinnvis og funksjonsnøytralt; ikke kombiner en stor arkitekturomlegging med nye produktkrav.
- Bevar eksisterende navigasjon, analytics, tilgjengelighet og loading-/error-adferd under uttrekk.
- Legg tester rundt regler og state som flyttes ut av views.
- Kjør relevante enhetstester og bygg etter kodeendringer.
- Ikke innfør ViewModels bare for å kunne si at arkitekturen er «ren MVVM».
- Vurder arkitekturgrensen når et view blir vanskelig å lese, endre eller teste; linjetall er et signal, ikke en absolutt regel.

## Review-sjekkliste

Ved nye eller vesentlig endrede SwiftUI-features:

1. Ligger forretningsregler i Domain/use cases?
2. Ligger datatilgang bak repositories?
3. Er feature-state og asynkrone handlinger utenfor store views?
4. Er kortvarig visuell state fortsatt lokal i viewet?
5. Er loading-, empty-, error- og processing-state synlig og testbar?
6. Er viktige state-overganger og regler dekket av tester?
7. Har endringen bevart tilgjengelighet og analytics?

