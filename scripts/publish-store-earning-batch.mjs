#!/usr/bin/env node

import { spawnSync } from "node:child_process";

const DEFAULT_LIMIT = 10;
const VALID_MODES = new Set(["ready", "matches", "duplicates"]);

const args = new Map(
  process.argv.slice(2).map((arg) => {
    const [key, ...valueParts] = arg.replace(/^--/, "").split("=");
    return [key, valueParts.join("=") || "true"];
  }),
);

const mode = args.get("mode") ?? "ready";
const limit = Number(args.get("limit") ?? DEFAULT_LIMIT);
const execute = args.has("execute");
const reviewNote = args.get("review-note") ?? defaultReviewNote(mode);

if (!VALID_MODES.has(mode)) {
  fail(`Invalid mode: ${mode}. Use one of: ${Array.from(VALID_MODES).join(", ")}`);
}

if (!Number.isInteger(limit) || limit <= 0 || limit > 50) {
  fail(`Invalid limit: ${args.get("limit")}. Use an integer from 1 to 50.`);
}

const previewRows = queryRows(previewSql(mode, limit));
printPreview(mode, previewRows);

if (previewRows.length === 0) {
  process.exit(0);
}

if (!execute) {
  console.log("\nDry run only. Add --execute to publish this batch.");
  process.exit(0);
}

const resultRows = queryRows(executeSql(mode, limit, reviewNote));
console.log("\nPublish result:");
console.table(resultRows);

const verifyRows = queryRows(verifySql(reviewNote));
console.log("\nVerification:");
console.table(verifyRows);

function previewSql(selectedMode, selectedLimit) {
  return `
    select
      id,
      title,
      parser_key,
      shop_slug,
      suggested_method_slug,
      summary,
      suggested_category_slug,
      matched_store_name,
      has_existing_store_method_rate
    from public.admin_ingestion_candidate_queue
    where ${whereClause(selectedMode)}
    order by detected_at desc
    limit ${selectedLimit};
  `;
}

function executeSql(selectedMode, selectedLimit, note) {
  if (selectedMode === "duplicates") {
    return executeDuplicateUpdatesSql(selectedLimit, note);
  }

  return executePromotionsSql(selectedMode, selectedLimit, note);
}

function executePromotionsSql(selectedMode, selectedLimit, note) {
  return `
    begin;

    create temporary table tmp_store_earning_candidates on commit drop as
    select id, parser_key
    from public.admin_ingestion_candidate_queue
    where ${whereClause(selectedMode)}
    order by detected_at desc
    limit ${selectedLimit};

    create temporary table tmp_promoted_store_earning_rates on commit drop as
    select
      candidate.id as candidate_id,
      candidate.parser_key,
      public.promote_ingestion_candidate_to_store_earning(
        candidate.id,
        null,
        null,
        null,
        ${sqlString(note)}
      ) as rate_id
    from tmp_store_earning_candidates candidate;

    update public.store_earning_rates rate
    set
      status = 'published',
      warning_text = null,
      checked_at = now(),
      updated_at = now()
    from tmp_promoted_store_earning_rates promoted
    where rate.id = promoted.rate_id;

    update public.stores store
    set
      status = 'published',
      last_verified_at = now(),
      updated_at = now()
    from tmp_promoted_store_earning_rates promoted
    join public.store_earning_rates rate on rate.id = promoted.rate_id
    where store.id = rate.store_id;

    create temporary table tmp_inserted_combinations on commit drop as
    with inserted as (
      insert into public.earning_combinations (
        store_id,
        status,
        title,
        total_value_label,
        summary,
        primary_handoff_url,
        last_verified_at,
        sort_order
      )
      select
        rate.store_id,
        'published',
        ${methodTitle("promoted.parser_key")},
        rate.rate_label,
        ${methodSummary("promoted.parser_key", "store.name")},
        rate.handoff_url,
        now(),
        0
      from tmp_promoted_store_earning_rates promoted
      join public.store_earning_rates rate on rate.id = promoted.rate_id
      join public.stores store on store.id = rate.store_id
      returning id, store_id
    )
    select * from inserted;

    insert into public.earning_combination_rates (
      combination_id,
      store_earning_rate_id,
      sort_order
    )
    select
      combination.id,
      promoted.rate_id,
      0
    from tmp_inserted_combinations combination
    join tmp_promoted_store_earning_rates promoted on true
    join public.store_earning_rates rate
      on rate.id = promoted.rate_id
      and rate.store_id = combination.store_id
    on conflict do nothing;

    select
      count(*) as published_count,
      ${sqlString(selectedMode)} as mode,
      ${sqlString(note)} as review_note
    from tmp_promoted_store_earning_rates;

    commit;
  `;
}

function executeDuplicateUpdatesSql(selectedLimit, note) {
  return `
    begin;

    create temporary table tmp_duplicate_candidates on commit drop as
    select
      q.id as candidate_id,
      q.parser_key,
      q.suggested_method_slug,
      q.matched_store_id as store_id,
      q.summary as rate_label,
      q.source_url
    from public.admin_ingestion_candidate_queue q
    where ${whereClause("duplicates")}
    order by q.detected_at desc
    limit ${selectedLimit};

    create temporary table tmp_resolved_duplicate_rates on commit drop as
    select
      candidate.*,
      rate.id as rate_id,
      combo.id as combo_id,
      store.name as store_name
    from tmp_duplicate_candidates candidate
    join public.earning_methods method on method.slug = candidate.suggested_method_slug
    join public.store_earning_rates rate
      on rate.store_id = candidate.store_id
      and rate.earning_method_id = method.id
      and rate.status in ('draft', 'published')
    join public.stores store on store.id = candidate.store_id
    left join public.earning_combination_rates combo_rate on combo_rate.store_earning_rate_id = rate.id
    left join public.earning_combinations combo on combo.id = combo_rate.combination_id;

    update public.store_earning_rates rate
    set
      rate_label = resolved.rate_label,
      normal_rate_label = resolved.rate_label,
      value_summary = resolved.rate_label,
      handoff_url = resolved.source_url,
      source_url = resolved.source_url,
      source_title = ${methodTitle("resolved.parser_key")},
      status = 'published',
      warning_text = null,
      checked_at = now(),
      updated_at = now()
    from tmp_resolved_duplicate_rates resolved
    where rate.id = resolved.rate_id;

    update public.earning_combinations combo
    set
      title = ${methodTitle("resolved.parser_key")},
      total_value_label = resolved.rate_label,
      summary = ${methodSummary("resolved.parser_key", "resolved.store_name")},
      primary_handoff_url = resolved.source_url,
      status = 'published',
      last_verified_at = now(),
      updated_at = now()
    from tmp_resolved_duplicate_rates resolved
    where combo.id = resolved.combo_id;

    create temporary table tmp_missing_duplicate_combinations on commit drop as
    with inserted as (
      insert into public.earning_combinations (
        store_id,
        status,
        title,
        total_value_label,
        summary,
        primary_handoff_url,
        last_verified_at,
        sort_order
      )
      select distinct
        resolved.store_id,
        'published',
        ${methodTitle("resolved.parser_key")},
        resolved.rate_label,
        ${methodSummary("resolved.parser_key", "resolved.store_name")},
        resolved.source_url,
        now(),
        0
      from tmp_resolved_duplicate_rates resolved
      where resolved.combo_id is null
      returning id, store_id
    )
    select * from inserted;

    insert into public.earning_combination_rates (
      combination_id,
      store_earning_rate_id,
      sort_order
    )
    select
      combination.id,
      resolved.rate_id,
      0
    from tmp_missing_duplicate_combinations combination
    join tmp_resolved_duplicate_rates resolved on resolved.store_id = combination.store_id
    on conflict do nothing;

    update public.ingestion_candidates candidate
    set
      status = 'promoted',
      reviewed_at = now(),
      review_note = ${sqlString(note)},
      promoted_store_earning_rate_id = resolved.rate_id,
      updated_at = now()
    from tmp_resolved_duplicate_rates resolved
    where candidate.id = resolved.candidate_id;

    select
      count(distinct candidate_id) as updated_count,
      ${sqlString("duplicates")} as mode,
      ${sqlString(note)} as review_note
    from tmp_resolved_duplicate_rates;

    commit;
  `;
}

function verifySql(note) {
  return `
    select
      store.name,
      method.slug as method,
      rate.rate_label,
      rate.status as rate_status,
      combo.total_value_label,
      combo.status as combo_status,
      candidate.status as candidate_status
    from public.ingestion_candidates candidate
    join public.store_earning_rates rate on rate.id = candidate.promoted_store_earning_rate_id
    join public.stores store on store.id = rate.store_id
    join public.earning_methods method on method.id = rate.earning_method_id
    left join public.earning_combination_rates combo_rate on combo_rate.store_earning_rate_id = rate.id
    left join public.earning_combinations combo on combo.id = combo_rate.combination_id
    where candidate.review_note = ${sqlString(note)}
    order by store.name, method.slug;
  `;
}

function whereClause(selectedMode) {
  if (selectedMode === "ready") {
    return `
      status = 'new'
      and review_signal_label = 'Klar til draft'
      and is_ready_for_store_earning is true
      and matches_existing_store is false
    `;
  }

  if (selectedMode === "matches") {
    return `
      status in ('new', 'needs_review', 'approved')
      and review_signal_label = 'Matcher butikk'
      and has_existing_store_method_rate is false
    `;
  }

  return `
    status in ('new', 'needs_review', 'approved')
    and review_signal_label = 'Mulig duplikat'
    and has_existing_store_method_rate is true
  `;
}

function methodTitle(parserKeySql) {
  return `
    case ${parserKeySql}
      when 'sas_eurobonus_shopping' then 'EuroBonus Online Shopping'
      when 'trumf_netthandel' then 'Trumf Netthandel'
      else 'Butikkopptjening'
    end
  `;
}

function methodSummary(parserKeySql, storeNameSql) {
  return `
    case ${parserKeySql}
      when 'sas_eurobonus_shopping'
        then 'Åpne ' || ${storeNameSql} || ' via SAS EuroBonus Online Shopping før kjøpet. Da bruker du den publiserte satsen vi har kontrollert for denne butikken.'
      when 'trumf_netthandel'
        then 'Åpne ' || ${storeNameSql} || ' via Trumf Netthandel før kjøpet. Da bruker du den publiserte Trumf-satsen vi har kontrollert for denne butikken.'
      else 'Bruk den dokumenterte opptjeningsmetoden før kjøpet.'
    end
  `;
}

function queryRows(sql) {
  const result = spawnSync(
    "npx",
    ["--yes", "supabase", "db", "query", "--linked", sql],
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

function printPreview(selectedMode, rows) {
  console.log(`Mode: ${selectedMode}`);
  console.log(`Limit: ${limit}`);
  console.log(`Action: ${execute ? "publish" : "dry-run"}`);
  console.log(`Candidates: ${rows.length}`);
  if (rows.length > 0) {
    console.table(rows);
  }
}

function defaultReviewNote(selectedMode) {
  const date = new Date().toISOString().slice(0, 10);
  return `Batch-publisert butikkopptjening ${date} (${selectedMode})`;
}

function sqlString(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
