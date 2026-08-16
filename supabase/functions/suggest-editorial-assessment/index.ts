type EditorialSuggestionRequest = {
  title?: string;
  summary?: string;
  details?: string;
  sourceUrl?: string;
  sourceTitle?: string;
  sourceEvidenceNote?: string;
  programName?: string;
  categoryName?: string;
};

type EditorialSuggestion = {
  editorialSummary: string;
  reasonWhyItMatters: string;
  estimatedValueText: string;
  difficultyLevel: "low" | "medium" | "high";
  availabilityScope: "narrow" | "regional" | "broad";
  riskNote: string;
  generatedBy: "openai" | "fallback";
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini";
const REQUEST_TIMEOUT_MS = 20_000;

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "content-type": "application/json; charset=utf-8",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = request.headers.get("authorization") ?? "";
  const apiKey = request.headers.get("apikey") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  if (!SUPABASE_URL) {
    return jsonResponse({ error: "Supabase environment is not configured" }, 500);
  }

  try {
    const role = await fetchEditorialRole(authHeader, apiKey);
    if (role !== "admin" && role !== "editor") {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    const input = sanitizeRequest(await request.json());
    if (!input.title && !input.summary && !input.sourceUrl) {
      return jsonResponse({ error: "Campaign context is missing" }, 400);
    }

    if (!OPENAI_API_KEY) {
      return jsonResponse(buildFallbackSuggestion(input));
    }

    return jsonResponse(await generateOpenAISuggestion(input));
  } catch (error) {
    return jsonResponse({ error: summarizeError(error) }, 500);
  }
});

async function fetchEditorialRole(
  authHeader: string,
  apiKey: string,
): Promise<string | null> {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/current_editorial_role`, {
    method: "POST",
    headers: {
      authorization: authHeader,
      apikey: apiKey,
      "content-type": "application/json",
    },
    body: "{}",
  });

  if (!response.ok) {
    return null;
  }

  const payload = await response.json();
  return typeof payload === "string" ? payload : null;
}

async function generateOpenAISuggestion(
  input: EditorialSuggestionRequest,
): Promise<EditorialSuggestion> {
  const response = await fetchWithTimeout("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      authorization: `Bearer ${OPENAI_API_KEY}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                "Du er redaksjonell assistent for Poengjeger. Skriv kort og tydelig norsk bokmål for vanlige bonusbrukere. Bruk dagligspråk, ikke rapport- eller konsulentspråk. Skriv som en nyttig person ville forklart tilbudet til en venn. Unngå ord som friksjon, kundeforhold, realisere, kontantnær, uttelling, estimert verdi, regional og bredt tilgjengelig. Skriv heller lett å bruke, nytt kort/abonnement, bruke fordelen, nesten som penger, hva du får igjen, gjelder i Norge og gjelder mange. Skill dokumenterte fakta fra vurderinger. Ikke finn på utløpsdato, vilkår, geografi eller bonusverdi. Marker usikkerhet tydelig.",
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: JSON.stringify(input, null, 2),
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "editorial_suggestion",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              editorialSummary: { type: "string" },
              reasonWhyItMatters: { type: "string" },
              estimatedValueText: { type: "string" },
              difficultyLevel: {
                type: "string",
                enum: ["low", "medium", "high"],
              },
              availabilityScope: {
                type: "string",
                enum: ["narrow", "regional", "broad"],
              },
              riskNote: { type: "string" },
            },
            required: [
              "editorialSummary",
              "reasonWhyItMatters",
              "estimatedValueText",
              "difficultyLevel",
              "availabilityScope",
              "riskNote",
            ],
          },
        },
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI ${response.status}: ${await response.text()}`);
  }

  const payload = await response.json();
  const text = extractResponseText(payload);
  if (!text) {
    throw new Error("OpenAI response did not include structured text");
  }

  return {
    ...normalizeSuggestion(JSON.parse(text)),
    generatedBy: "openai",
  };
}

function buildFallbackSuggestion(
  input: EditorialSuggestionRequest,
): EditorialSuggestion {
  const title = input.title || "Kampanjen";
  const summary = input.summary || "Bonusverdi må verifiseres mot kilden.";
  const sourceText = input.sourceUrl ? ` Kilde: ${input.sourceUrl}` : "";
  const programText = input.programName ? ` for ${input.programName}` : "";

  return {
    editorialSummary:
      `${summary}. Må sjekkes av redaksjonen før publisering.`,
    reasonWhyItMatters:
      `${title} kan være nyttig${programText} hvis brukeren uansett skulle handle hos denne leverandøren. Sjekk pris, vilkår og at bonusen faktisk blir registrert.`,
    estimatedValueText:
      `${summary}. Hva du får igjen avhenger av beløp, kategori og vilkår hos kilden.`,
    difficultyLevel: "medium",
    availabilityScope: "broad",
    riskNote:
      `Forslag basert på begrenset informasjon. Sjekk bonusverdi, vilkår, hvem tilbudet gjelder for og oppdatert kilde før publisering.${sourceText}`,
    generatedBy: "fallback",
  };
}

function sanitizeRequest(input: unknown): EditorialSuggestionRequest {
  const record = (input && typeof input === "object") ? input as Record<string, unknown> : {};
  return {
    title: sanitizeText(record.title),
    summary: sanitizeText(record.summary),
    details: sanitizeText(record.details),
    sourceUrl: sanitizeText(record.sourceUrl),
    sourceTitle: sanitizeText(record.sourceTitle),
    sourceEvidenceNote: sanitizeText(record.sourceEvidenceNote),
    programName: sanitizeText(record.programName),
    categoryName: sanitizeText(record.categoryName),
  };
}

function normalizeSuggestion(input: Record<string, unknown>): Omit<EditorialSuggestion, "generatedBy"> {
  return {
    editorialSummary: sanitizeText(input.editorialSummary) || "Må vurderes redaksjonelt før publisering.",
    reasonWhyItMatters: sanitizeText(input.reasonWhyItMatters) || "Må vurderes redaksjonelt før publisering.",
    estimatedValueText: sanitizeText(input.estimatedValueText) || "Verdi må verifiseres mot kilden.",
    difficultyLevel: normalizeDifficulty(input.difficultyLevel),
    availabilityScope: normalizeAvailability(input.availabilityScope),
    riskNote: sanitizeText(input.riskNote) || "Kontroller kilde og vilkår før publisering.",
  };
}

function sanitizeText(value: unknown): string {
  return String(value ?? "").trim().slice(0, 1800);
}

function normalizeDifficulty(value: unknown): "low" | "medium" | "high" {
  return value === "low" || value === "high" ? value : "medium";
}

function normalizeAvailability(value: unknown): "narrow" | "regional" | "broad" {
  return value === "narrow" || value === "regional" ? value : "broad";
}

function extractResponseText(payload: Record<string, unknown>): string | null {
  if (typeof payload.output_text === "string") {
    return payload.output_text;
  }

  const output = Array.isArray(payload.output) ? payload.output : [];
  for (const item of output) {
    const content = item && typeof item === "object"
      ? (item as Record<string, unknown>).content
      : null;
    if (!Array.isArray(content)) {
      continue;
    }
    for (const part of content) {
      if (part && typeof part === "object") {
        const text = (part as Record<string, unknown>).text;
        if (typeof text === "string") {
          return text;
        }
      }
    }
  }

  return null;
}

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    return await fetch(url, {
      ...init,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }
}

function summarizeError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}
