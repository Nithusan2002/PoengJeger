# Ingestion Connectors

Dette dokumentet beskriver første connector-spike for automatisert
innholdsoppdagelse. Alle funn skal lagres som `ingestion_candidates` og må
gjennom redaksjonell review før de kan promoteres til `draft`.

## Edge Function

`supabase/functions/ingest-campaign-candidates` kjører godkjente aktive kilder
fra `source_registry`.

Krav til miljøvariabler:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `INGESTION_RUN_SECRET`
- `POENGJEGER_INGESTION_USER_AGENT` valgfri, men anbefalt

Kjøring:

```sh
curl -X POST "$SUPABASE_FUNCTION_URL/ingest-campaign-candidates?limit=50" \
  -H "Authorization: Bearer $INGESTION_RUN_SECRET"
```

Begrenset kjøring:

```sh
curl -X POST "$SUPABASE_FUNCTION_URL/ingest-campaign-candidates?source=trumf_netthandel&limit=10" \
  -H "Authorization: Bearer $INGESTION_RUN_SECRET"
```

## Første kilder

| Kilde                  | Parser                   | Status  | Metode                             | Robots/status                                                                                            | Kommentar                                                                                                           |
| ---------------------- | ------------------------ | ------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Trumf Netthandel       | `trumf_netthandel`       | Aktiv   | Offentlig JSON-feed                | `trumfnetthandel.no/robots.txt` blokkerer ikke `/cashback`; CDN `robots.txt` returnerte 404 ved kontroll | Bruker `https://wlp.tcb-cdn.com/trumf/notifierfeed.json`. Lager kandidater for butikkbonus, ikke ferdige kampanjer. |
| re:member reward       | `remember_reward`        | Aktiv   | Offentlig HTML med `__NEXT_DATA__` | `www.remember.no/robots.txt` tillater `/reward/rabatt`                                                   | Parser aktive butikker og cashback-satser. Finansielt/kortrelatert innhold krever manuell kontroll.                 |
| SAS EuroBonus Shopping | `sas_eurobonus_shopping` | Inaktiv | Offentlig browser-extension API    | `onlineshopping.loyaltykey.com/robots.txt` returnerte 403 ved kontroll                                   | Connectoren finnes, men kilden er deaktivert i `source_registry` til robots/vilkår er eksplisitt godkjent.          |

## Sikkerhet og kvalitet

- Funksjonen krever `INGESTION_RUN_SECRET` og bruker service role bare
  server-side.
- Kilder må være aktive i `source_registry`; nye domener skal ikke hentes uten
  ny godkjenning.
- HTTP-kall har timeout og identifiserbar user-agent.
- Duplikater stoppes med eksisterende `normalized_hash`-indeks.
- Manglende bonusverdi markeres i `metadata.missing_bonus_value`; verdier
  gjettes ikke.
- Kandidater inneholder rå JSON/HTML-utdrag per funn i `raw_content` og
  kilde-URL i `source_url`.
- Det publiseres ingen kampanjer automatisk.

## Kjente begrensninger

- Første versjon lager mange butikk-/partnerkandidater, ikke fullverdige
  tidsavgrensede kampanjer.
- Edge Function bruker ikke Playwright. DOM-tunge kilder som DNB, OBOS, NAF og
  LOfavør bør vurderes separat.
- `normalized_hash` inkluderer bonusbeskrivelsen. Endrede satser gir derfor ny
  kandidat for review.
