# Web Surface Strategy

Poengjeger skal ha to separate webflater når begge trengs:

1. Offentlig produktside for presentasjon, venteliste, kontakt og senere app-lenker.
2. Intern adminflate for redaksjonell drift.

## Beslutning

Adminflaten i `admin-tool/` er den prioriterte webflaten før en offentlig
produktside. Den dekker den viktigste MVP-risikoen: at kampanjer, kandidater,
butikker, opptjeningssatser og programguider kan kontrolleres og vedlikeholdes
uten SQL Editor.

Første delte hosting for adminflaten er GitHub Pages via GitHub Actions. Det er
akseptabelt for intern MVP fordi flaten er statisk, ikke bruker service-role key
og all tilgang fortsatt håndheves av Supabase Auth, `editorial_user_roles`, RLS
og RPC-er.

En offentlig side kan vente til Poengjeger trenger testbrukere, app-presentasjon
eller SEO. Den kan starte som en statisk GitHub Pages-side.

## URL-struktur

- Offentlig side: `poengjeger.no` eller GitHub Pages i tidlig fase.
- Admin: `admin.poengjeger.no` eller en separat intern hosting-URL.

Admin skal ikke eksponeres som synlig lenke i vanlig offentlig navigasjon. En
skjult lenke er likevel ikke en sikkerhetsmekanisme. Tilgang skal håndheves med
Supabase Auth, `editorial_user_roles`, RLS og admin-RPC-er.

GitHub Pages-buildet skal bare få `ADMIN_SUPABASE_URL` og
`ADMIN_SUPABASE_PUBLISHABLE_KEY` som repository variables. Service-role key,
cron secrets og AI-nøkler skal ikke eksponeres i browseren.

## MVP-avgrensning

Admin er `Må ha` fordi produktet avhenger av kontrollert innholdskvalitet.
Offentlig produktside er `Kan vente` til det finnes et konkret behov for
rekruttering, presentasjon eller distribusjon.
