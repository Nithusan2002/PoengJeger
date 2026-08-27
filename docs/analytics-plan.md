# Analytics-plan for premiumvalidering

Dette dokumentet definerer minimumsmålingene Poengjeger trenger før betalingslogikk eller abonnement bygges.

## Formål

Målet er å avgjøre om brukerne får nok gjentatt verdi fra "sjekk før du handler" til at premiumabonnement er verdt å bygge.

Analytics skal svare på tre spørsmål:

- Kommer brukere tilbake for å sjekke butikk, kategori eller kampanje før kjøp?
- Bruker de funksjoner som peker mot betalingsvilje, som varsler, lagring, filtre og guider?
- Hvilke premiumkandidater bør bygges først hvis signalene er sterke nok?

## Prinsipper

- Mål bare produktbruk som trengs for MVP-validering.
- Ikke lagre private bonuskontoer, saldoer, transaksjoner eller handlehistorikk.
- Ikke logg fritekstsøk ukritisk hvis søket kan inneholde persondata.
- Bruk pseudonym bruker-ID eller installasjons-ID.
- Skill produktanalytics fra redaksjonelle fakta og kommersielle vurderinger.

## Eventer

| Event | Når logges det | Viktige properties | Hvorfor |
| --- | --- | --- | --- |
| `app_opened` | Når appen åpnes aktivt | `source`, `days_since_last_open` | Måler returbruk og vane. |
| `program_selected` | Når bruker velger eller fjerner bonusprogram | `program_id`, `selected`, `selected_program_count` | Viser om personalisering faktisk settes opp. |
| `store_search_started` | Når bruker åpner eller starter butikksøk | `entry_point` | Måler bruk av "sjekk før du handler"-kjernen. |
| `store_search_result_opened` | Når bruker åpner butikk fra søk/kategori | `store_id`, `category_id`, `rank`, `entry_point` | Viser om søk leder til faktisk vurdering. |
| `store_detail_opened` | Når butikkside åpnes | `store_id`, `program_ids`, `has_active_campaign`, `has_best_combination` | Måler hovedflaten for opptjeningsvalg. |
| `best_combination_viewed` | Når beste kombinasjon vises på butikkside | `store_id`, `program_ids`, `mechanism_count` | Måler om premiumrelevant beslutningsverdi eksponeres. |
| `handoff_opened` | Når bruker åpner "Slik gjør du det" | `store_id`, `destination_type`, `requires_warning` | Måler intensjon før ekstern handel. |
| `external_destination_opened` | Når bruker trykker videre til portal eller kilde | `store_id`, `destination_type`, `program_id` | Sterkt signal om at appen påvirker handling. |
| `campaign_detail_opened` | Når kampanjedetalj åpnes | `campaign_id`, `program_ids`, `entry_point` | Måler interesse for kampanjer og feed. |
| `favorite_added` | Når bruker lagrer butikk, kampanje eller kjøpsplan | `favorite_type`, `entity_id` | Signal om gjentatt behov og premiumgrense. |
| `favorite_removed` | Når bruker fjerner lagring | `favorite_type`, `entity_id` | Viser om lagring har varig verdi. |
| `filter_applied` | Når bruker bruker filter/sortering | `surface`, `filter_type`, `selected_count` | Viser behov for lagrede filtre eller avansert sortering. |
| `notification_enabled` | Når bruker aktiverer varsler | `scope`, `program_ids` | Måler betalingsrelevant ønske om timing. |
| `notification_opened` | Når bruker åpner appen fra varsel | `notification_type`, `entity_id` | Viser om varsler gir reell bruk. |
| `notification_disabled` | Når bruker slår av varsler | `scope` | Risikoindikator for støy. |
| `guide_opened` | Når bruker åpner Guide-innhold | `guide_id`, `program_id`, `entry_point` | Måler om dypere guider kan bli premium. |
| `premium_candidate_used` | Når bruker bruker en funksjon som kan bli premium | `candidate_type`, `surface` | Samler signal for senere betalingsbeslutning. |

## Premiumkandidater og signaler

| Premiumkandidat | Nødvendig signal før bygging | Ikke bygg hvis |
| --- | --- | --- |
| Mer presise varsler | Mange aktiverer gratisvarsler, få slår dem av, og varselåpning gir reell returbruk. | Varsler skrus ofte av eller åpnes sjelden. |
| Butikk-/kategori-varsler | Brukere søker gjentatt etter samme butikk/kategori eller lagrer dem. | Søk er sporadisk og uten gjentakelse. |
| Lagrede filtre | Filterbruk gjentas på samme flater over flere økter. | Filtre brukes mest én gang ved onboarding eller testing. |
| Ubegrensede favoritter | Aktive brukere lagrer ofte og treffer en moderat gratisgrense. | De fleste lagrer få eller ingen elementer. |
| Historikk | Brukere prøver å finne tidligere kampanjer eller utløpte tilbud. | Bruken handler nesten bare om nåværende kampanjer. |
| Dypere guider | Guide-innhold åpnes ofte og leder tilbake til butikk/kampanje. | Guider leses lite eller fungerer bare som engangsopplæring. |
| Ukentlig oppsummering | Brukere kommer tilbake ukentlig og åpner flere detaljer per økt. | Returbruk er svak eller veldig ujevn. |

## Beslutningsterskler

Før premium bygges bør minst to av disse signalene være sanne i en pilotperiode:

- En meningsfull andel aktive brukere kommer tilbake ukentlig.
- Brukere åpner butikk- eller kampanjedetaljer i flere økter, ikke bare første dag.
- Handoff eller ekstern åpning skjer ofte nok til å vise at appen påvirker handling.
- Varsler eller favoritter brukes av en tydelig gruppe aktive brukere.
- Minst én premiumkandidat har gjentatt bruk uten å være nødvendig for grunnverdien.

Tersklene bør tallfestes etter første interne/pilotbruk, når vi vet omtrent hvor mange brukere og kampanjer som inngår.

## Lagring i MVP

Anbefalt første løsning er en enkel Supabase-tabell for produkt-events, ikke en ekstern analytics-SDK.

Grunner:

- Lavere avhengighetsrisiko.
- Full kontroll over hvilke properties som lagres.
- Enklere å holde data nært eksisterende Supabase-oppsett.
- Nok for MVP-validering og manuelle analyser.

Foreslått minimumsskjema:

- `id`
- `occurred_at`
- `event_name`
- `anonymous_user_id`
- `session_id`
- `surface`
- `entity_type`
- `entity_id`
- `properties`
- `app_version`
- `platform`

Eventdata bør ha RLS som hindrer klienten i å lese andres events. Klienten bør bare kunne skrive tillatte eventer med begrenset payload.

## Neste tekniske oppgave

Lag en Supabase-migrasjon for `product_events` og en liten Swift-klient for å sende tillatte events. Start med eventene som måler kjerneløkken:

1. `app_opened`
2. `store_search_started`
3. `store_search_result_opened`
4. `store_detail_opened`
5. `handoff_opened`
6. `external_destination_opened`
7. `campaign_detail_opened`
8. `favorite_added`
9. `filter_applied`
10. `guide_opened`

Betalingslogikk skal fortsatt vente.
