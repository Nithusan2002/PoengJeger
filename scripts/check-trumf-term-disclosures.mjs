#!/usr/bin/env node

import { spawnSync } from "node:child_process";

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, value = "true"] = arg.replace(/^--/, "").split("=");
    return [key, value];
  }),
);

const limit = Number(args.get("limit") ?? 50);
const storeFilter = args.get("store") ?? "";
const fetchTimeoutMs = Number(args.get("timeout-ms") ?? 15_000);

const disclosureRules = [
  {
    key: "new_customer",
    sourcePatterns: [/nye kunder?/i, /ny kunde/i, /innmelding/i],
    localPatterns: [/nye kunder?/i, /ny kunde/i, /innmelding/i],
    label: "nye kunder",
  },
  {
    key: "annual_subscription",
    sourcePatterns: [/årsabonnement/i],
    localPatterns: [/årsabonnement/i],
    label: "årsabonnement",
  },
  {
    key: "first_payment",
    sourcePatterns: [/første betaling/i, /forste betaling/i],
    localPatterns: [/første betaling/i, /forste betaling/i],
    label: "kun første betaling",
  },
];

const rows = queryRows(buildQuery());
const findings = [];

for (const row of rows) {
  const html = await fetchText(row.source_url);
  if (!html) {
    findings.push({
      store: row.store_name,
      source_url: row.source_url,
      missing_terms: "source_fetch_failed",
      source_excerpt: "Kunne ikke hente kildesiden innen timeout.",
    });
    continue;
  }

  const sourceText = normalizeText(stripHtml(html));
  const localText = normalizeText([
    row.rate_label,
    row.value_summary,
    row.requirement_summary,
    row.rate_warning_text,
    row.total_value_label,
    row.combination_summary,
    row.combination_warning_text,
  ].filter(Boolean).join(" "));

  const missingRules = disclosureRules
    .filter((rule) => rule.sourcePatterns.some((pattern) => pattern.test(sourceText)))
    .filter((rule) => !rule.localPatterns.some((pattern) => pattern.test(localText)));
  const missingTerms = missingRules.map((rule) => rule.label);

  if (missingTerms.length > 0) {
    findings.push({
      store: row.store_name,
      source_url: row.source_url,
      missing_terms: missingTerms.join(", "),
      source_excerpt: excerpt(sourceText, missingRules),
    });
  }
}

console.log(`Trumf store earning rows checked: ${rows.length}`);
console.log(`Rows missing important source terms: ${findings.length}`);

if (findings.length > 0) {
  console.table(findings);
  process.exitCode = 1;
}

function buildQuery() {
  const escapedStoreFilter = storeFilter.replaceAll("'", "''");
  const storeClause = escapedStoreFilter
    ? `and store.name ilike '%${escapedStoreFilter}%'`
    : "";

  return `
    select distinct on (rate.id)
      store.name as store_name,
      rate.id as rate_id,
      rate.source_url,
      rate.rate_label,
      rate.value_summary,
      rate.requirement_summary,
      rate.warning_text as rate_warning_text,
      combo.total_value_label,
      combo.summary as combination_summary,
      combo.warning_text as combination_warning_text
    from public.store_earning_rates rate
    join public.stores store on store.id = rate.store_id
    join public.earning_methods method on method.id = rate.earning_method_id
    left join public.earning_combination_rates combo_rate on combo_rate.store_earning_rate_id = rate.id
    left join public.earning_combinations combo on combo.id = combo_rate.combination_id
    where store.status = 'published'
      and rate.status = 'published'
      and method.slug = 'trumf'
      and rate.source_url is not null
      ${storeClause}
    order by rate.id, store.name
    limit ${Number.isFinite(limit) && limit > 0 ? limit : 50};
  `;
}

function queryRows(sql) {
  const result = spawnSync(
    "npx",
    ["--yes", "supabase", "db", "query", "--linked", sql],
    { encoding: "utf8", maxBuffer: 1024 * 1024 * 10, timeout: 45_000 },
  );

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    process.stderr.write(result.stderr);
    process.stderr.write(result.stdout);
    process.exit(result.status ?? 1);
  }

  const output = result.stdout.trim();
  const jsonStart = output.indexOf("{");
  if (jsonStart === -1) {
    throw new Error(`Could not parse Supabase CLI output:\n${output}`);
  }

  return JSON.parse(output.slice(jsonStart)).rows ?? [];
}

async function fetchText(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), fetchTimeoutMs);

  try {
    const response = await fetch(url, {
      headers: {
        "user-agent": "Poengjeger editorial QA/1.0",
        "accept": "text/html,application/xhtml+xml",
      },
      signal: controller.signal,
    });

    if (!response.ok) {
      return null;
    }

    return response.text();
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function stripHtml(html) {
  return decodeHtmlEntities(
    html
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/<style[\s\S]*?<\/style>/gi, " ")
      .replace(/<[^>]+>/g, " "),
  );
}

function decodeHtmlEntities(value) {
  return value
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'")
    .replace(/&aring;/g, "å")
    .replace(/&Aring;/g, "Å")
    .replace(/&aelig;/g, "æ")
    .replace(/&AElig;/g, "Æ")
    .replace(/&oslash;/g, "ø")
    .replace(/&Oslash;/g, "Ø")
    .replace(/&#(\d+);/g, (_, codePoint) => String.fromCodePoint(Number(codePoint)));
}

function normalizeText(value) {
  return value.replace(/\s+/g, " ").trim();
}

function excerpt(sourceText, missingRules) {
  const indexes = missingRules.flatMap((rule) =>
    rule.sourcePatterns
      .map((pattern) => sourceText.search(pattern))
      .filter((termIndex) => termIndex >= 0)
  );
  const index = indexes.sort((first, second) => first - second)[0] ?? 0;
  const start = Math.max(0, index - 80);
  return sourceText.slice(start, start + 220);
}
