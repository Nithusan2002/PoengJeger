import assert from "node:assert/strict";
import test from "node:test";

import {
  buildRememberCandidates,
  buildSasCandidates,
  buildTrumfCandidates,
  parseRememberStores,
  rememberSummary,
  sasSummary,
  suggestMerchantCategory,
} from "./parsers.ts";

const categories = new Map([
  ["elektronikk", "cat-electronics"],
  ["hotel", "cat-hotel"],
  ["annet", "cat-other"],
]);

test("Trumf parser creates editorial candidates and flags missing bonus values", async () => {
  const candidates = await buildTrumfCandidates(
    { id: "source-trumf", parser_key: "trumf_netthandel" },
    {
      merchants: {
        komplett: {
          hostName: "komplett.no",
          urlName: "komplett",
          name: "Komplett",
          cashbackDescription: "4 % Trumf-bonus",
        },
        unknown: {
          hostName: "example.no",
          urlName: "unknown",
          name: "Ukjent butikk",
        },
        invalid: {
          name: "Mangler urlName",
        },
      },
    },
    "program-trumf",
    categories,
    10,
  );

  assert.equal(candidates.length, 2);
  assert.deepEqual(candidates.map((candidate) => candidate.status), ["new", "new"]);
  assert.equal(candidates[0].title, "Trumf: Komplett");
  assert.equal(candidates[0].suggested_program_id, "program-trumf");
  assert.equal(candidates[0].suggested_category_id, "cat-electronics");
  assert.equal(candidates[0].metadata.requires_editorial_review, true);
  assert.equal(candidates[0].metadata.missing_bonus_value, false);
  assert.equal(candidates[1].summary, null);
  assert.equal(candidates[1].metadata.missing_bonus_value, true);
  assert.match(candidates[0].normalized_hash, /^[a-f0-9]{64}$/);
});

test("Trumf parser returns no candidates for an empty response", async () => {
  const candidates = await buildTrumfCandidates(
    { id: "source-trumf", parser_key: "trumf_netthandel" },
    {},
    "program-trumf",
    categories,
    10,
  );

  assert.deepEqual(candidates, []);
});

test("SAS parser limits valid shops and keeps candidates as editorial drafts", async () => {
  const candidates = await buildSasCandidates(
    { id: "source-sas", parser_key: "sas_eurobonus_shopping" },
    {
      data: [
        {
          uuid: "shop-1",
          slug: "radisson",
          name: "Radisson Hotels",
          commission_type: "variable",
          points: 500,
          has_campaign: true,
          campaign_ends_date: "2026-09-01",
          description: "<p>Hotell og overnatting</p>",
        },
        {
          uuid: "shop-2",
          slug: "no-points",
          name: "Uten poeng",
          points: 0,
        },
        {
          name: "Mangler uuid",
          points: 100,
        },
      ],
    },
    "program-sas",
    categories,
    1,
    "https://fallback.example/feed",
  );

  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].title, "SAS EuroBonus Shopping: Radisson Hotels");
  assert.equal(candidates[0].summary, "500 EuroBonus-poeng per 100 kr, kampanje til 2026-09-01");
  assert.equal(candidates[0].source_url, "https://onlineshopping.flysas.com/nb-NO/butikker/radisson/shop-1");
  assert.equal(candidates[0].suggested_category_id, "cat-hotel");
  assert.equal(candidates[0].metadata.requires_editorial_review, true);
  assert.equal(candidates[0].metadata.missing_bonus_value, false);
});

test("SAS summary returns null instead of guessing missing values", () => {
  assert.equal(sasSummary({ name: "Uten poeng", points: 0 }), null);
  assert.equal(
    sasSummary({
      name: "Fast bonus",
      commission_type: "fixed",
      points: 1000,
    }),
    "1 000 EuroBonus-poeng",
  );
});

test("re:member parser filters disabled and direct-deal stores", async () => {
  const html = rememberHtml([
    {
      slug: "elkjop",
      name: "Elkjøp",
      enabled: true,
      maxPercentageValue: 5,
    },
    {
      slug: "direct",
      name: "Direct Deals Norge",
      enabled: true,
      maxPercentageValue: 99,
    },
    {
      slug: "disabled",
      name: "Skjult butikk",
      enabled: false,
      maxPercentageValue: 10,
    },
  ]);

  const candidates = await buildRememberCandidates(
    { id: "source-remember", parser_key: "remember_reward" },
    html,
    null,
    categories,
    10,
  );

  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].title, "re:member reward: Elkjøp");
  assert.equal(candidates[0].summary, "5%");
  assert.equal(candidates[0].suggested_program_id, null);
  assert.equal(candidates[0].suggested_category_id, "cat-electronics");
  assert.equal(candidates[0].metadata.requires_editorial_review, true);
  assert.equal(candidates[0].status, "new");
});

test("re:member parser rejects pages without Next data", () => {
  assert.throws(
    () => parseRememberStores("<html></html>"),
    /Could not find __NEXT_DATA__/,
  );
});

test("remember summary handles ranged rates and missing values explicitly", () => {
  assert.equal(
    rememberSummary({
      commission: [
        { value: 2, type: "PERCENTAGE", description: "Lav" },
        { value: 7, type: "PERCENTAGE", description: "Høy" },
      ],
    }),
    "2-7%*",
  );
  assert.equal(rememberSummary({}), null);
});

test("category suggestion falls back when no keyword matches", () => {
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Ukjent nisjebutikk"]),
    { id: "cat-other", slug: "annet", source: "default" },
  );
});

function rememberHtml(stores) {
  return `
    <html>
      <script id="__NEXT_DATA__" type="application/json">
        ${JSON.stringify({ props: { pageProps: { stores } } })}
      </script>
    </html>
  `;
}
