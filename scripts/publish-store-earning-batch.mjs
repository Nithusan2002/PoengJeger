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
    with source_rows as (
      select
        gen_random_uuid() as combination_id,
        rate.store_id,
        promoted.rate_id,
        promoted.parser_key,
        rate.rate_label,
        rate.handoff_url,
        store.name as store_name
      from tmp_promoted_store_earning_rates promoted
      join public.store_earning_rates rate on rate.id = promoted.rate_id
      join public.stores store on store.id = rate.store_id
    ),
    inserted as (
      insert into public.earning_combinations (
        id,
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
        source.combination_id,
        source.store_id,
        'published',
        ${methodTitle("source.parser_key")},
        source.rate_label,
        ${methodSummary("source.parser_key", "source.store_name")},
        source.handoff_url,
        now(),
        0
      from source_rows source
      returning id, store_id
    )
    select
      inserted.id,
      inserted.store_id,
      source.rate_id
    from inserted
    join source_rows source on source.combination_id = inserted.id;

    insert into public.earning_combination_rates (
      combination_id,
      store_earning_rate_id,
      sort_order
    )
    select
      combination.id,
      combination.rate_id,
      0
    from tmp_inserted_combinations combination
    on conflict do nothing;

    ${normalizeMixedSasTrumfRecommendationsSql(`
      select distinct rate.store_id
      from tmp_promoted_store_earning_rates promoted
      join public.store_earning_rates rate on rate.id = promoted.rate_id
    `)}

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
    with source_rows as (
      select distinct
        gen_random_uuid() as combination_id,
        resolved.store_id,
        resolved.rate_id,
        resolved.parser_key,
        resolved.rate_label,
        resolved.source_url,
        resolved.store_name
      from tmp_resolved_duplicate_rates resolved
      where resolved.combo_id is null
    ),
    inserted as (
      insert into public.earning_combinations (
        id,
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
        source.combination_id,
        source.store_id,
        'published',
        ${methodTitle("source.parser_key")},
        source.rate_label,
        ${methodSummary("source.parser_key", "source.store_name")},
        source.source_url,
        now(),
        0
      from source_rows source
      returning id, store_id
    )
    select
      inserted.id,
      inserted.store_id,
      source.rate_id
    from inserted
    join source_rows source on source.combination_id = inserted.id;

    insert into public.earning_combination_rates (
      combination_id,
      store_earning_rate_id,
      sort_order
    )
    select
      combination.id,
      combination.rate_id,
      0
    from tmp_missing_duplicate_combinations combination
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

    ${normalizeMixedSasTrumfRecommendationsSql(`
      select distinct store_id
      from tmp_resolved_duplicate_rates
    `)}

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

function normalizeMixedSasTrumfRecommendationsSql(storeIdsSql) {
  return `
    create temporary table tmp_mixed_sas_trumf_stores on commit drop as
    with touched_stores as (
      ${storeIdsSql}
    )
    select touched.store_id
    from touched_stores touched
    where exists (
      select 1
      from public.store_earning_rates rate
      join public.earning_methods method on method.id = rate.earning_method_id
      where rate.store_id = touched.store_id
        and rate.status = 'published'
        and method.slug = 'trumf'
        and position('%' in rate.rate_label) > 0
        and rate.rate_label not ilike '%opptil%'
        and public.extract_first_decimal(rate.rate_label) is not null
    )
      and exists (
        select 1
        from public.store_earning_rates rate
        join public.earning_methods method on method.id = rate.earning_method_id
        where rate.store_id = touched.store_id
          and rate.status = 'published'
          and method.slug = 'sas-eurobonus-online-shopping'
          and rate.rate_label ilike '%per 100 kr%'
          and public.extract_first_decimal(rate.rate_label) is not null
      );

    update public.store_earning_rates rate
    set
      value_summary = case method.slug
        when 'trumf' then
          public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label), 2)
          || ' kr Trumf-bonus per 100 kr. Ved overføring til SAS EuroBonus tilsvarer det '
          || public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label) * 10, 2)
          || ' poeng ved engangsoverføring eller '
          || public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label) * 13.5, 2)
          || ' poeng ved automatisk overføring.'
        when 'sas-eurobonus-online-shopping' then
          public.format_norwegian_decimal(public.extract_first_decimal(rate.rate_label), 2)
          || ' EuroBonus-poeng per 100 kr.'
        else rate.value_summary
      end,
      warning_text = case method.slug
        when 'trumf' then
          'EuroBonus-ekvivalensen er beregnet fra Trumfs overføringskurser: 10 poeng per Trumf-krone ved engangsoverføring og 13,5 poeng per Trumf-krone ved automatisk overføring. Du kan ikke bruke både Trumf Netthandel og SAS EuroBonus Online Shopping på samme portalklikk.'
        when 'sas-eurobonus-online-shopping' then
          'Sammenlign mot Trumf Netthandel når kunden kan overføre Trumf-bonus til SAS EuroBonus. Du kan ikke bruke både SAS EuroBonus Online Shopping og Trumf Netthandel på samme portalklikk.'
        else rate.warning_text
      end,
      sort_order = case method.slug
        when 'trumf' then 10
        when 'sas-eurobonus-online-shopping' then 20
        else rate.sort_order
      end,
      updated_at = now()
    from public.earning_methods method
    join tmp_mixed_sas_trumf_stores mixed on true
    where method.id = rate.earning_method_id
      and rate.store_id = mixed.store_id
      and rate.status = 'published'
      and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
      and (
        (
          method.slug = 'trumf'
          and position('%' in rate.rate_label) > 0
          and rate.rate_label not ilike '%opptil%'
        )
        or (
          method.slug = 'sas-eurobonus-online-shopping'
          and rate.rate_label ilike '%per 100 kr%'
        )
      )
      and public.extract_first_decimal(rate.rate_label) is not null;

    with scored_combinations as (
      select
        combo.id as combination_id,
        store.id as store_id,
        store.name as store_name,
        method.slug as method_slug,
        rate.handoff_url,
        public.extract_first_decimal(rate.rate_label) as documented_rate,
        case method.slug
        when 'trumf' then public.extract_first_decimal(rate.rate_label) * 13.5
        when 'sas-eurobonus-online-shopping' then public.extract_first_decimal(rate.rate_label)
          else null
        end as eurobonus_auto_points_per_100,
        case method.slug
          when 'trumf' then public.extract_first_decimal(rate.rate_label) * 10
          else null
        end as eurobonus_single_points_per_100
      from tmp_mixed_sas_trumf_stores mixed
      join public.stores store on store.id = mixed.store_id
      join public.earning_combinations combo on combo.store_id = mixed.store_id
      join public.earning_combination_rates combo_rate on combo_rate.combination_id = combo.id
      join public.store_earning_rates rate on rate.id = combo_rate.store_earning_rate_id
      join public.earning_methods method on method.id = rate.earning_method_id
      where combo.status = 'published'
        and rate.status = 'published'
        and method.slug in ('trumf', 'sas-eurobonus-online-shopping')
        and (
          (
            method.slug = 'trumf'
            and position('%' in rate.rate_label) > 0
            and rate.rate_label not ilike '%opptil%'
          )
          or (
            method.slug = 'sas-eurobonus-online-shopping'
            and rate.rate_label ilike '%per 100 kr%'
          )
        )
        and public.extract_first_decimal(rate.rate_label) is not null
    ),
    ranked_combinations as (
      select
        *,
        row_number() over (
          partition by store_id
          order by eurobonus_auto_points_per_100 desc, method_slug desc
        ) * 10 as resolved_sort_order
      from scored_combinations
    )
    update public.earning_combinations combo
    set
      total_value_label = public.format_norwegian_decimal(ranked.eurobonus_auto_points_per_100, 2)
        || ' EB-poeng / 100 kr',
      summary = case ranked.method_slug
        when 'trumf' then
          'Start hos Trumf Netthandel før du handler hos '
          || ranked.store_name
          || '. '
          || public.format_norwegian_decimal(ranked.documented_rate, 2)
          || ' % Trumf-bonus gir '
          || public.format_norwegian_decimal(ranked.documented_rate, 2)
          || ' Trumf-kroner per 100 kr, som kan bli '
          || public.format_norwegian_decimal(ranked.eurobonus_auto_points_per_100, 2)
          || ' EuroBonus-poeng med automatisk overføring eller '
          || public.format_norwegian_decimal(ranked.eurobonus_single_points_per_100, 2)
          || ' poeng ved engangsoverføring.'
        when 'sas-eurobonus-online-shopping' then
          'Start hos SAS EuroBonus Online Shopping før du handler hos '
          || ranked.store_name
          || ' hvis du vil ha direkte EuroBonus-opptjening uten å gå via Trumf.'
        else combo.summary
      end,
      easier_alternative_label = case ranked.method_slug
        when 'trumf' then (
          select public.format_norwegian_decimal(max(other.eurobonus_auto_points_per_100), 2)
            || ' EB-poeng / 100 kr direkte via SAS'
          from ranked_combinations other
          where other.store_id = ranked.store_id
            and other.method_slug = 'sas-eurobonus-online-shopping'
        )
        else combo.easier_alternative_label
      end,
      warning_text = case ranked.method_slug
        when 'trumf' then
          'Beregningen forutsetter at 1 Trumf-krone gir 13,5 EuroBonus-poeng ved automatisk overføring. Ved engangsoverføring er dokumentert minimum '
          || public.format_norwegian_decimal(ranked.eurobonus_single_points_per_100, 2)
          || ' EuroBonus-poeng per 100 kr. Kontroller satsen i portalen før kjøp.'
        when 'sas-eurobonus-online-shopping' then
          'SAS-satsen kan være lavere enn Trumf-alternativet målt som EuroBonus-ekvivalent, men enklere hvis du ikke vil bruke Trumf-overføring.'
        else combo.warning_text
      end,
      primary_handoff_url = ranked.handoff_url,
      last_verified_at = now(),
      sort_order = ranked.resolved_sort_order,
      updated_at = now()
    from ranked_combinations ranked
    where combo.id = ranked.combination_id;

    drop table if exists tmp_mixed_sas_trumf_stores;
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
