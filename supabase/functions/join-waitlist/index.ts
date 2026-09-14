import { corsHeaders, normalizeSubmission } from "./helpers.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function json(body: Record<string, unknown>, status: number, headers: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}

Deno.serve(async (request) => {
  const origin = request.headers.get("Origin");
  const cors = corsHeaders(origin);
  if (!cors) return json({ error: "Ugyldig opprinnelse." }, 403);

  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (request.method !== "POST") return json({ error: "Metoden støttes ikke." }, 405, cors);

  const contentLength = Number(request.headers.get("Content-Length") ?? 0);
  if (contentLength > 2048) return json({ error: "Forespørselen er for stor." }, 413, cors);
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "Tjenesten er ikke konfigurert." }, 503, cors);

  let raw: unknown;
  try {
    raw = await request.json();
  } catch {
    return json({ error: "Ugyldig forespørsel." }, 400, cors);
  }

  const submission = normalizeSubmission(raw);
  if (!submission) return json({ error: "Kontroller e-postadresse og samtykke." }, 400, cors);

  const response = await fetch(`${supabaseUrl}/rest/v1/launch_waitlist?on_conflict=email`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${serviceRoleKey}`,
      "apikey": serviceRoleKey,
      "Content-Type": "application/json",
      "Prefer": "resolution=ignore-duplicates,return=minimal",
    },
    body: JSON.stringify({
      email: submission.email,
      consent_version: "2026-09-14",
      source: submission.source,
    }),
  });

  if (!response.ok) {
    console.error("Waitlist insert failed", response.status);
    return json({ error: "Kunne ikke registrere e-postadressen nå." }, 502, cors);
  }

  return json({ ok: true }, 200, cors);
});
