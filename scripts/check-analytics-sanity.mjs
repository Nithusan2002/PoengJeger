#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import process from "node:process";

const DEFAULT_CONFIG_PATH = "Poengjeger/Config/AppSecrets.local.xcconfig";

function parseArgs(argv) {
  const args = {
    configPath: process.env.APP_SECRETS_XCCONFIG || DEFAULT_CONFIG_PATH,
    host: process.env.SUPABASE_HOST || "",
    key: process.env.SUPABASE_PUBLISHABLE_KEY || "",
    authToken: process.env.SUPABASE_AUTH_TOKEN || "",
    json: false
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--config") {
      args.configPath = argv[++index];
    } else if (arg === "--host") {
      args.host = argv[++index];
    } else if (arg === "--key") {
      args.key = argv[++index];
    } else if (arg === "--auth-token") {
      args.authToken = argv[++index];
    } else if (arg === "--json") {
      args.json = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Usage: node scripts/check-analytics-sanity.mjs [--config path] [--host host] [--key publishableKey] [--auth-token jwt] [--json]

Reads the read-only analytics_sanity_7d view and prints a compact pilot funnel table.
The view is protected by RLS, so use an authenticated editorial Supabase JWT.

Defaults:
  --config ${DEFAULT_CONFIG_PATH}

Environment overrides:
  APP_SECRETS_XCCONFIG
  SUPABASE_HOST
  SUPABASE_PUBLISHABLE_KEY
  SUPABASE_AUTH_TOKEN`);
}

async function readConfiguration(args) {
  if (args.host && args.key) {
    return normalizeConfiguration(args.host, args.key, args.authToken);
  }

  const contents = await readFile(args.configPath, "utf8");
  const host = args.host || readXcconfigValue(contents, "SUPABASE_HOST");
  const key = args.key || readXcconfigValue(contents, "SUPABASE_PUBLISHABLE_KEY");
  return normalizeConfiguration(host, key, args.authToken);
}

function readXcconfigValue(contents, key) {
  const pattern = new RegExp(`^\\s*${key}\\s*=\\s*(.+?)\\s*$`, "m");
  return contents.match(pattern)?.[1]?.trim() || "";
}

function normalizeConfiguration(host, key, authToken) {
  const normalizedHost = host
    .replace(/^https?:\/\//, "")
    .replace(/\/$/, "")
    .trim();
  const normalizedKey = key.trim();
  const normalizedAuthToken = authToken.trim();

  if (!normalizedHost || normalizedHost.includes("$(")) {
    throw new Error("SUPABASE_HOST is missing or unresolved.");
  }
  if (!normalizedKey || normalizedKey.includes("$(")) {
    throw new Error("SUPABASE_PUBLISHABLE_KEY is missing or unresolved.");
  }

  return {
    host: normalizedHost,
    key: normalizedKey,
    authToken: normalizedAuthToken
  };
}

async function fetchAnalyticsSanity({ host, key, authToken }) {
  const url = new URL(`https://${host}/rest/v1/analytics_sanity_7d`);
  url.searchParams.set("select", "step_order,event_name,event_count,session_count,user_count,latest_at");
  url.searchParams.set("order", "step_order.asc");

  const response = await fetch(url, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${authToken || key}`,
      Accept: "application/json"
    }
  });
  const body = await response.text();

  if (!response.ok) {
    throw new SupabaseReadError(response.status, parseSupabaseError(body));
  }

  return JSON.parse(body);
}

function parseSupabaseError(body) {
  try {
    const error = JSON.parse(body);
    return [error.code, error.message, error.hint].filter(Boolean).join(" - ");
  } catch {
    return body.replace(/\s+/g, " ").slice(0, 500);
  }
}

class SupabaseReadError extends Error {
  constructor(status, message) {
    super(message);
    this.name = "SupabaseReadError";
    this.status = status;
  }
}

function printTable(rows) {
  const columns = [
    ["Event", "event_name"],
    ["Events", "event_count"],
    ["Sessions", "session_count"],
    ["Users", "user_count"],
    ["Latest", "latest_at"]
  ];
  const tableRows = rows.map((row) => ({
    ...row,
    latest_at: formatTimestamp(row.latest_at)
  }));
  const widths = columns.map(([label, key]) =>
    Math.max(label.length, ...tableRows.map((row) => String(row[key] ?? "").length))
  );

  console.log(columns.map(([label], index) => label.padEnd(widths[index])).join("  "));
  console.log(widths.map((width) => "-".repeat(width)).join("  "));
  for (const row of tableRows) {
    console.log(
      columns
        .map(([, key], index) => String(row[key] ?? "").padEnd(widths[index]))
        .join("  ")
    );
  }
}

function formatTimestamp(value) {
  if (!value) {
    return "-";
  }

  return value.replace("T", " ").replace(/\.\d+/, "").replace("+00:00", "Z");
}

const args = parseArgs(process.argv);
const configuration = await readConfiguration(args);

try {
  const rows = await fetchAnalyticsSanity(configuration);
  if (args.json) {
    console.log(JSON.stringify(rows, null, 2));
  } else {
    console.log(`Analytics sanity: ${configuration.host}`);
    printTable(rows);
  }
} catch (error) {
  if (error instanceof SupabaseReadError) {
    console.error(`analytics_sanity_7d: ${error.status} ${error.message}`);
    if (!configuration.authToken) {
      console.error(
        "This view requires an authenticated editorial Supabase JWT. Set SUPABASE_AUTH_TOKEN or pass --auth-token."
      );
    }
    process.exit(1);
  }

  throw error;
}
