export const allowedOrigins = new Set([
  "https://nithusan.no",
  "https://www.nithusan.no",
  "http://127.0.0.1:4187",
  "http://localhost:4187",
]);

export type WaitlistSubmission = {
  email: string;
  consent: true;
  source: "nithusan.no/poengjeger";
};

export function normalizeSubmission(value: unknown): WaitlistSubmission | null {
  if (!value || typeof value !== "object") return null;

  const body = value as Record<string, unknown>;
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const company = typeof body.company === "string" ? body.company.trim() : "";
  const source = body.source;

  if (company) return null;
  if (body.consent !== true) return null;
  if (source !== "nithusan.no/poengjeger") return null;
  if (email.length < 3 || email.length > 254) return null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return null;

  return { email, consent: true, source };
}

export function corsHeaders(origin: string | null): Record<string, string> | null {
  if (!origin || !allowedOrigins.has(origin)) return null;
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}
