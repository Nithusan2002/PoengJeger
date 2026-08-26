import {
  buildRememberCandidates,
  buildSasCandidates,
  buildTrumfCandidates,
  type CandidateInput,
  type SasShopFeed,
  type TrumfFeed,
} from "./parsers.ts";

type SourceRegistryRow = {
  id: string;
  ingest_kind: string;
  base_url: string | null;
  parser_key: string | null;
  poll_interval_minutes: number;
  last_checked_at: string | null;
  campaign_sources: {
    name: string;
    base_url: string | null;
  } | null;
};

type IngestionRunRow = {
  id: string;
};

type BonusProgramRow = {
  id: string;
  slug: string;
};

type CampaignCategoryRow = {
  id: string;
  slug: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const INGESTION_RUN_SECRET = Deno.env.get("INGESTION_RUN_SECRET") ?? "";
const USER_AGENT = Deno.env.get("POENGJEGER_INGESTION_USER_AGENT") ??
  "PoengjegerIngestion/0.1 (+https://poengjeger.no)";

const TRUMF_FEED_URL = "https://wlp.tcb-cdn.com/trumf/notifierfeed.json";
const SAS_SHOPS_FEED_URL =
  "https://onlineshopping.loyaltykey.com/api/v1/shops?filter%5Bchannel%5D=SAS&filter%5Blanguage%5D=nb&filter%5Bcountry%5D=no&filter%5Bamount%5D=5000";
const REMEMBER_URL = "https://www.remember.no/reward/rabatt";
const DEFAULT_LIMIT_PER_SOURCE = 50;
const MAX_LIMIT_PER_SOURCE = 1_000;
const REQUEST_TIMEOUT_MS = 15_000;

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
  const hasSecretAuth = Boolean(INGESTION_RUN_SECRET) &&
    authHeader === `Bearer ${INGESTION_RUN_SECRET}`;

  if (!hasSecretAuth) {
    const role = await fetchRequesterRole(authHeader, apiKey);
    if (role !== "admin" && role !== "editor") {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return jsonResponse(
      { error: "Supabase environment is not configured" },
      500,
    );
  }

  const url = new URL(request.url);
  const parserKeyFilter = url.searchParams.get("source");
  const limitPerSource = parsePositiveInteger(
    url.searchParams.get("limit"),
    DEFAULT_LIMIT_PER_SOURCE,
  );

  try {
    const programs = await loadBonusPrograms();
    const categories = await loadCampaignCategories();
    const sources = await loadActiveSources(parserKeyFilter);
    const results = [];

    for (const source of sources) {
      results.push(await runSource(source, programs, categories, limitPerSource));
    }

    return jsonResponse({
      checked_source_count: sources.length,
      results,
    });
  } catch (error) {
    return jsonResponse({ error: summarizeError(error) }, 500);
  }
});

async function fetchRequesterRole(
  authHeader: string,
  apiKey: string,
): Promise<string | null> {
  if (!authHeader.startsWith("Bearer ") || !apiKey) {
    return null;
  }

  const userResponse = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      authorization: authHeader,
      apikey: apiKey,
    },
  });

  if (userResponse.ok) {
    const user = await userResponse.json();
    const metadataRole = user?.app_metadata?.poengjeger_role;
    if (metadataRole === "admin" || metadataRole === "editor") {
      return metadataRole;
    }
  }

  const roleResponse = await fetch(`${SUPABASE_URL}/rest/v1/rpc/current_editorial_role`, {
    method: "POST",
    headers: {
      authorization: authHeader,
      apikey: apiKey,
      "content-type": "application/json",
    },
    body: "{}",
  });

  if (!roleResponse.ok) {
    return null;
  }

  const role = await roleResponse.json();
  return typeof role === "string" ? role : null;
}

async function runSource(
  source: SourceRegistryRow,
  programs: Map<string, string>,
  categories: Map<string, string>,
  limitPerSource: number,
) {
  const run = await createRun(source.id);
  let insertedCount = 0;
  let skippedDuplicateCount = 0;

  try {
    const candidates = await scrapeSource(source, programs, categories, limitPerSource);
    for (const candidate of candidates) {
      const inserted = await insertCandidateIfNew(candidate);
      if (inserted) {
        insertedCount++;
      } else {
        skippedDuplicateCount++;
      }
    }

    await finishRun(run.id, "succeeded", insertedCount, null);
    await patchTable("source_registry", source.id, {
      last_checked_at: new Date().toISOString(),
    });

    return {
      source_registry_id: source.id,
      parser_key: source.parser_key,
      status: "succeeded",
      found_count: candidates.length,
      inserted_count: insertedCount,
      skipped_duplicate_count: skippedDuplicateCount,
    };
  } catch (error) {
    const message = summarizeError(error);
    await finishRun(run.id, "failed", insertedCount, message);
    return {
      source_registry_id: source.id,
      parser_key: source.parser_key,
      status: "failed",
      inserted_count: insertedCount,
      skipped_duplicate_count: skippedDuplicateCount,
      error: message,
    };
  }
}

async function scrapeSource(
  source: SourceRegistryRow,
  programs: Map<string, string>,
  categories: Map<string, string>,
  limitPerSource: number,
): Promise<CandidateInput[]> {
  switch (source.parser_key) {
    case "trumf_netthandel":
      return scrapeTrumf(
        source,
        programs.get("trumf") ?? null,
        categories,
        limitPerSource,
      );
    case "sas_eurobonus_shopping":
      return scrapeSas(
        source,
        programs.get("sas-eurobonus") ?? null,
        categories,
        limitPerSource,
      );
    case "remember_reward":
      return scrapeRemember(source, null, categories, limitPerSource);
    default:
      throw new Error(`Unsupported parser_key: ${source.parser_key ?? "null"}`);
  }
}

async function scrapeTrumf(
  source: SourceRegistryRow,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
): Promise<CandidateInput[]> {
  const feedUrl = source.base_url || TRUMF_FEED_URL;
  const feed = await fetchJson<TrumfFeed>(feedUrl);
  return buildTrumfCandidates(source, feed, programId, categories, limit);
}

async function scrapeSas(
  source: SourceRegistryRow,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
): Promise<CandidateInput[]> {
  const feedUrl = source.base_url || SAS_SHOPS_FEED_URL;
  const feed = await fetchJson<SasShopFeed>(feedUrl);
  return buildSasCandidates(source, feed, programId, categories, limit, feedUrl);
}

async function scrapeRemember(
  source: SourceRegistryRow,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
): Promise<CandidateInput[]> {
  const pageUrl = source.base_url || REMEMBER_URL;
  const html = await fetchText(pageUrl);
  return buildRememberCandidates(source, html, programId, categories, limit);
}

async function loadBonusPrograms(): Promise<Map<string, string>> {
  const rows = await restRequest<BonusProgramRow[]>(
    "/rest/v1/bonus_programs?select=id,slug&is_active=eq.true",
  );
  return new Map(rows.map((row) => [row.slug, row.id]));
}

async function loadCampaignCategories(): Promise<Map<string, string>> {
  const rows = await restRequest<CampaignCategoryRow[]>(
    "/rest/v1/campaign_categories?select=id,slug",
  );
  return new Map(rows.map((row) => [row.slug, row.id]));
}

async function loadActiveSources(
  parserKeyFilter: string | null,
): Promise<SourceRegistryRow[]> {
  const params = new URLSearchParams({
    select:
      "id,ingest_kind,base_url,parser_key,poll_interval_minutes,last_checked_at,campaign_sources(name,base_url)",
    is_active: "eq.true",
    order: "created_at.asc",
  });
  if (parserKeyFilter) {
    params.set("parser_key", `eq.${parserKeyFilter}`);
  } else {
    params.set(
      "parser_key",
      "in.(trumf_netthandel,sas_eurobonus_shopping,remember_reward)",
    );
  }

  return restRequest<SourceRegistryRow[]>(
    `/rest/v1/source_registry?${params.toString()}`,
  );
}

async function createRun(sourceRegistryId: string): Promise<IngestionRunRow> {
  const rows = await restRequest<IngestionRunRow[]>("/rest/v1/ingestion_runs", {
    method: "POST",
    body: JSON.stringify({
      source_registry_id: sourceRegistryId,
      status: "running",
    }),
    headers: {
      prefer: "return=representation",
    },
  });
  return rows[0];
}

async function finishRun(
  runId: string,
  status: "succeeded" | "failed" | "partial",
  candidateCount: number,
  errorMessage: string | null,
) {
  await patchTable("ingestion_runs", runId, {
    status,
    candidate_count: candidateCount,
    error_message: errorMessage,
    finished_at: new Date().toISOString(),
  });
}

async function insertCandidateIfNew(
  candidate: CandidateInput,
): Promise<boolean> {
  const hashParam = encodeURIComponent(candidate.normalized_hash);
  const existing = await restRequest<Array<{ id: string }>>(
    `/rest/v1/ingestion_candidates?select=id&source_registry_id=eq.${candidate.source_registry_id}&normalized_hash=eq.${hashParam}&limit=1`,
  );
  if (existing.length > 0) {
    return false;
  }

  await restRequest("/rest/v1/ingestion_candidates", {
    method: "POST",
    body: JSON.stringify(candidate),
    headers: {
      prefer: "return=minimal",
    },
  });
  return true;
}

async function patchTable(
  table: string,
  id: string,
  body: Record<string, unknown>,
) {
  await restRequest(`/rest/v1/${table}?id=eq.${id}`, {
    method: "PATCH",
    body: JSON.stringify(body),
    headers: {
      prefer: "return=minimal",
    },
  });
}

async function restRequest<T = unknown>(
  path: string,
  init: RequestInit & { headers?: Record<string, string> } = {},
): Promise<T> {
  const response = await fetch(`${SUPABASE_URL}${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_ROLE_KEY,
      authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "content-type": "application/json",
      ...(init.headers ?? {}),
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Supabase ${response.status}: ${text}`);
  }

  const text = await response.text();
  if (!text) {
    return null as T;
  }

  return JSON.parse(text) as T;
}

async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetchWithTimeout(url, {
    headers: {
      accept: "application/json",
      "user-agent": USER_AGENT,
    },
  });
  if (!response.ok) {
    throw new Error(`${url} returned HTTP ${response.status}`);
  }
  return response.json() as Promise<T>;
}

async function fetchText(url: string): Promise<string> {
  const response = await fetchWithTimeout(url, {
    headers: {
      accept: "text/html,application/xhtml+xml",
      "user-agent": USER_AGENT,
    },
  });
  if (!response.ok) {
    throw new Error(`${url} returned HTTP ${response.status}`);
  }
  return response.text();
}

async function fetchWithTimeout(
  url: string,
  init: RequestInit,
): Promise<Response> {
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

function parsePositiveInteger(value: string | null, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    return fallback;
  }
  return Math.min(parsed, MAX_LIMIT_PER_SOURCE);
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
