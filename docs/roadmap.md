# Roadmap

Dette er en omfangsoversikt, ikke en leveringsforpliktelse. Endre den når en beslutning påvirker rekkefølge eller MVP.

## Nåværende MVP-grunnlag

- iOS-app i SwiftUI.
- Første produktfase er eksplisitt begrenset til EuroBonus og Trumf.
- Brukervalg av relevante bonusprogrammer innen EuroBonus og Trumf først.
- Hovedvanen er "sjekk før du handler": søk butikk eller kategori før kjøp, se opptjeningsmuligheter og følg riktig handoff.
- Butikksider viser vanlig opptjening, aktive kampanjer, alle relevante mekanismer og beste redaksjonelt definerte kombinasjon.
- Kampanjefeed beholdes som sekundær utforskflate og "populært akkurat nå", ikke som eneste kjerneløkke.
- Begrensede relevante varsler.
- Supabase-datamodell med redaksjonell kampanjeadministrasjon.
- Supabase-datamodell utvides med butikker, opptjeningsmetoder, satser og redaksjonelle kombinasjoner.
- Kandidatkø som kan promotere funn til utkast, aldri direkte til publisert kampanje.
- Enkel Guide-fane med læringsstier som forklarer EuroBonus- og Trumf-økosystemene, strategi, vanlige feller og aktive kampanjer uten å innføre en blogg- eller nyhetsflate.
- Design- og brukerflytretningen er dokumentert i `docs/design-and-user-flow.md`.

## Neste valideringer

1. Verifiser den komplette redaksjonelle arbeidsflyten med representative kampanjer, inkludert draft-redigering og publisering. Bruk `docs/editorial-qa-checklist.md`.
2. Verifiser den nye skannbare feeden visuelt med representative kampanjer, Dynamic Type, mørk modus og backenddata.
3. Juster eksisterende SwiftUI-flyt mot `docs/design-and-user-flow.md`, spesielt Hjem, butikksøk, butikkside, Guide og kampanjedetalj.
4. Velg og analyser eksplisitt godkjente kilder for EuroBonus og Trumf før automatisert overvåking utvides.
5. Stram inn adminverktøyet videre med bedre session-håndtering og QA før bredere intern bruk. Første forenkling er gjort for én admin: kandidatkøen prioriterer lag draft/avvis fremfor flertrinns review.

## Ikke i MVP uten ny beslutning

- Tilkobling til bonuskontoer eller private saldi.
- Full reisemotor eller automatisk bestilling.
- Sosialt nettverk og omfattende gamification.
- Avanserte AI-assistenter.
- Bred støtte for alle bonusprogrammer ved lansering.
- Nye poengsystemer før EuroBonus og Trumf er validert.
- Generisk innholds-, nyhets- eller bloggseksjon.
- Hard betalingsmur rundt butikk-/kategorisøk, beste kombinasjon eller nødvendig handoff-informasjon.
- Automatisk publisering av butikkopptjening eller kombinasjoner uten redaksjonell kontroll.
