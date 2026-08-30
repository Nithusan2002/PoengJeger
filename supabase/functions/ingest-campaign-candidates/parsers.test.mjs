import assert from "node:assert/strict";
import { webcrypto } from "node:crypto";
import test from "node:test";

globalThis.crypto ??= webcrypto;

import {
  buildRememberCandidates,
  buildSasCandidates,
  buildTrumfCandidates,
  normalizeSasShopSlug,
  normalizeTrumfShopSlug,
  parseRememberStores,
  rememberSummary,
  sasSummary,
  suggestMerchantCategory,
  trumfSummary,
} from "./parsers.ts";

const categories = new Map([
  ["dagligvare", "cat-grocery"],
  ["elektronikk", "cat-electronics"],
  ["barn-familie", "cat-family"],
  ["boker-medier", "cat-media"],
  ["dyr-kjaeledyr", "cat-pets"],
  ["hotel", "cat-hotel"],
  ["hus-hjem", "cat-home"],
  ["helse-skjonnhet", "cat-beauty"],
  ["klaer-sko", "cat-fashion"],
  ["reise", "cat-travel"],
  ["sport-fritid", "cat-sport"],
  ["subscription", "cat-subscription"],
  ["telecom", "cat-telecom"],
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
  assert.equal(candidates[0].summary, "4 % Trumf-bonus");
  assert.equal(candidates[0].suggested_program_id, "program-trumf");
  assert.equal(candidates[0].suggested_category_id, "cat-electronics");
  assert.equal(candidates[0].metadata.requires_editorial_review, true);
  assert.equal(candidates[0].metadata.missing_bonus_value, false);
  assert.equal(candidates[0].metadata.shop_slug, "komplett");
  assert.equal(candidates[1].summary, null);
  assert.equal(candidates[1].metadata.missing_bonus_value, true);
  assert.match(candidates[0].normalized_hash, /^[a-f0-9]{64}$/);
});

test("Trumf parser normalizes technical url names into clean shop slugs", async () => {
  const candidates = await buildTrumfCandidates(
    { id: "source-trumf", parser_key: "trumf_netthandel" },
    {
      merchants: {
        gymgrossisten: {
          hostName: "gymgrossisten.no",
          urlName: "trumfgymgrossisten",
          name: "Gymgrossisten",
          cashbackDescription: "Opptil 4,6%",
        },
        inkclub: {
          hostName: "www.inkclub.com",
          urlName: "trumfinkclub-no",
          name: "inkClub.com",
          cashbackDescription: "11,7%",
        },
        mimmis: {
          hostName: "www.mimmis.no",
          urlName: "mimmistrumf",
          name: "mimmis",
          cashbackDescription: "3,1%",
        },
      },
    },
    "program-trumf",
    categories,
    10,
  );

  assert.deepEqual(
    candidates.map((candidate) => candidate.metadata.shop_slug),
    ["gymgrossisten", "inkclub", "mimmis"],
  );
});

test("Trumf shop slug fallback strips Trumf transport affixes", () => {
  assert.equal(normalizeTrumfShopSlug("trumfgymgrossisten"), "gymgrossisten");
  assert.equal(normalizeTrumfShopSlug("trumfinkclub-no"), "inkclub");
  assert.equal(normalizeTrumfShopSlug("mimmistrumf"), "mimmis");
  assert.equal(normalizeTrumfShopSlug("babybanden-trumf"), "babybanden");
  assert.equal(normalizeTrumfShopSlug("bad", "Bad.no"), "badno");
  assert.equal(normalizeTrumfShopSlug("foto", "Foto.no"), "fotono");
  assert.equal(normalizeTrumfShopSlug("bosch", "Bosch"), "bosch-home");
  assert.equal(normalizeTrumfShopSlug("siemens-home", "Siemens Home"), "siemens");
  assert.equal(normalizeTrumfShopSlug("gina-tricot", "Gina Tricot"), "gina-tricot-ab");
  assert.equal(normalizeTrumfShopSlug("e-wheels", "E-Wheels"), "e-wheels-2");
  assert.equal(normalizeTrumfShopSlug("disney", "Disney+"), "disney-1");
  assert.equal(normalizeTrumfShopSlug("jbl", "JBL"), "jbl-com");
  assert.equal(normalizeTrumfShopSlug("ellos", "Ellos NO"), "ellos-3");
  assert.equal(normalizeTrumfShopSlug("lenovo", "Lenovo"), "lenovo-2");
  assert.equal(normalizeTrumfShopSlug("bakeren-og-kokken", "Bakeren og Kokken"), "bagaren-och-kocken");
  assert.equal(normalizeTrumfShopSlug("bodystore", "Bodystore"), "bodystore-com");
  assert.equal(normalizeTrumfShopSlug("gullfunn", "Gullfunn"), "gullfunn-1");
  assert.equal(normalizeTrumfShopSlug("l-occitane", "L'Occitane"), "loccitane");
  assert.equal(normalizeTrumfShopSlug("elektroimportoren", "Elektroimportøren"), "elektroimportoren-no");
  assert.equal(normalizeTrumfShopSlug("fjord-line", "Fjord Line"), "fjordline");
  assert.equal(normalizeTrumfShopSlug("vy-express", "VY Express"), "vy-buss");
  assert.equal(normalizeTrumfShopSlug("askeladden-navnelapper", "Askeladden Navnelapper"), "navnelapper");
  assert.equal(normalizeTrumfShopSlug("inkmann", "Inkmann"), "inkmann-2");
  assert.equal(normalizeTrumfShopSlug("lyko", "LYKO"), "lyko-dk");
  assert.equal(normalizeTrumfShopSlug("storytel", "Storytel"), "storytel-no");
  assert.equal(normalizeTrumfShopSlug("vidaxl", "VidaXL"), "vida-xl-se");
  assert.equal(normalizeTrumfShopSlug("barbershop", "Barbershop"), "barbershop-no");
  assert.equal(normalizeTrumfShopSlug("polarn-o-pyret", "Polarn O. Pyret"), "polarnopyret");
  assert.equal(normalizeTrumfShopSlug("parfym", "Parfym"), "parfymno");
  assert.equal(normalizeTrumfShopSlug("skyshowtime", "SkyShowtime"), "sky-showtime");
  assert.equal(normalizeTrumfShopSlug("tilbords", "Tilbords"), "tilbords-1");
  assert.equal(normalizeTrumfShopSlug("urverket", "Urverket"), "urverket-no");
  assert.equal(normalizeTrumfShopSlug("vita", "Vita"), "vita-no");
  assert.equal(normalizeTrumfShopSlug("vpg", "VPG"), "vpg-no");
  assert.equal(normalizeTrumfShopSlug("zoo", "ZOO"), "zoo-se-1");
  assert.equal(normalizeTrumfShopSlug("cs-megastore", "CS MEGASTORE"), "computersalg");
  assert.equal(normalizeTrumfShopSlug("racketspesialisten", "Racketspesialisten"), "racketspecialisten");
});

test("Trumf summary labels plain cashback rates", () => {
  assert.equal(trumfSummary("3,1%"), "3,1% Trumf-bonus");
  assert.equal(trumfSummary("Opptil 4,6%"), "Opptil 4,6% Trumf-bonus");
  assert.equal(trumfSummary("Opptil 270kr"), "Opptil 270 kr Trumf-bonus");
  assert.equal(trumfSummary("4 % Trumf-bonus"), "4 % Trumf-bonus");
  assert.equal(trumfSummary(undefined), null);
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

test("SAS shop slug applies editorial fixes for known source typos", () => {
  assert.equal(normalizeSasShopSlug("under-amour", "Under Armour"), "under-armour");
  assert.equal(normalizeSasShopSlug("kinoklubb", "Kinoklubb"), "kinoklubben");
  assert.equal(normalizeSasShopSlug("vita-no", "VITA"), "vita-no");
  assert.equal(normalizeSasShopSlug(undefined, "Mangler slug"), null);
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

test("category suggestion applies editorial overrides before broad keywords", () => {
  assert.deepEqual(
    suggestMerchantCategory(categories, ["AEG", "www.aeg.no", "hvitevarer"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Treningspartner", "www.treningspartner.no"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Christiania Glasmagasin", "www.cg.no"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["VetZoo", "hjem til kjæledyr"]),
    { id: "cat-pets", slug: "dyr-kjaeledyr", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Vy Buss", "sport og tur"]),
    { id: "cat-travel", slug: "reise", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Trøndermobil", "mobiltelefon"]),
    { id: "cat-telecom", slug: "telecom", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["VidaXL", "outdoor furniture"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Trendcarpet", "pet friendly carpet"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Lysman", "dagligvare lys"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Lusini", "klær og serveringsutstyr"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Lunehjem.no", "helse interiør"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Memira", "kamera og øyehelse"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Homeroom", "fashion home"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["I love dogs", "fashion"]),
    { id: "cat-pets", slug: "dyr-kjaeledyr", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["ICE", "elektronikk mobil"]),
    { id: "cat-telecom", slug: "telecom", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Fortum Strøm", "dagligvare"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Football Travel", "dagligvare"]),
    { id: "cat-travel", slug: "reise", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Fjordline", "bil"]),
    { id: "cat-travel", slug: "reise", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Festkompaniet", "elektronikk"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Farnell", "klær"]),
    { id: "cat-electronics", slug: "elektronikk", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Fabel", "barnebøker"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Ellos", "elektronikk"]),
    { id: "cat-fashion", slug: "klaer-sko", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Electrolux Spares & accessories", "dagligvare"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["E-Wheels", "dagligvare"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Dentway", "hus og hjem"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["FotoKnudsen", "kamera"]),
    { id: "cat-media", slug: "boker-medier", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Bookbeat", "elektronikk"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Bokia", "leker"]),
    { id: "cat-media", slug: "boker-medier", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Bodystore", "matvarer"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Bosch Home", "elektronikk"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Tempur", "fashion"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Sportsmagasinet", "bøker"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Oslo Skin Lab", "sport"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Nespresso", "shopping"]),
    { id: "cat-grocery", slug: "dagligvare", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Marshall", "shopping"]),
    { id: "cat-electronics", slug: "elektronikk", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Maxulin", "shopping"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Länna Møbler", "shopping"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["SkyShowtime", "shopping"]),
    { id: "cat-media", slug: "boker-medier", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["SharkNinja", "shopping"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Qatar Airways", "shopping"]),
    { id: "cat-travel", slug: "reise", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["North Trampoline", "shopping"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Db", "fashion"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Bad.no", "elektronikk"]),
    { id: "cat-home", slug: "hus-hjem", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Babyland", "klær"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Lekmer", "klær og leker"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Lappeliten", "klær og merkelapper"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Kost1", "sport og kosttilskudd"]),
    { id: "cat-beauty", slug: "helse-skjonnhet", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Haglöfs", "klær og outdoor"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Guttelus", "klær"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Skogstad Sport", "klær"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Skistart.com", "ski clothing"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Razer", "software gaming"]),
    { id: "cat-electronics", slug: "elektronikk", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Proteinfabrikken", "klær og trening"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Outnorth", "fashion outdoor"]),
    { id: "cat-sport", slug: "sport-fritid", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Norli", "elektronisk gavekort"]),
    { id: "cat-media", slug: "boker-medier", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Nordhost", "hotell"]),
    { id: "cat-telecom", slug: "telecom", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Nordic Print", "familiefoto"]),
    { id: "cat-media", slug: "boker-medier", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["PlussMobil", "mobiltelefon"]),
    { id: "cat-telecom", slug: "telecom", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Polarn O. Pyret", "klær"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["PatPat", "fashion"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Navnelapper", "klær"]),
    { id: "cat-family", slug: "barn-familie", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Mulberry", "magasin"]),
    { id: "cat-fashion", slug: "klaer-sko", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Readly", "magasin"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Under Armour", "sport clothing"]),
    { id: "cat-fashion", slug: "klaer-sko", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["SWIMS", "sko"]),
    { id: "cat-fashion", slug: "klaer-sko", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Suitable", "menswear"]),
    { id: "cat-fashion", slug: "klaer-sko", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Telia", "bredbånd og tv"]),
    { id: "cat-telecom", slug: "telecom", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Strim", "streaming"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Storytel", "lydbok"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
  );
  assert.deepEqual(
    suggestMerchantCategory(categories, ["Nextory", "bøker"]),
    { id: "cat-subscription", slug: "subscription", source: "keyword" },
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
