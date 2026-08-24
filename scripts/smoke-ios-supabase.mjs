#!/usr/bin/env node

import { readFile } from "node:fs/promises";
import process from "node:process";

const DEFAULT_CONFIG_PATH = "Poengjeger/Config/AppSecrets.local.xcconfig";

const checks = [
  {
    name: "programs",
    path: "bonus_programs",
    query: {
      select: "id,slug,name,issuer_name,country_code,is_active",
      is_active: "eq.true",
      order: "name.asc"
    }
  },
  {
    name: "programGuides",
    path: "program_guides",
    query: {
      select:
        "id,program_id,status,intro_text,strategy,value_estimate_label,value_estimate_detail,expiration_summary,expiration_detail,earning_tips,redemption_tips,risk_notes,last_reviewed_at",
      status: "eq.published",
      order: "last_reviewed_at.desc.nullslast"
    }
  },
  {
    name: "campaigns",
    path: "campaigns",
    query: {
      select: [
        "id",
        "title",
        "summary",
        "details",
        "status",
        "start_date",
        "end_date",
        "last_verified_at",
        "primary_program_id",
        "editorial_score",
        "editorial_summary",
        "is_featured",
        "campaign_categories(id,slug,name)",
        "campaign_requirements(id,text,sort_order)",
        "campaign_source_references(id,url,title,checked_at,evidence_note,campaign_sources(name))",
        "campaign_editorial_assessments(score,decision_label,decision_summary,best_for,not_for,reason_why_it_matters,estimated_value_text,difficulty_level,availability_scope,risk_note)",
        "campaign_geo_restrictions(id,country_code)",
        "campaign_programs(program_id)"
      ].join(","),
      status: "eq.published",
      order: "is_featured.desc,last_verified_at.desc"
    }
  },
  {
    name: "stores",
    path: "stores",
    query: {
      select: [
        "id",
        "slug",
        "name",
        "status",
        "website_url",
        "search_keywords",
        "last_verified_at",
        "campaign_categories(id,slug,name)",
        "store_earning_rates(id,status,rate_label,normal_rate_label,value_summary,requirement_summary,warning_text,handoff_url,source_url,source_title,checked_at,starts_at,ends_at,sort_order,is_base_rate,earning_methods(id,slug,name,method_type,program_id,description))",
        "earning_combinations(id,status,title,total_value_label,summary,easier_alternative_label,warning_text,primary_handoff_url,last_verified_at,sort_order,earning_combination_rates(store_earning_rate_id,sort_order),earning_combination_steps(id,text,sort_order))"
      ].join(","),
      status: "eq.published",
      order: "name.asc"
    }
  }
];

function parseArgs(argv) {
  const args = {
    configPath: process.env.APP_SECRETS_XCCONFIG || DEFAULT_CONFIG_PATH,
    host: process.env.SUPABASE_HOST || "",
    key: process.env.SUPABASE_PUBLISHABLE_KEY || ""
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--config") {
      args.configPath = argv[++index];
    } else if (arg === "--host") {
      args.host = argv[++index];
    } else if (arg === "--key") {
      args.key = argv[++index];
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
  console.log(`Usage: node scripts/smoke-ios-supabase.mjs [--config path] [--host host] [--key publishableKey]

Runs the same Supabase REST selects that the iOS bootstrap flow uses.

Defaults:
  --config ${DEFAULT_CONFIG_PATH}

Environment overrides:
  APP_SECRETS_XCCONFIG
  SUPABASE_HOST
  SUPABASE_PUBLISHABLE_KEY`);
}

async function readConfiguration(args) {
  if (args.host && args.key) {
    return normalizeConfiguration(args.host, args.key);
  }

  const contents = await readFile(args.configPath, "utf8");
  const host = args.host || readXcconfigValue(contents, "SUPABASE_HOST");
  const key = args.key || readXcconfigValue(contents, "SUPABASE_PUBLISHABLE_KEY");
  return normalizeConfiguration(host, key);
}

function readXcconfigValue(contents, key) {
  const pattern = new RegExp(`^\\s*${key}\\s*=\\s*(.+?)\\s*$`, "m");
  return contents.match(pattern)?.[1]?.trim() || "";
}

function normalizeConfiguration(host, key) {
  const normalizedHost = host
    .replace(/^https?:\/\//, "")
    .replace(/\/$/, "")
    .trim();
  const normalizedKey = key.trim();

  if (!normalizedHost || normalizedHost.includes("$(")) {
    throw new Error("SUPABASE_HOST is missing or unresolved.");
  }
  if (!normalizedKey || normalizedKey.includes("$(")) {
    throw new Error("SUPABASE_PUBLISHABLE_KEY is missing or unresolved.");
  }

  return { host: normalizedHost, key: normalizedKey };
}

async function runCheck({ host, key }, check) {
  const url = new URL(`https://${host}/rest/v1/${check.path}`);
  for (const [name, value] of Object.entries(check.query)) {
    url.searchParams.set(name, value);
  }

  const response = await fetch(url, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      Accept: "application/json"
    }
  });
  const body = await response.text();

  if (!response.ok) {
    return {
      name: check.name,
      ok: false,
      status: response.status,
      message: parseSupabaseError(body)
    };
  }

  return {
    name: check.name,
    ok: true,
    status: response.status
  };
}

function parseSupabaseError(body) {
  try {
    const error = JSON.parse(body);
    return [error.code, error.message, error.hint].filter(Boolean).join(" - ");
  } catch {
    return body.replace(/\s+/g, " ").slice(0, 500);
  }
}

const args = parseArgs(process.argv);
const configuration = await readConfiguration(args);
console.log(`Supabase iOS smoke test: ${configuration.host}`);

let hasFailure = false;
for (const check of checks) {
  const result = await runCheck(configuration, check);
  if (result.ok) {
    console.log(`${result.name}: ${result.status} OK`);
  } else {
    hasFailure = true;
    console.error(`${result.name}: ${result.status} ${result.message}`);
  }
}

if (hasFailure) {
  console.error("Supabase iOS smoke test failed.");
  process.exit(1);
}

console.log("Supabase iOS smoke test passed.");
