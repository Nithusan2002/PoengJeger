#!/usr/bin/env node

import { spawnSync } from "node:child_process";

const showAll = process.argv.includes("--all");

const sql = `
  with mixed_store_rates as (
    select
      store.id as store_id,
      store.name as store_name,
      method.slug as method_slug,
      rate.id as rate_id,
      rate.rate_label,
      rate.value_summary,
      rate.warning_text,
      position('%' in rate.rate_label) > 0
        and rate.rate_label not ilike '%opptil%' as is_exact_trumf_percent,
      rate.rate_label ilike '%per 100 kr%' as is_sas_per_100,
      public.extract_first_decimal(rate.rate_label) as documented_rate,
      case method.slug
        when 'trumf' then
          case
            when position('%' in rate.rate_label) > 0
              and rate.rate_label not ilike '%opptil%'
              then public.extract_first_decimal(rate.rate_label) * 13.5
            else null
          end
        when 'sas-eurobonus-online-shopping' then
          case
            when rate.rate_label ilike '%per 100 kr%'
              then public.extract_first_decimal(rate.rate_label)
            else null
          end
        else null
      end as eurobonus_auto_points_per_100,
      case method.slug
        when 'trumf' then public.extract_first_decimal(rate.rate_label) * 10
        else null
      end as eurobonus_single_points_per_100
    from public.stores store
    join public.store_earning_rates rate on rate.store_id = store.id
    join public.earning_methods method on method.id = rate.earning_method_id
    where store.status = 'published'
      and rate.status = 'published'
      and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
      and public.extract_first_decimal(rate.rate_label) is not null
  ),
  mixed_stores as (
    select store_id
    from mixed_store_rates
    group by store_id
    having count(*) filter (where method_slug = 'trumf') > 0
       and count(*) filter (where method_slug = 'sas-eurobonus-online-shopping') > 0
  ),
  manually_ambiguous_stores as (
    select distinct rate.store_id
    from mixed_store_rates rate
    join mixed_stores mixed on mixed.store_id = rate.store_id
    where rate.eurobonus_auto_points_per_100 is null
  ),
  expected_best as (
    select distinct on (rate.store_id)
      rate.store_id,
      rate.store_name,
      rate.method_slug as expected_method_slug,
      rate.rate_label as expected_rate_label,
      rate.eurobonus_auto_points_per_100,
      rate.eurobonus_single_points_per_100
    from mixed_store_rates rate
    join mixed_stores mixed on mixed.store_id = rate.store_id
    where rate.eurobonus_auto_points_per_100 is not null
    order by rate.store_id, rate.eurobonus_auto_points_per_100 desc, rate.method_slug desc
  ),
  actual_best as (
    select distinct on (store.id)
      store.id as store_id,
      method.slug as actual_method_slug,
      combo.total_value_label,
      combo.summary,
      combo.warning_text,
      combo.sort_order
    from public.stores store
    join mixed_stores mixed on mixed.store_id = store.id
    join public.earning_combinations combo on combo.store_id = store.id
    join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
    join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
    join public.earning_methods method on method.id = rate.earning_method_id
    where combo.status = 'published'
      and rate.status = 'published'
      and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
    order by store.id, combo.sort_order, combo.created_at
  )
  select
    expected.store_name,
    expected.expected_method_slug,
    actual.actual_method_slug,
    expected.expected_rate_label,
    actual.total_value_label,
    public.format_norwegian_decimal(expected.eurobonus_auto_points_per_100, 2) as expected_auto_eb_points_per_100,
    case
      when ambiguous.store_id is not null then 'needs_manual_review'
      when actual.actual_method_slug is distinct from expected.expected_method_slug then 'wrong_best_method'
      when expected.expected_method_slug = 'trumf'
        and actual.total_value_label not ilike '%EB-poeng%'
        then 'missing_eurobonus_equivalent_label'
      when expected.expected_method_slug = 'trumf'
        and (
          actual.summary not ilike '%automatisk%'
          or actual.summary not ilike '%engangsoverføring%'
        )
        then 'missing_transfer_explanation'
      else 'ok'
    end as qa_status
  from expected_best expected
  left join actual_best actual on actual.store_id = expected.store_id
  left join manually_ambiguous_stores ambiguous on ambiguous.store_id = expected.store_id
  order by qa_status desc, expected.store_name;
`;

const rows = queryRows(sql);
const hardProblems = rows.filter(
  (row) => row.qa_status !== "ok" && row.qa_status !== "needs_manual_review",
);
const manualReviewRows = rows.filter((row) => row.qa_status === "needs_manual_review");

console.log(`Mixed SAS/Trumf stores checked: ${rows.length}`);
console.log(`Recommendation issues: ${hardProblems.length}`);
console.log(`Manual review rows: ${manualReviewRows.length}`);

if (showAll && rows.length > 0) {
  console.table(rows);
} else if (hardProblems.length > 0) {
  console.table(hardProblems);
} else if (manualReviewRows.length > 0) {
  console.table(manualReviewRows);
}

if (hardProblems.length > 0) {
  process.exitCode = 1;
}

function queryRows(query) {
  const result = spawnSync(
    "npx",
    ["--yes", "supabase", "db", "query", "--linked", query],
    { encoding: "utf8", maxBuffer: 1024 * 1024 * 10, timeout: 45_000 },
  );

  if (result.error) {
    fail(`Supabase CLI failed: ${result.error.message}`);
  }

  if (result.status !== 0) {
    process.stderr.write(result.stderr);
    process.stderr.write(result.stdout);
    process.exit(result.status ?? 1);
  }

  const output = result.stdout.trim();
  const jsonStart = output.indexOf("{");
  if (jsonStart === -1) {
    fail(`Could not parse Supabase CLI output:\n${output}`);
  }

  try {
    return JSON.parse(output.slice(jsonStart)).rows ?? [];
  } catch (error) {
    fail(`Could not parse Supabase CLI JSON output: ${error.message}\n${output}`);
  }
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
