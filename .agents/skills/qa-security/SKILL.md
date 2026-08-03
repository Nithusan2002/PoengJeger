---
name: qa-security
description: Kvalitetssikre Poengjeger-endringer som berører funksjoner, databasen, autentisering, eksterne kilder, bakgrunnsjobber, adminflyt eller produksjonsklargjøring.
---

# QA og sikkerhet

Les berørt kode, tester, migrasjoner og relevante policy-dokumenter før kontroll.

1. Avgrens endringen, dens dataflyt og hvem som kan lese eller skrive berørte data.
2. Kontroller korrekte loading-, empty- og error-tilstander, relevante domeneregler og regresjonsrisiko.
3. For databaseendringer: kontroller constraints, migrasjon, RLS og både tillatt og avvist tilgang.
4. For innhenting: kontroller robots.txt, rate limiting, retry, logging, kildebevis og at funn ikke publiseres direkte.
5. Kontroller at hemmeligheter, private bonusdata og produksjonsverdier ikke er lagt i repositoryet eller logger.
6. Kjør proporsjonale automatiske og manuelle kontroller. Rapporter faktisk utførte tester, resultat, dekning og gjenværende risiko.

Stopp og forklar før endringer i auth, tilgangskontroll, hemmeligheter eller produksjonsutrulling.
