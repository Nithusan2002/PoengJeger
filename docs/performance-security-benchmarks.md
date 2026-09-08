# Ytelses- og sikkerhetsmål

Dette dokumentet definerer hvordan Poengjeger vurderer benchmarkene før pilot.
En enkelt rask kjøring er ikke nok til å erklære et mål oppfylt.

## Mål og målemetode

| Område | Mål | Praktisk definisjon |
| --- | --- | --- |
| Første brukbare innhold | p95 ≤ 2 000 ms | Fra `AppEnvironment` opprettes til første lasting ender i brukbart innhold eller en eksplisitt feiltilstand. Måles i Release-build på fysisk enhet. |
| API-respons | p95 ≤ 300 ms | Fra et Supabase REST-kall sendes til transportresponsen er mottatt. Dekoding er ikke inkludert. Bootstrap vurderes også samlet. |
| Stabilitet | Crash-free sessions > 99 % | Måles i App Store Connect etter intern distribusjon/TestFlight. Minst 100 sesjoner kreves før tallet brukes som beslutningsgrunnlag. |
| Transport | HTTPS og TLS 1.2+ | Produksjonsklienten konstruerer bare Supabase-URL med `https://`. ATS-unntak skal ikke innføres. TLS-versjon kontrolleres mot produksjonsendepunktet før pilot. |
| Data i ro | Dokumentert leverandørkryptering | Supabase-prosjektets faktiske kryptering og ansvar må bekreftes mot gjeldende leverandørdokumentasjon før pilot. |
| Innholdsbilder | ≤ 200 KB per nedlastet bilde | Gjelder bilder som lastes over nett i brukerflyten. App Store-ikon og andre byggressurser er unntatt. Bilder skal komprimeres og caches. |

## Lokal baseline

Kjør en arkivert eller Release-konfigurert app på minst én støttet fysisk
mellomklasse-enhet. Gjenta kaldstart og relevant brukerflyt minst 20 ganger med
normalt nett, og kontroller i tillegg tregt nett og nettutfall.

Filtrer enhetsloggen på kategorien `Performance`. Loggene inneholder bare:

- benchmarknavn
- varighet og terskelresultat
- tabell-/endepunktnavn uten query-parametere
- HTTP-status eller overordnet utfall

Nøkler, Authorization-header, URL-spørringer og brukerdata skal aldri logges.
Beregn p50 og p95 på de innsamlede varighetene og noter enhet, iOS-versjon,
appversjon, buildtype, nettforhold og antall målinger.

## Pilotport

Før pilot skal teamet:

1. dokumentere en baseline for oppstart, bootstrap og hvert API-endepunkt;
2. kontrollere crash-free sessions i TestFlight/App Store Connect når minst 100 sesjoner finnes;
3. bekrefte TLS og kryptering for produksjonsprosjektet;
4. kontrollere at eventuelle nye nettbilder holder størrelsesbudsjettet;
5. registrere avvik og tiltak uten å skjule treg lasting med innhold som ser ekte ut.

Mål som mangler tilstrekkelige data rapporteres som «ikke målt», ikke bestått.

## Baseline 2026-09-07

Dette er en foreløpig simulatorbaseline, ikke godkjenning av fysisk iPhone.
Målingen brukte Release-build på iPhone 17e-simulator med iOS 26.5, normalt
nett og 20 avsluttede/kaldstartede appprosesser mot konfigurert Supabase-miljø.
Alle forespørsler svarte med HTTP 200.

| Måling | Antall | p50 | p95 | Mål | Foreløpig resultat |
| --- | ---: | ---: | ---: | ---: | --- |
| Første brukbare innhold | 20 | 1 161,2 ms | 1 817,0 ms | ≤ 2 000 ms | Består i simulator |
| Samlet bootstrap | 20 | 643,7 ms | 1 223,7 ms | Informativ | Baseline etablert |
| `bonus_programs` | 20 | 215,5 ms | 692,6 ms | ≤ 300 ms | Består ikke |
| `campaigns` | 20 | 209,1 ms | 692,6 ms | ≤ 300 ms | Består ikke |
| `program_guides` | 20 | 209,6 ms | 731,7 ms | ≤ 300 ms | Består ikke |
| `stores` | 20 | 309,6 ms | 861,6 ms | ≤ 300 ms | Består ikke |

Oppstartsmålet må gjentas på fysisk mellomklasse-enhet. API-avvikene er store
nok til å undersøkes, særlig `stores`, men optimalisering skal vurderes mot
fysisk baseline og faktisk payload før datamodell eller brukerflyt endres.

### Sikkerhetskontroll 2026-09-07

- Direkte kontroll mot konfigurert Supabase-host: TLS 1.2-handshake bestod og
  TLS 1.1 ble avvist.
- Supabase dokumenterer at HTTP-API-ene håndhever SSL, og at data krypteres i
  ro og i transitt i deres delte ansvarsmodell.
- Supabases DPA beskriver AES-256 for disker og sikkerhetskopier samt TLS 1.2
  for nettkommunikasjon.

Leverandørgrunnlag:

- [Supabase: Shared Responsibility Model](https://supabase.com/docs/guides/deployment/shared-responsibility-model)
- [Supabase: Postgres SSL Enforcement](https://supabase.com/docs/guides/platform/ssl-enforcement)
- [Supabase Data Processing Addendum](https://supabase.com/downloads/docs/Supabase%2BDPA%2B231211.pdf)

Kontrollen bekrefter leverandør- og transportlaget. RLS, grants og fravær av
service-role-nøkler må fortsatt inngå i releasekontrollen for selve prosjektet.

## API-optimalisering 2026-09-08

Den opprinnelige `stores`-forespørselen hentet butikker, satser, metoder,
kombinasjoner og steg som ett dypt nestet PostgREST-join. En direkte kontroll
viste omtrent 206 KB respons, p50 269 ms og p95 856 ms. Bare butikkmetadata var
omtrent 26 KB med p95 192 ms.

Lesingen er derfor delt i tre parallelle, eksplisitt publiserte datasett:

- butikkmetadata
- publiserte opptjeningssatser med opptjeningsmetode
- publiserte kombinasjoner med satskoblinger og steg

Klienten setter datasettene sammen med `store_id`. Samlet overført datamengde
for de tre datasettene var omtrent 153 KB i kontrollen, rundt 26 % mindre enn
det nestede svaret. Ingen skjema-, RLS- eller autentiseringsendring var nødvendig.

Ny simulatorbaseline brukte samme Release-buildtype, iPhone 17e-simulator,
iOS 26.5, normalt nett og 40 kaldstarter:

| Måling | Antall | p50 | p95 | Mål | Resultat |
| --- | ---: | ---: | ---: | ---: | --- |
| Første brukbare innhold | 40 | 1 019,4 ms | 1 955,9 ms | ≤ 2 000 ms | Består knapt i simulator |
| Samlet bootstrap | 40 | 459,0 ms | 1 445,8 ms | Informativ | Median forbedret ca. 29 % |
| `stores` | 40 | 241,0 ms | 1 014,5 ms | ≤ 300 ms | Består ikke |
| `store_earning_rates` | 40 | 269,0 ms | 1 293,2 ms | ≤ 300 ms | Består ikke |
| `earning_combinations` | 40 | 265,8 ms | 1 289,7 ms | ≤ 300 ms | Består ikke |

De høye tailverdiene traff flere parallelle endepunkter samtidig og peker på
kald nettverkstilkobling eller ekstern variasjon, ikke bare payloadstørrelse.
300-mskravet kan derfor ikke godkjennes. Neste tiltak bør baseres på fysisk
enhet og kan være lokal cache for sist verifiserte bootstrap, uten å vise cache
som ferske data eller skjule feiltilstand.
