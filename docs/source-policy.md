# Kildepolicy

## Godkjenning

Automatisk overvåking er kun tillatt for kilder som er eksplisitt registrert og godkjent i `source_registry`. Nye domener skal ikke overvåkes uten redaksjonell godkjenning.

Godkjente kilder kan være offisielle kampanjesider, bonusprogrammer, banker og kortutstedere, butikker, offentlige RSS-feeder, lovlig mottatte nyhetsbrev og offentlige pressesider.

## Kilderegister

For hver kilde skal den operative konfigurasjonen minst angi tilknyttet `campaign_sources`-rad, hentemetode, startadresse, parsernøkkel ved behov, kontrollfrekvens, aktiv status og sist kontroll. Før automatisering må redaksjonen i tillegg dokumentere domene, tillatte og ekskluderte URL-mønstre, robots.txt-status, bruksvilkår, ansvarlig redaktør og siste feil.

## Innhenting

Prioriter: offisielt API, RSS/Atom, offentlig strukturert data, sitemap/kampanjeindeks, offentlig HTML, tillatt nettleserautomatisering og til slutt manuell kontroll.

Respekter robots.txt, bruksvilkår og hastighetsgrenser. Bruk identifiserbar user-agent, caching samt ETag eller Last-Modified når tilgjengelig. Stopp ved blokkering eller gjentatte 403/429-feil. Ikke omgå CAPTCHA, innlogging, betalingsmur eller tekniske sperrer. Ikke hent private brukerdata.

## Bevis og kontroll

Lagre kildeadresse, kontrolltidspunkt og relevante kildebevis når lovlig og nødvendig. Manglende data skal være `null`, aldri en gjetning. Ikke presenter en kampanje som verifisert uten dokumentert kilde og kontrolltidspunkt.
