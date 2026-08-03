---
name: campaign-monitoring
description: Design, implementer og kontroller overvåking av godkjente offentlige kampanjekilder i Poengjeger, inkludert connectors, innhenting, endringsdeteksjon, duplikatkontroll og kontrollfrekvens.
---

# Kampanjeovervåking

Les `docs/source-policy.md`, `docs/editorial-policy.md`, `docs/data-model.md`, relevante connectors, migrasjoner og tester.

Før en kilde implementeres, dokumenter navn, domene, sider, autoritet, tilgjengelig API/RSS/strukturert data, robots.txt, vilkår, kontrollfrekvens, datakvalitet og vedlikeholdsbehov. Ikke implementer en connector som krever omgåelse av CAPTCHA, innlogging, betalingsmur eller tekniske sperrer.

Bruk minst komplekse forsvarlige hentemetode i denne rekkefølgen: offisielt API, RSS/Atom, strukturert data, sitemap/indeks, offentlig HTML, tillatt nettleserautomatisering, manuell kontroll.

En connector skal være avgrenset til én kilde eller stabil kildetype, respektere robots.txt og hastighetsgrenser, ha identifiserbar user-agent, caching og timeout, kontrollert retry og behandling av 403, 404, 429 og serverfeil. Den skal være idempotent og aldri gjette manglende data.

Normaliser innhold før sammenligning. Skill mellom ny, endret, forlenget, utløpt eller fjernet kampanje, kosmetisk endring og mulig duplikat. Test med lagrede fixtures, også manglende dato, endret bonus, feilformat, timeout, blokkering, tom respons og gjentatt kjøring.

Alle funn skal være redaksjonelle utkast. Send til kontroll ved manglende eller uklar verdi, mulige målrettede eller finansielle kampanjer, ikke-offisiell kilde, mulig duplikat eller sikkerhetsnivå under 90.
