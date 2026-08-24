#!/usr/bin/env node

const DEFAULT_PROJECT_REF = "vxshbidckvfzxohcpprq";
const DEFAULT_SOURCE = "trumf_netthandel";
const DEFAULT_LIMIT = 1000;

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.replace(/^--/, "").split("=");
    return [key, valueParts.join("=") || "true"];
  }),
);

const projectRef = args.get("project-ref") ?? process.env.SUPABASE_PROJECT_REF ?? DEFAULT_PROJECT_REF;
const functionUrl = args.get("function-url") ??
  process.env.SUPABASE_FUNCTION_URL ??
  `https://${projectRef}.functions.supabase.co`;
const source = args.get("source") ?? process.env.INGESTION_SOURCE ?? DEFAULT_SOURCE;
const limit = Number(args.get("limit") ?? process.env.INGESTION_LIMIT ?? DEFAULT_LIMIT);
const secret = process.env.INGESTION_RUN_SECRET;

if (!secret) {
  console.error("Missing INGESTION_RUN_SECRET.");
  console.error("Usage: INGESTION_RUN_SECRET=... node scripts/run-ingestion.mjs --source=trumf_netthandel --limit=1000");
  process.exit(1);
}

if (!Number.isInteger(limit) || limit <= 0) {
  console.error(`Invalid limit: ${limit}`);
  process.exit(1);
}

const url = new URL(`${functionUrl.replace(/\/$/, "")}/ingest-campaign-candidates`);
url.searchParams.set("source", source);
url.searchParams.set("limit", String(limit));

const response = await fetch(url, {
  method: "POST",
  headers: {
    authorization: `Bearer ${secret}`,
    "content-type": "application/json",
  },
});

const text = await response.text();
let body;
try {
  body = text ? JSON.parse(text) : null;
} catch {
  body = text;
}

if (!response.ok) {
  console.error(`Ingestion failed: HTTP ${response.status}`);
  console.error(typeof body === "string" ? body : JSON.stringify(body, null, 2));
  process.exit(1);
}

console.log(JSON.stringify(body, null, 2));
