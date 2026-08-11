# Source Onboarding Template

Bruk denne malen før en ny kilde legges inn i `source_registry` eller en connector bygges.

## Kilde

- Navn:
- Eier/utgiver:
- Domene:
- Start-URL:
- Relevante URL-mønstre:
- Ekskluderte URL-mønstre:
- Tilknyttet bonusprogram:
- Ansvarlig redaktør:

## Godkjenning

- Kildetype: offisielt API, RSS/Atom, strukturert data, sitemap, offentlig HTML, tillatt nettleserautomatisering eller manuell kontroll.
- Robots.txt-status:
- Vilkår kontrollert:
- Krever innlogging, CAPTCHA, betalingsmur eller teknisk omgåelse:
- Tillatt for automatisert kontroll:
- Dato for godkjenning:

## Hentemetode

- Foreslått `parser_key`:
- Kontrollfrekvens:
- User-agent:
- Rate limit:
- Timeout:
- Retry-policy:
- Bruk av ETag eller Last-Modified:
- Cachebehov:

## Datafelt

- Tittel:
- Sammendrag:
- Bonusverdi:
- Startdato:
- Sluttdato:
- Krav/vilkår:
- Program:
- Kategori:
- Kildebevis:
- Felter som ofte mangler:

## Kvalitet og risiko

- Forventet datakvalitet:
- Kjente feilkilder:
- Mulige duplikater mot eksisterende kilder:
- Målrettede eller medlemsavhengige tilbud:
- Finansielle produkter eller kredittkortvilkår:
- Kommersielle forhold:
- Sikkerhetsnivå:

## Stoppkriterier

Stopp eller deaktiver kilden ved:

- gjentatte 403- eller 429-feil
- endrede vilkår eller robots.txt som gjør innhenting uklar
- krav om innlogging, CAPTCHA eller omgåelse
- systematisk feil bonusverdi, dato eller vilkår
- høy andel duplikater eller irrelevante kandidater

## Testkrav

- Fixture for normal respons.
- Fixture for manglende dato.
- Fixture for endret bonusverdi.
- Fixture for tom respons.
- Kontroll av timeout eller blokkering.
- Kontroll av gjentatt kjøring og deduplisering.

## Beslutning

- Status: godkjent, avvist eller parkert
- Begrunnelse:
- Neste kontroll:
- Lenke til migrasjon eller seed-endring:
