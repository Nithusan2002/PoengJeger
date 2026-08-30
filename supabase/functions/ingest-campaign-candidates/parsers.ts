export type CandidateInput = {
  source_registry_id: string;
  source_url: string;
  title: string;
  summary: string | null;
  raw_content: string;
  normalized_hash: string;
  suggested_program_id: string | null;
  suggested_category_id: string | null;
  status: "new";
  metadata: Record<string, unknown>;
};

export type ParserSource = {
  id: string;
  parser_key: string | null;
  base_url?: string | null;
};

export type TrumfFeed = {
  merchants?: Record<string, {
    hostName?: string;
    urlName?: string;
    name?: string;
    cashbackDescription?: string;
    basicRate?: string;
  }>;
};

export type SasShopDetail = {
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

export type SasShopFeed = {
  data?: SasShopDetail[];
};

export type RememberStore = {
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

type CategorySuggestion = {
  id: string | null;
  slug: string | null;
  source: "keyword" | "default" | "unavailable";
};

const SAS_HANDOFF_BASE_URL = "https://onlineshopping.flysas.com/nb-NO/butikker";

export async function buildTrumfCandidates(
  source: ParserSource,
  feed: TrumfFeed,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
): Promise<CandidateInput[]> {
  const merchants = Object.values(feed.merchants ?? {})
    .filter((merchant) => merchant.name && merchant.urlName)
    .slice(0, limit);

  return Promise.all(merchants.map(async (merchant) => {
    const shopSlug = normalizeTrumfShopSlug(merchant.urlName!, merchant.name);
    const sourceUrl = `https://trumfnetthandel.no/cashback/${
      encodeURIComponent(merchant.urlName!)
    }`;
    const summary = trumfSummary(merchant.cashbackDescription || merchant.basicRate);
    const category = suggestMerchantCategory(categories, [
      merchant.name,
      merchant.urlName,
      merchant.hostName,
    ]);

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
      suggested_category_id: category.id,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        host_name: merchant.hostName ?? null,
        url_name: merchant.urlName,
        shop_slug: shopSlug,
        bonus_type: "cashback",
        suggested_category_slug: category.slug,
        suggested_category_source: category.source,
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

export function normalizeTrumfShopSlug(urlName: string, merchantName?: string): string {
  const nameSeed = merchantName
    ?.replace(/\.(no|com|se|dk|fi|net|org)\b/gi, " ")
    .replace(/\b(no|norge|norway)\b/gi, " ");
  const normalizedName = normalizeSearchText(nameSeed ?? merchantName ?? "");
  if (normalizedName === "bad") {
    return "badno";
  }
  if (normalizedName === "foto") {
    return "fotono";
  }
  if (normalizedName === "bosch") {
    return "bosch-home";
  }
  if (normalizedName === "siemens home") {
    return "siemens";
  }
  if (normalizedName === "gina tricot") {
    return "gina-tricot-ab";
  }
  if (normalizedName === "e wheels") {
    return "e-wheels-2";
  }
  if (normalizedName === "disney") {
    return "disney-1";
  }
  if (normalizedName === "jbl") {
    return "jbl-com";
  }
  if (normalizedName === "ellos") {
    return "ellos-3";
  }
  if (normalizedName === "lenovo") {
    return "lenovo-2";
  }
  if (normalizedName === "bakeren og kokken") {
    return "bagaren-och-kocken";
  }
  if (normalizedName === "bodystore") {
    return "bodystore-com";
  }
  if (normalizedName === "gullfunn") {
    return "gullfunn-1";
  }
  if (normalizedName === "l occitane") {
    return "loccitane";
  }
  if (normalizedName === "elektroimportoren") {
    return "elektroimportoren-no";
  }
  if (normalizedName === "fjord line") {
    return "fjordline";
  }
  if (normalizedName === "vy express") {
    return "vy-buss";
  }
  if (normalizedName === "askeladden navnelapper") {
    return "navnelapper";
  }
  if (normalizedName === "inkmann") {
    return "inkmann-2";
  }
  if (normalizedName === "lyko") {
    return "lyko-dk";
  }
  if (normalizedName === "storytel") {
    return "storytel-no";
  }
  if (normalizedName === "vidaxl" || normalizedName === "vida xl") {
    return "vida-xl-se";
  }
  if (normalizedName === "barbershop") {
    return "barbershop-no";
  }
  if (normalizedName === "polarn o pyret") {
    return "polarnopyret";
  }
  if (normalizedName === "parfym") {
    return "parfymno";
  }
  if (normalizedName === "philips hue") {
    return "philips-hue";
  }
  if (normalizedName === "skyshowtime") {
    return "sky-showtime";
  }
  if (normalizedName === "sofas and more") {
    return "sofas-more";
  }
  if (normalizedName === "tilbords") {
    return "tilbords-1";
  }
  if (normalizedName === "urverket") {
    return "urverket-no";
  }
  if (normalizedName === "vita") {
    return "vita-no";
  }
  if (normalizedName === "vpg") {
    return "vpg-no";
  }
  if (normalizedName === "zoo") {
    return "zoo-se-1";
  }
  if (normalizedName === "cs megastore") {
    return "computersalg";
  }
  if (normalizedName === "racketspesialisten") {
    return "racketspecialisten";
  }

  const fallbackSeed = urlName
    .replace(/^trumf[-_]?/i, "")
    .replace(/[-_]?trumf$/i, "")
    .replace(/[-_]?no$/i, "");

  return slugify(nameSeed || fallbackSeed);
}

export function trumfSummary(value?: string): string | null {
  const summary = value?.trim().replace(/(\d)\s*kr\b/gi, "$1 kr");
  if (!summary) {
    return null;
  }

  if (/\btrumf\b/i.test(summary)) {
    return summary;
  }

  return `${summary} Trumf-bonus`;
}

export function normalizeSasShopSlug(slug?: string, name?: string): string | null {
  const normalizedName = normalizeSearchText(name ?? "");
  if (normalizedName === "under armour") {
    return "under-armour";
  }
  if (normalizedName === "kinoklubb") {
    return "kinoklubben";
  }

  if (!slug) {
    return null;
  }

  return slugify(slug);
}

export async function buildSasCandidates(
  source: ParserSource,
  feed: SasShopFeed,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
  fallbackUrl: string,
): Promise<CandidateInput[]> {
  const shops = (feed.data ?? [])
    .filter((shop) => shop.name && shop.uuid)
    .slice(0, limit);

  return Promise.all(shops.map(async (shop) => {
    const summary = sasSummary(shop);
    const sourceUrl = sasSourceUrl(shop) || fallbackUrl;
    const shopSlug = normalizeSasShopSlug(shop.slug, shop.name);
    const category = suggestMerchantCategory(categories, [
      shop.name,
      shop.slug,
      String(shop.categoryId ?? ""),
      stripHtml(shop.description ?? ""),
    ]);

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
      suggested_category_id: category.id,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        shop_uuid: shop.uuid,
        shop_slug: shopSlug,
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
        suggested_category_slug: category.slug,
        suggested_category_source: category.source,
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

export async function buildRememberCandidates(
  source: ParserSource,
  html: string,
  programId: string | null,
  categories: Map<string, string>,
  limit: number,
): Promise<CandidateInput[]> {
  const stores = parseRememberStores(html)
    .filter((store) => store.enabled && store.name && store.slug)
    .filter((store) => !store.name!.toLowerCase().includes("direct deals"))
    .slice(0, limit);

  return Promise.all(stores.map(async (store) => {
    const summary = rememberSummary(store);
    const sourceUrl = `https://www.remember.no/reward/rabatt/${
      encodeURIComponent(store.slug!)
    }`;
    const category = suggestMerchantCategory(categories, [
      store.name,
      store.slug,
    ]);

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
      suggested_category_id: category.id,
      status: "new",
      metadata: {
        parser_key: source.parser_key,
        slug: store.slug,
        commission: store.commission ?? null,
        bonus_type: "cashback",
        suggested_category_slug: category.slug,
        suggested_category_source: category.source,
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
}

export function parseRememberStores(html: string): RememberStore[] {
  const nextDataMatch = html.match(
    /<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>/,
  );
  if (!nextDataMatch) {
    throw new Error("Could not find __NEXT_DATA__ in re:member page");
  }

  const nextData = JSON.parse(nextDataMatch[1]);
  return (nextData?.props?.pageProps?.stores ?? []) as RememberStore[];
}

export function sasSummary(shop: SasShopDetail): string | null {
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

export function rememberSummary(store: RememberStore): string | null {
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

export function suggestMerchantCategory(
  categories: Map<string, string>,
  values: Array<string | null | undefined>,
): CategorySuggestion {
  const haystack = normalizeSearchText(values.filter(Boolean).join(" "));
  const matchedSlug = categorySlugFromKeywords(haystack);

  if (matchedSlug && categories.has(matchedSlug)) {
    return {
      id: categories.get(matchedSlug) ?? null,
      slug: matchedSlug,
      source: "keyword",
    };
  }

  if (categories.has("annet")) {
    return {
      id: categories.get("annet") ?? null,
      slug: "annet",
      source: "default",
    };
  }

  if (categories.has("shopping")) {
    return {
      id: categories.get("shopping") ?? null,
      slug: "shopping",
      source: "default",
    };
  }

  return {
    id: null,
    slug: null,
    source: "unavailable",
  };
}

function sasSourceUrl(shop: SasShopDetail): string | null {
  if (!shop.slug || !shop.uuid) {
    return null;
  }
  return `${SAS_HANDOFF_BASE_URL}/${encodeURIComponent(shop.slug)}/${
    encodeURIComponent(shop.uuid)
  }`;
}

function categorySlugFromKeywords(value: string): string | null {
  const overrideSlug = categorySlugOverride(value);
  if (overrideSlug) {
    return overrideSlug;
  }

  const rules: Array<{ slug: string; terms: string[] }> = [
    {
      slug: "dagligvare",
      terms: [
        "dagligvare",
        "grocery",
        "matkasse",
        "matvarer",
        "meny",
        "kiwi",
        "spar",
        "joker",
        "oda",
        "kolonial",
        "godtlevert",
        "adamsmatkasse",
        "adams matkasse",
        "morgenlevering",
        "foodstuff",
      ],
    },
    {
      slug: "programvare",
      terms: [
        "programvare",
        "software",
        "security",
        "antivirus",
        "vpn",
        "avast",
        "avg",
        "norton",
        "mcafee",
      ],
    },
    {
      slug: "boker-medier",
      terms: [
        "fotoknudsen",
      ],
    },
    {
      slug: "elektronikk",
      terms: [
        "elektronikk",
        "electronics",
        "computer",
        "data",
        "pc",
        "gaming",
        "mobiltelefon",
        "hvitevarer",
        "tv",
        "lyd",
        "kamera",
        "komplett",
        "power",
        "elkjop",
        "elkjøp",
        "netonnet",
        "dustin",
        "proshop",
        "acer",
        "aeg",
        "bosch",
        "dyson",
        "electrolux",
        "elektroimportoren",
        "elektroimportøren",
        "elon",
        "batteriexperten",
        "harman kardon",
        "foto no",
        "fotoknudsen",
        "inkclub",
        "inkmann",
        "ideal of sweden",
        "estore",
        "hamphi",
        "jbl",
        "lenovo",
        "minifinder",
      ],
    },
    {
      slug: "klaer-sko",
      terms: [
        "klaer",
        "klær",
        "sko",
        "fashion",
        "mote",
        "clothing",
        "shoes",
        "sneakers",
        "boots",
        "zalando",
        "boozt",
        "nelly",
        "ellos",
        "h m",
        "hm",
        "dressmann",
        "cubus",
        "bikbok",
        "adidas",
        "aimn",
        "aim n",
        "asics",
        "bjorn borg",
        "björn borg",
        "bonprix",
        "bubbleroom",
        "chicastore",
        "edblad",
        "berg watches",
        "daniel wellington",
        "bagbrokers",
        "farfetch",
        "floyd",
        "g star",
        "gina tricot",
        "festkompaniet",
        "guttelus",
        "haglofs",
        "haglöfs",
        "helly hansen",
        "hunkemoller",
        "hunkemöller",
        "db",
        "emp",
        "gullfunn",
        "j lindeberg",
        "jlindeberg",
        "junkyard",
        "kouture",
        "lindex",
        "miinto",
      ],
    },
    {
      slug: "sport-fritid",
      terms: [
        "sport",
        "fritid",
        "trening",
        "fitness",
        "outdoor",
        "friluft",
        "sykkel",
        "ski",
        "jakt",
        "fiske",
        "tur",
        "lopeshop",
        "løpeshop",
        "fjellsport",
        "xxl",
        "gymgrossisten",
        "milrab",
        "e wheels",
        "evoride",
        "myprotein",
        "new balance",
      ],
    },
    {
      slug: "helse-skjonnhet",
      terms: [
        "helse",
        "skjonnhet",
        "skjønnhet",
        "beauty",
        "apotek",
        "pharmacy",
        "hudpleie",
        "makeup",
        "kosmetikk",
        "parfyme",
        "hair",
        "blivakker",
        "bangerhead",
        "lyko",
        "coverbrands",
        "farmasiet",
        "apotekhjem",
        "barbershop",
        "bodystore",
        "dentaworks",
        "fredrik louisa",
        "glowid",
        "hudprodukter",
        "kayani",
        "kicks",
        "kondomeriet",
        "dentway",
        "l occitane",
        "loccitane",
        "lenson",
        "lensway",
        "libresse",
        "maxa",
      ],
    },
    {
      slug: "barn-familie",
      terms: [
        "barn",
        "baby",
        "familie",
        "kids",
        "leker",
        "toys",
        "barneklær",
        "barneklaer",
        "jollyroom",
        "lekmer",
        "babymarkt",
        "babyshop",
        "navnelapper",
        "beckmann",
        "lappeliten",
        "lego",
        "mimmis",
      ],
    },
    {
      slug: "hus-hjem",
      terms: [
        "hus",
        "hjem",
        "home",
        "interior",
        "interiør",
        "interior",
        "mobel",
        "møbel",
        "furniture",
        "hage",
        "garden",
        "bygg",
        "verktoy",
        "verktøy",
        "kjokken",
        "kjøkken",
        "kitchen",
        "lampe",
        "lys",
        "ledlys",
        "lyskilder",
        "jernia",
        "clas ohlson",
        "kid",
        "princess",
        "kitchn",
        "kitch'n",
        "kitchenone",
        "bad stil",
        "bad no",
        "bakeren og kokken",
        "drommerom",
        "drømmerom",
        "ekstralys",
        "fyrklovern",
        "fyrklövern",
        "gront fokus",
        "grønt fokus",
        "hoie",
        "høie",
        "homeroom",
        "husqvarna",
        "inzpero",
        "karcher",
        "kärcher",
        "kokkeglede",
        "lexington",
        "lightup",
        "lunehjem",
        "newport",
      ],
    },
    {
      slug: "bil-motor",
      terms: [
        "bil",
        "motor",
        "bildeler",
        "autodeler",
        "autodoc",
        "autodude",
        "bilxtra",
        "dekk",
        "dekkonline",
        "eurodel",
      ],
    },
    {
      slug: "boker-medier",
      terms: [
        "bok",
        "boker",
        "bøker",
        "bokia",
        "blad",
        "bladkongen",
        "magasin",
        "media",
        "medier",
        "fabel",
        "kinogavekort",
        "kinoklubben",
      ],
    },
    {
      slug: "dyr-kjaeledyr",
      terms: [
        "dyr",
        "kjaeledyr",
        "kjæledyr",
        "pet",
        "pets",
        "dyrekassen",
        "zooplus",
        "vetzoo",
        "i love dogs",
      ],
    },
    {
      slug: "hotel",
      terms: [
        "hotel",
        "hotell",
        "hotels",
        "overnatting",
        "strawberry",
        "scandic",
        "thon",
        "radisson",
        "booking",
      ],
    },
    {
      slug: "reise",
      terms: [
        "reise",
        "travel",
        "flight",
        "fly",
        "tog",
        "buss",
        "ferie",
        "cruise",
        "leiebil",
        "rentalcar",
        "hertz",
        "avis leiebil",
        "vy",
        "norwegian",
        "auto europe",
        "budget",
        "click boat",
        "click and boat",
        "direct ferries",
        "campanyon",
        "fjord line",
        "getyourguide",
        "go city",
        "havila kystruten",
        "interhome",
        "lastminute",
        "lufthansa",
        "nazar",
      ],
    },
    {
      slug: "telecom",
      terms: [
        "telekom",
        "mobil",
        "mobile",
        "bredband",
        "broadband",
        "telia",
        "telenor",
        "onecall",
        "talkmore",
        "chilimobil",
        "ice",
      ],
    },
    {
      slug: "credit-card",
      terms: [
        "kredittkort",
        "creditcard",
        "credit card",
        "americanexpress",
        "american express",
        "mastercard",
        "visa",
        "amex",
      ],
    },
    {
      slug: "subscription",
      terms: [
        "abonnement",
        "subscription",
        "streaming",
        "lydbok",
        "storytel",
        "bookbeat",
        "viaplay",
        "tv2play",
        "disney",
        "spotify",
        "avisabonnement",
        "match com",
      ],
    },
  ];

  for (const rule of rules) {
    if (rule.terms.some((term) => matchesCategoryTerm(value, term))) {
      return rule.slug;
    }
  }

  return null;
}

function categorySlugOverride(value: string): string | null {
  const overrides: Array<{ slug: string; terms: string[] }> = [
    {
      slug: "hus-hjem",
      terms: [
        "aeg",
        "badno",
        "bad no",
        "bosch home",
        "christiania glasmagasin",
        "electrolux spares",
        "fortum strom",
        "fortum strøm",
        "gront fokus",
        "grønt fokus",
        "hultens",
        "hulténs",
        "homeroom",
        "jotex",
        "nordic nest",
        "onyx cookware",
        "p lindberg",
        "sharkninja",
        "skeidar",
        "slikkepott",
        "sofas and more",
        "smarta saker",
        "smartasaker",
        "lunehjem",
        "lusini",
        "lysman",
        "tempur",
        "tibber",
        "tilbords",
        "trendcarpet",
        "vinlagringskompaniet",
        "lanna mobler",
        "länna møbler",
        "vidaxl",
        "vida xl",
      ],
    },
    {
      slug: "dyr-kjaeledyr",
      terms: [
        "i love dogs",
        "ilovedogs",
        "vivara",
        "vetzoo",
        "zoo",
        "zoo no",
      ],
    },
    {
      slug: "reise",
      terms: [
        "amisol",
        "fjordline",
        "football travel",
        "omio",
        "qatar airways",
        "sembo",
        "trip",
        "tripx",
        "viator",
        "vy buss",
        "weloveholidays",
      ],
    },
    {
      slug: "telecom",
      terms: [
        "ice",
        "nordhost",
        "plussmobil",
        "trondermobil",
        "trøndermobil",
        "telia",
      ],
    },
    {
      slug: "klaer-sko",
      terms: [
        "ellos",
        "liffner",
        "mulberry",
        "oakley",
        "pilgrim",
        "puma",
        "safira",
        "superdry",
        "swims",
        "suitable",
        "tiger of sweden",
        "timarco",
        "under amour",
        "under armour",
        "urban pioneers",
        "urban pioneers concept store",
        "vakre vene",
        "viking footwear",
        "wakakuu",
        "weekday",
      ],
    },
    {
      slug: "sport-fritid",
      terms: [
        "e wheels",
        "e-wheels",
        "db",
        "haglofs",
        "haglöfs",
        "north trampoline",
        "outnorth",
        "proteinfabrikken",
        "racketspesialisten",
        "racketspecialisten",
        "skistart",
        "skogstad sport",
        "sportsmagasinet",
        "stormberg",
        "treningspartner",
        "vpg",
        "watery",
      ],
    },
    {
      slug: "barn-familie",
      terms: [
        "festkompaniet",
        "guttelus",
        "babyland",
        "lappeliten",
        "lekmer",
        "navnelapper",
        "patpat",
        "partyking",
        "polarn o pyret",
        "polarnopyret",
        "smaungene",
        "småungene",
        "superkul",
      ],
    },
    {
      slug: "elektronikk",
      terms: [
        "cs megastore",
        "farnell",
        "iphonehuset",
        "philips hue",
        "razer",
        "marshall",
        "sackit",
        "lux case",
        "lux-case",
        "xplora",
      ],
    },
    {
      slug: "helse-skjonnhet",
      terms: [
        "bodystore",
        "dentway",
        "kost1",
        "maxulin",
        "memira",
        "nordicfeel",
        "nytelse",
        "oslo skin lab",
        "parfym",
        "sephora",
        "senze of joy",
        "soma",
        "vita",
      ],
    },
    {
      slug: "boker-medier",
      terms: [
        "bokia",
        "kinoklubb",
        "kinoklubben",
        "norli",
        "nordic print",
        "prime video",
        "skyshowtime",
        "sky showtime",
        "vistaprint",
      ],
    },
    {
      slug: "subscription",
      terms: [
        "bookbeat",
        "fabel",
        "nextory",
        "readly",
        "storytel",
        "strim",
      ],
    },
    {
      slug: "dagligvare",
      terms: [
        "nespresso",
      ],
    },
  ];

  for (const override of overrides) {
    if (override.terms.some((term) => matchesCategoryTerm(value, term))) {
      return override.slug;
    }
  }

  return null;
}

function matchesCategoryTerm(value: string, term: string): boolean {
  const normalizedTerm = normalizeSearchText(term);
  if (!normalizedTerm) {
    return false;
  }

  if (normalizedTerm.length <= 3) {
    return ` ${value} `.includes(` ${normalizedTerm} `);
  }

  return value.includes(normalizedTerm);
}

function normalizeSearchText(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/æ/g, "ae")
    .replace(/ø/g, "o")
    .replace(/å/g, "a")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function slugify(value: string): string {
  return normalizeSearchText(value).replace(/\s+/g, "-");
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
