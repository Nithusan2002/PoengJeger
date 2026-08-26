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
    const sourceUrl = `https://trumfnetthandel.no/cashback/${
      encodeURIComponent(merchant.urlName!)
    }`;
    const summary = merchant.cashbackDescription || merchant.basicRate || null;
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
        bonus_type: "cashback",
        suggested_category_slug: category.slug,
        suggested_category_source: category.source,
        missing_bonus_value: !summary,
        requires_editorial_review: true,
      },
    };
  }));
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
        shop_slug: shop.slug ?? null,
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
