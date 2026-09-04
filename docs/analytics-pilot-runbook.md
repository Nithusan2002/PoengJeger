# Analytics pilot-runbook

Denne runbooken beskriver den ukentlige sanity-sjekken for Poengjegers interne pilotmåling.

## Formål

Sjekken skal bekrefte at kjerneflyten "sjekk før du handler" måles komplett nok til å gi beslutningsgrunnlag før premiumfunksjoner vurderes.

Bruk denne runbooken til å svare på fire spørsmål:

- Åpner brukere appen flere ganger?
- Starter de butikk- eller kategorisøk?
- Leder søk til butikkdetaljer og beste kombinasjon?
- Åpner de handoff eller ekstern destinasjon ofte nok til at appen påvirker handling?

## Tilgang

Analytics-readback krever innlogget redaksjonell Supabase-tilgang.

`analytics_sanity_7d` er et aggregert view over `product_events`. Det viser ikke rå `anonymous_user_id`, `session_id` eller fritekstsøk. Viewet bruker `security_invoker`, så eksisterende RLS på `product_events` gjelder fortsatt.

Ikke legg JWT, service role key eller andre hemmeligheter i repoet, dokumenter, screenshots eller chat.

## Kjøring

Hent en kortlevd Supabase JWT for en redaksjonell bruker, og kjør:

```bash
SUPABASE_AUTH_TOKEN="<redaksjonell-jwt>" node scripts/check-analytics-sanity.mjs
```

Alternativt:

```bash
node scripts/check-analytics-sanity.mjs --auth-token "<redaksjonell-jwt>"
```

For maskinlesbar output:

```bash
SUPABASE_AUTH_TOKEN="<redaksjonell-jwt>" node scripts/check-analytics-sanity.mjs --json
```

For å kontrollere at anonym lesing fortsatt er blokkert:

```bash
node scripts/check-analytics-sanity.mjs
```

Forventet resultat uten auth er `401 permission denied`.

## Ukentlig sjekk

Kjør scriptet minst en gang per pilotuke og noter tallene for:

- `app_opened`
- `store_search_started`
- `store_search_result_opened`
- `store_detail_opened`
- `best_combination_viewed`
- `handoff_opened`
- `external_destination_opened`
- `campaign_detail_opened`
- `guide_opened`
- `favorite_added`
- `favorite_removed`

Se særlig på forholdet mellom:

- `store_search_started` og `store_search_result_opened`
- `store_search_result_opened` og `store_detail_opened`
- `store_detail_opened` og `handoff_opened`
- `handoff_opened` og `external_destination_opened`
- `app_opened` og antall distinkte brukere

## Røde flagg

Undersøk før videre pilot hvis:

- `store_search_started` øker, men `store_search_result_opened` står stille.
- `store_detail_opened` finnes, men `best_combination_viewed` mangler for butikker som skal ha kombinasjon.
- `handoff_opened` er nær null etter at pilotbrukere har fått konkrete testoppgaver.
- `external_destination_opened` er nær null når handoff er høy.
- `campaign_detail_opened` eller `guide_opened` er null over flere pilotdager med relevant innhold.
- `favorite_added` og `favorite_removed` er like høye uten tydelig forklaring.
- Antall `user_count` er høyere enn forventet intern/pilotbruk, som kan tyde på teststøy eller installasjons-ID-reset.

## Personvernregler

Ikke analyser eller eksporter:

- fritekstsøk
- rå `anonymous_user_id`
- rå `session_id`
- private bonuskontoer
- saldoer
- transaksjoner
- handlehistorikk

Hvis en analyse krever rå eventrader, bruk bare redaksjonell/admin-tilgang, hold uttrekket lokalt og slett det når avklaringen er ferdig.

## Beslutningsbruk

Analytics fra pilot skal bare brukes som beslutningsstøtte. Ikke bygg betalingslogikk før pilotdata viser gjentatt verdi i minst to av signalene definert i `docs/analytics-plan.md`.

Ved tvil: prioriter forbedring av kjerneflyten før nye premiumflater.
