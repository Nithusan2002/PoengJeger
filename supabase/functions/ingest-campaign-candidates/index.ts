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

type CandidateInput = {
  source_registry_id: string;
  source_url: string;
  title: string;
  summary: string | null;
  raw_content: string;
  normalized_hash: string;
  suggested_program_id: string | null;
  status: "new";
  metadata: Record<string, unknown>;
};

type IngestionRunRow = {
  id: string;
};

type BonusProgramRow = {
  id: string;
  slug: string;
};

type TrumfFeed = {
  merchants?: Record<string, {
    hostName?: string;
    urlName?: string;
    name?: string;
    cashbackDescription?: string;
    basicRate?: string;
  }>;
};

type SasShopDetail = {
  uuid?: string;
  name?: string;
  commission_type?: "fixed" | "variable";
  points?: number;
  points_campaign?: number;
  campaign_ends?: string | null;
  campaign_ends_date?: string | null;
  currency?: string;
  categoryId?: number;
  has_campaign?: number | boolean;
  slug?: string;
  fixed_cashback_text?: string | null;
  description?: string | null;
  disable_web_view?: boolean;
};

type SasShopFeed = {
  data?: SasShopDetail[];
};

type RememberStore = {
  slug?: string;
  name?: string;
  enabled?: boolean;
  maxPercentageValue?: number;
  maxFixedValue?: number;
  commission?: Array<{
    value: number;
    type: "PERCENTAGE" | "NOK";
    description: string;
  }>;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const INGESTION_RUN_SECRET = Deno.env.get("INGESTION_RUN_SECRET") ?? "";
const USER_AGENT = Deno.env.get("POENGJEGER_INGESTION_USER_AGENT") ??
  "PoengjegerIngestion/0.1 (+https://poengjeger.no)";

const TRUMF_FEED_URL = "https://wlp.tcb-cdn.com/trumf/notifierfeed.json";
const SAS_SHOPS_FEED_URL =
  "https://onlineshopping.loyaltykey.com/api/v1/shops?filter%5Bchannel%5D=SAS&filter%5Blanguage%5D=nb&filter%5Bcountry%5D=no&filter%5Bamount%5D=5000";
const SAS_HANDOFF_BASE_URL = "https://onlineshopping.flysas.com/nb-NO/butikker";
const REMEMBER_URL = "https://www.remember.no/reward/rabatt";
const DEFAULT_LIMIT_PER_SOURCE = 50;
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
    const sources = await loadActiveSources(parserKeyFilter);
    const results = [];

    for (const source of sources) {
      results.push(await runSource(source, programs, limitPerSource));
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
  limitPerSource: number,
) {
  const run = await createRun(source.id);
  let insertedCount = 0;
  let skippedDuplicateCount = 0;

  try {
    const candidates = await scrapeSource(source, programs, limitPerSource);
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
  limitPerSource: number,
): Promise<CandidateInput[]> {
  switch (source.parser_key) {
    case "trumf_netthandel":
      return scrapeTrumf(source, programs.get("trumf") ?? null, limitPerSource);
    case "sas_eurobonus_shopping":
      return scrapeSas(
        source,
        programs.get("sas-eurobonus") ?? null,
        limitPerSource,
      );
    case "remember_reward":
      return scrapeRemember(source, null, limitPerSource);
    default:
      throw new Error(`Unsupported parser_key: ${source.parser_key ?? "null"}`);
  }
}

async function scrapeTrumf(
  source: SourceRegistryRow,
  programId: string | null,
  limit: number,
): Promise<CandidateInput[]> {
  const feedUrl = source.base_url || TRUMF_FEED_URL;
  const feed = await fetchJson<TrumfFeed>(feedUrl);
  const merchants = Object.values(feed.merchants ?? {})
    .filter((merchant) => merchant.name && merchant.urlName)
    .slice(0, limit);

  return Promise.all(merchants.map(async (merchant) => {
    const sourceUrl = `https://trumfnetthandel.no/cashback/${
      encodeURIComponent(merchant.urlName!)
    }`;
    const summary = merchant.cashbackDescription || merchant.basicRate || null;
    return {
      source_registry_id: source.id,
      source_url: sourceUrl,
      title: `Trumf: ${merchant.name}`,
      summary,
      raw_content: JSON.stringify(merchant),
      normalized_hash: await stableHash([
        source.parser_key,
        merchant.urlName,
        merchant.name,
        summary,
      ]),
      suggested_program_id: programId,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        host_name: merchant.hostName ?? null,
        url_name: merchant.urlName,
        bonus_type: "cashback",
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

async function scrapeSas(
  source: SourceRegistryRow,
  programId: string | null,
  limit: number,
): Promise<CandidateInput[]> {
  const feedUrl = source.base_url || SAS_SHOPS_FEED_URL;
  const feed = await fetchJson<SasShopFeed>(feedUrl);
  const shops = (feed.data ?? [])
    .filter((shop) => shop.name && shop.uuid)
    .slice(0, limit);

  return Promise.all(shops.map(async (shop) => {
    const summary = sasSummary(shop);
    const sourceUrl = sasSourceUrl(shop) || feedUrl;

    return {
      source_registry_id: source.id,
      source_url: sourceUrl,
      title: `SAS EuroBonus Shopping: ${shop.name}`,
      summary,
      raw_content: JSON.stringify(shop),
      normalized_hash: await stableHash([
        source.parser_key,
        shop.uuid,
        shop.name,
        summary,
        shop.campaign_ends_date,
      ]),
      suggested_program_id: programId,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        shop_uuid: shop.uuid,
        shop_slug: shop.slug ?? null,
        category_id: shop.categoryId ?? null,
        commission_type: shop.commission_type ?? null,
        currency: shop.currency ?? null,
        points: shop.points ?? null,
        points_campaign: shop.points_campaign ?? null,
        campaign_ends: shop.campaign_ends ?? null,
        campaign_ends_date: shop.campaign_ends_date ?? null,
        has_campaign: shop.has_campaign ?? null,
        fixed_cashback_text: shop.fixed_cashback_text ?? null,
        handoff_url: sourceUrl,
        source_description_text: stripHtml(shop.description ?? ""),
        bonus_type: "points",
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

function sasSummary(shop: SasShopDetail): string | null {
  if (shop.fixed_cashback_text) {
    return stripHtml(shop.fixed_cashback_text).trim() || null;
  }

  const points = Number(shop.points) || 0;
  if (points <= 0) {
    return null;
  }

  const base = shop.commission_type === "fixed"
    ? `${formatNumber(points)} EuroBonus-poeng`
    : `${formatNumber(points)} EuroBonus-poeng per 100 kr`;

  if (Boolean(shop.has_campaign) && shop.campaign_ends_date) {
    return `${base}, kampanje til ${shop.campaign_ends_date}`;
  }
  return base;
}

function sasSourceUrl(shop: SasShopDetail): string | null {
  if (!shop.slug || !shop.uuid) {
    return null;
  }
  return `${SAS_HANDOFF_BASE_URL}/${encodeURIComponent(shop.slug)}/${
    encodeURIComponent(shop.uuid)
  }`;
}

async function scrapeRemember(
  source: SourceRegistryRow,
  programId: string | null,
  limit: number,
): Promise<CandidateInput[]> {
  const pageUrl = source.base_url || REMEMBER_URL;
  const html = await fetchText(pageUrl);
  const nextDataMatch = html.match(
    /<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>/,
  );
  if (!nextDataMatch) {
    throw new Error("Could not find __NEXT_DATA__ in re:member page");
  }

  const nextData = JSON.parse(nextDataMatch[1]);
  const stores = (nextData?.props?.pageProps?.stores ?? []) as RememberStore[];
  const enabledStores = stores
    .filter((store) => store.enabled && store.name && store.slug)
    .filter((store) => !store.name!.toLowerCase().includes("direct deals"))
    .slice(0, limit);

  return Promise.all(enabledStores.map(async (store) => {
    const summary = rememberSummary(store);
    const sourceUrl = `https://www.remember.no/reward/rabatt/${
      encodeURIComponent(store.slug!)
    }`;
    return {
      source_registry_id: source.id,
      source_url: sourceUrl,
      title: `re:member reward: ${store.name}`,
      summary,
      raw_content: JSON.stringify(store),
      normalized_hash: await stableHash([
        source.parser_key,
        store.slug,
        store.name,
        summary,
      ]),
      suggested_program_id: programId,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        slug: store.slug,
        commission: store.commission ?? null,
        bonus_type: "cashback",
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

function rememberSummary(store: RememberStore): string | null {
  if (store.commission && store.commission.length > 1) {
    const percentageRates = store.commission.filter((rate) =>
      rate.type === "PERCENTAGE"
    );
    if (percentageRates.length > 1) {
      const values = percentageRates.map((rate) => rate.value);
      const min = Math.min(...values);
      const max = Math.max(...values);
      return min === max ? `${max}%` : `${min}-${max}%*`;
    }
  }

  if (store.maxPercentageValue && store.maxPercentageValue > 0) {
    return `${store.maxPercentageValue}%`;
  }
  if (store.maxFixedValue && store.maxFixedValue > 0) {
    return `${store.maxFixedValue} kr`;
  }
  return null;
}

async function loadBonusPrograms(): Promise<Map<string, string>> {
  const rows = await restRequest<BonusProgramRow[]>(
    "/rest/v1/bonus_programs?select=id,slug&is_active=eq.true",
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

async function stableHash(parts: unknown[]): Promise<string> {
  const normalized = parts
    .map((part) => String(part ?? "").trim().toLowerCase().replace(/\s+/g, " "))
    .join("|");
  const bytes = new TextEncoder().encode(normalized);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function parsePositiveInteger(value: string | null, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    return fallback;
  }
  return Math.min(parsed, 250);
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat("nb-NO", { maximumFractionDigits: 0 }).format(
    value,
  );
}

function stripHtml(value: string): string {
  return value
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
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
