# Roadmap

Dette er en omfangsoversikt, ikke en leveringsforpliktelse. Endre den når en beslutning påvirker rekkefølge eller MVP.

## Nåværende MVP-grunnlag

- iOS-app i SwiftUI.
- Brukervalg av relevante bonusprogrammer.
- Tett, skannbar personlig feed med aktive kampanjer, detaljer, filtrering og favoritter.
- Begrensede relevante varsler.
- Supabase-datamodell med redaksjonell kampanjeadministrasjon.
- Kandidatkø som kan promotere funn til utkast, aldri direkte til publisert kampanje.
- Enkel Lær-fane med programguider som forklarer strategi, vanlige feller og aktive kampanjer per bonusprogram uten å innføre en blogg- eller nyhetsflate.

## Neste valideringer

1. Verifiser den komplette redaksjonelle arbeidsflyten med representative kampanjer, inkludert draft-redigering og publisering. Bruk `docs/editorial-qa-checklist.md`.
2. Verifiser den nye skannbare feeden visuelt med representative kampanjer, Dynamic Type, mørk modus og backenddata.
3. Velg og analyser minst tre eksplisitt godkjente kilder før automatisert overvåking bygges.
4. Stram inn adminverktøyet med bedre session-håndtering, rolleadministrasjon og QA før bredere intern bruk.

## Ikke i MVP uten ny beslutning

- Tilkobling til bonuskontoer eller private saldi.
- Full reisemotor eller automatisk bestilling.
- Sosialt nettverk og omfattende gamification.
- Avanserte AI-assistenter.
- Bred støtte for alle bonusprogrammer ved lansering.
- Generisk innholds-, nyhets- eller bloggseksjon.
