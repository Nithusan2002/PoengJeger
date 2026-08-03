# Arkitekturbeslutninger

## ADR-011: Instruksjoner organiseres i regler, Skills og prosjektdokumentasjon
- Status: Vedtatt
- Bakgrunn: Ett omfattende instruksjonsdokument blandet varige regler, prosjektfakta og arbeidsprosedyrer. Det gjør det vanskeligere å finne relevant kontekst og å bruke samme prosess konsekvent.
- Beslutning: `AGENTS.md` inneholder varige regler og når en arbeidsflyt er obligatorisk. `.agents/skills/` inneholder gjenbrukbare prosedyrer. `docs/` inneholder prosjektfakta, policyer og teknisk referanse.
- Konsekvens: Instruksjonene blir lettere å vedlikeholde og mer målrettede. Nye Skills må holdes korte og peke til dokumentasjonen fremfor å duplisere den.

## ADR-001: SwiftUI-app med feature-orientert, lagdelt arkitektur
- Status: Foreslått
- Bakgrunn: MVP-en trenger rask utvikling, enkel navigasjon og god separasjon mellom UI, domene og data.
- Beslutning: Appen bygges i SwiftUI med feature-orientert struktur og lagene Presentation, Domain og Data.
- Konsekvens: Lavere kompleksitet enn full clean architecture, men fortsatt god testbarhet og tydelige grenser.

## ADR-002: Supabase/PostgreSQL som eneste sannhetskilde for kampanjeinnhold
- Status: Foreslått
- Bakgrunn: Produktet er innholds- og feed-drevet og trenger tydelig datakvalitet, rollegrenser og historikk.
- Beslutning: Kampanjer, kilder, vurderinger, preferanser og favoritter lagres i PostgreSQL via Supabase.
- Konsekvens: Enkel backend for MVP, men krever gode migrasjoner, RLS og moderat normalisering.

## ADR-003: Redaksjonell vurdering skilles fra dokumenterte fakta
- Status: Foreslått
- Bakgrunn: Produktbriefen krever troverdighet og tydelig skille mellom kildebasert informasjon og redaksjonelle vurderinger.
- Beslutning: Kildehenvisninger og kontrolltidspunkt lagres separat fra redaksjonell score og begrunnelse.
- Konsekvens: Litt mer modellkompleksitet, men bedre tillit, revisjonsspor og forklarbarhet.

## ADR-004: Enkelt adminverktøy utenfor iOS-appen
- Status: Foreslått
- Bakgrunn: MVP trenger administrasjon av kampanjeinnhold, men sluttbrukerappen skal fokusere på konsum, ikke redaksjon.
- Beslutning: Kampanjeadministrasjon løses først som en enkel intern web-/Supabase-basert flyt.
- Konsekvens: Lavere kompleksitet i iOS-appen og raskere vei til testbar innholdsproduksjon.

## ADR-005: Begrenset lokal caching
- Status: Foreslått
- Bakgrunn: Feed og preferanser bør oppleves raske, men full offline-synk er unødvendig i MVP.
- Beslutning: Kun sist hentede feed, preferanser og favoritter caches lokalt.
- Konsekvens: Bedre brukeropplevelse uten å bygge tung synkroniseringslogikk.

## ADR-006: Forklarbar, enkel rangering i MVP
- Status: Foreslått
- Bakgrunn: Produktbriefen sier at rangering må være forståelig og ikke oppleves vilkårlig.
- Beslutning: MVP bruker enkel redaksjonell score og tekstlig begrunnelse, ikke kompleks algoritmisk ranking.
- Konsekvens: Høyere forklarbarhet og enklere vedlikehold, men mindre automatisering.

## ADR-007: iOS-klienten integreres først mot Supabase REST via URLSession
- Status: Foreslått
- Bakgrunn: MVP-en trenger ekte backend-data raskt, men prosjektet skal unngå nye avhengigheter uten tydelig behov.
- Beslutning: Første iOS-integrasjon mot Supabase bygges med `URLSession` og PostgREST-endepunkter, med `SUPABASE_URL` og `SUPABASE_ANON_KEY` lest fra appkonfigurasjon.
- Konsekvens: Lavere avhengighetsrisiko og full kontroll over datamapping, men mer manuell API-kode enn ved bruk av et dedikert Supabase-SDK.

## ADR-008: Automatisert innholdsoppdagelse går via kandidatkø før publisering
- Status: Foreslått
- Bakgrunn: Poengjeger trenger etter hvert mer effektiv innhenting av kampanjer, men produktet krever tydelig kildeintegritet og redaksjonell kontroll.
- Beslutning: Alt automatisk eller halvautomatisk oppdaget kampanjeinnhold skal først lagres i en egen kandidatmodell som `ingestion_candidates`, og må gjennom admin-review før det kan bli en publisert `campaign`.
- Konsekvens: Litt mer backend- og admin-kompleksitet tidlig, men langt lavere risiko for feilpublisering, bedre revisjonsspor og en tryggere vei til senere scraping, feeds eller API-baserte kilder.

## ADR-009: Supabase-klientkonfigurasjon holdes utenfor repositoryet
- Status: Foreslått
- Bakgrunn: iOS-appen trenger Supabase-host og klientnøkkel i runtime, men disse skal ikke ligge hardkodet i `project.pbxproj` eller andre committede filer.
- Beslutning: Xcode-targeten leser `SUPABASE_HOST` og `SUPABASE_PUBLISHABLE_KEY` fra en lokal `AppSecrets.local.xcconfig` som inkluderes via en committet `AppConfig.xcconfig`. Repositoryet inneholder kun en eksempel-fil for oppsett, og legacy `anon`-nøkkel er fjernet fra klientkonfigurasjonen.
- Konsekvens: Lavere risiko for lekkasje av miljøverdier og enklere rotasjon av nøkler, men utviklere må opprette lokal konfigurasjon før appen kan hente live-data.

## ADR-010: Første admin-flyt bygges som databaseprimitiver, ikke eget UI
- Status: Foreslått
- Bakgrunn: Produktet trenger en reell redaksjonell flyt for å vurdere og promotere `ingestion_candidates`, men et fullt admin-UI vil forsinke læring om selve innholdsprosessen.
- Beslutning: Første admin-MVP bygges som en Supabase-basert kø-visning og eksplisitte review-/promote-funksjoner i databasen. Kandidater kan bare promoteres til `draft`, aldri publiseres direkte.
- Konsekvens: Raskere vei til testbar innholdsoperasjon og lavere publiseringsrisiko, men redaksjonen må foreløpig bruke Supabase Studio eller SQL frem til et eget admin-UI bygges. Funksjonene må derfor være brukbare både via SQL Editor og senere RPC-kall.

## ADR-012: Første live adminflate bygges som separat internt webverktøy
- Status: Foreslått
- Bakgrunn: Den vanlige iOS-klienten bruker publiserbar nøkkel og skal være enkel, rask og trygg for sluttbrukere. Live redaksjonelle handlinger i samme klient vil blande sikkerhetsgrenser, øke appkompleksitet og skape unødvendig MVP-støy.
- Beslutning: Første faktiske adminflate bygges som et separat internt webverktøy over de eksisterende Supabase-primitivene for kø, review og promotering. iOS-appen kan beholde en preview-only adminskjerm for intern demonstrasjon, men ikke som operativ liveflate.
- Konsekvens: Bedre sikkerhet og tydeligere rollefordeling mellom sluttbrukerprodukt og redaksjonsdrift. Teamet må bygge og drifte én ekstra intern overflate, men unngår å presse admin-auth og arbeidsflyt inn i forbrukerappen for tidlig.

## ADR-013: Adminautorisasjon forankres i databasebaserte roller
- Status: Foreslått
- Bakgrunn: Eksisterende `is_admin()` baserte seg kun på JWT `app_metadata`. Det er upraktisk for et lite internt team fordi rolleendringer da krever auth-adminoperasjoner utenfor den vanlige datamodellen.
- Beslutning: Poengjeger innfører `editorial_user_roles` i PostgreSQL som primær sannhetskilde for interne roller. `public.current_editorial_role()` og `public.is_admin()` leser først aktiv rolle fra databasen og faller bare tilbake til eldre JWT-metadata for bakoverkompatibilitet.
- Konsekvens: RLS og RPC-er kan styres med vanlig migrasjonsdrevet datamodell, og interne rolleendringer blir enklere å auditere. Samtidig må admin bootstrap håndteres forsvarlig, fordi bare eksisterende `admin`-rolle kan tildele nye roller etter oppstart.
