import Foundation

struct Store: Identifiable, Hashable {
    enum Status: String, Codable, Hashable {
        case draft
        case review
        case published
        case archived
    }

    let id: UUID
    let slug: String
    let name: String
    let category: CampaignCategory?
    let status: Status
    let websiteURL: URL?
    let searchKeywords: [String]
    let lastVerifiedAt: Date?
    let earningRates: [StoreEarningRate]
    let combinations: [EarningCombination]

    var isPublished: Bool {
        status == .published
    }

    var baseRates: [StoreEarningRate] {
        earningRates
            .filter(\.isBaseRate)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var activePromotions: [StoreEarningRate] {
        earningRates
            .filter { !$0.isBaseRate && $0.isActive }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedEarningRates: [StoreEarningRate] {
        earningRates.sorted { $0.sortOrder < $1.sortOrder }
    }

    var bestCombination: EarningCombination? {
        bestCombination(for: [])
    }

    func bestCombination(for selectedProgramIDs: Set<UUID>) -> EarningCombination? {
        let usableCombinations = combinations
            .filter { $0.status == .published && isUsableCombination($0) }

        if !selectedProgramIDs.isEmpty {
            let selectedCombinations = usableCombinations
                .filter { combinationMatchesSelectedPrograms($0, selectedProgramIDs: selectedProgramIDs) }
                .sorted { $0.sortOrder < $1.sortOrder }

            if let selectedCombination = selectedCombinations.first {
                return selectedCombination
            }
        }

        return usableCombinations
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
    }

    func hasSelectedProgramEarning(for selectedProgramIDs: Set<UUID>) -> Bool {
        guard !selectedProgramIDs.isEmpty else { return hasVerifiedEarning }

        return bestCombination(for: selectedProgramIDs).map {
            combinationMatchesSelectedPrograms($0, selectedProgramIDs: selectedProgramIDs)
        } == true || earningRates.contains { $0.isActive && $0.matchesSelectedPrograms(selectedProgramIDs) }
    }

    func matches(_ query: String) -> Bool {
        StoreSearchMatch(store: self, query: query).score > 0
    }

    private func isUsableCombination(_ combination: EarningCombination) -> Bool {
        guard !combination.rateIDs.isEmpty else { return true }

        let ratesByID = Dictionary(uniqueKeysWithValues: earningRates.map { ($0.id, $0) })
        let includedRates = combination.rateIDs.compactMap { ratesByID[$0] }

        guard includedRates.count == combination.rateIDs.count else { return false }
        return includedRates.allSatisfy(\.isActive)
    }

    private func combinationMatchesSelectedPrograms(_ combination: EarningCombination, selectedProgramIDs: Set<UUID>) -> Bool {
        guard !selectedProgramIDs.isEmpty else { return true }

        let ratesByID = Dictionary(uniqueKeysWithValues: earningRates.map { ($0.id, $0) })
        let includedRates = combination.rateIDs.compactMap { ratesByID[$0] }
        let programIDs = Set(includedRates.compactMap(\.method.programID))

        return !programIDs.isEmpty && programIDs.isSubset(of: selectedProgramIDs)
    }
}

struct EarningMethod: Identifiable, Hashable {
    enum MethodType: String, Codable, Hashable {
        case portal
        case card
        case loyalty
        case campaign
        case manual
    }

    let id: UUID
    let slug: String
    let name: String
    let type: MethodType
    let programID: UUID?
    let description: String?
}

struct StoreEarningRate: Identifiable, Hashable {
    enum Status: String, Codable, Hashable {
        case draft
        case published
        case expired
        case archived
    }

    let id: UUID
    let method: EarningMethod
    let status: Status
    let rateLabel: String
    let normalRateLabel: String?
    let valueSummary: String?
    let requirementSummary: String?
    let warningText: String?
    let handoffURL: URL?
    let sourceURL: URL?
    let sourceTitle: String?
    let checkedAt: Date?
    let startsAt: Date?
    let endsAt: Date?
    let sortOrder: Int
    let isBaseRate: Bool

    var isActive: Bool {
        guard status == .published else { return false }

        let now = Date()
        if let startsAt, startsAt > now {
            return false
        }
        if let endsAt, endsAt < now {
            return false
        }
        return true
    }

    func matchesSelectedPrograms(_ selectedProgramIDs: Set<UUID>) -> Bool {
        guard !selectedProgramIDs.isEmpty, let programID = method.programID else { return true }
        return selectedProgramIDs.contains(programID)
    }
}

struct EarningCombination: Identifiable, Hashable {
    enum Status: String, Codable, Hashable {
        case draft
        case published
        case archived
    }

    let id: UUID
    let status: Status
    let title: String
    let totalValueLabel: String
    let summary: String
    let easierAlternativeLabel: String?
    let warningText: String?
    let primaryHandoffURL: URL?
    let lastVerifiedAt: Date?
    let sortOrder: Int
    let rateIDs: [UUID]
    let steps: [EarningCombinationStep]
}

struct EarningCombinationStep: Identifiable, Hashable {
    let id: UUID
    let text: String
    let sortOrder: Int
}

struct StoreSearchUseCase {
    func search(stores: [Store], query: String) -> [Store] {
        search(stores: stores, query: query, selectedProgramIDs: [])
    }

    func search(stores: [Store], query: String, selectedProgramIDs: Set<UUID>) -> [Store] {
        searchResults(stores: stores, query: query, selectedProgramIDs: selectedProgramIDs)
            .map(\.store)
    }

    func searchResults(stores: [Store], query: String, selectedProgramIDs: Set<UUID>) -> [StoreSearchResult] {
        let analysis = ShoppingIntentSearchUseCase().analyze(query: query)
        let matches = stores
            .filter(\.isPublished)
            .map { store in
                (
                    store: store,
                    match: StoreSearchMatch(
                        store: store,
                        query: query,
                        additionalTerms: analysis.searchTerms
                    )
                )
            }
            .filter { $0.match.score > 0 }

        let hasDirectMatch = matches.contains { $0.match.isDirectMatch }

        return matches
            .filter { !hasDirectMatch || $0.match.isDirectMatch }
            .sorted { first, second in
                if first.match.score != second.match.score {
                    return first.match.score > second.match.score
                }

                let firstHasSelectedEarning = first.store.hasSelectedProgramEarning(for: selectedProgramIDs)
                let secondHasSelectedEarning = second.store.hasSelectedProgramEarning(for: selectedProgramIDs)

                if firstHasSelectedEarning != secondHasSelectedEarning {
                    return firstHasSelectedEarning
                }

                let firstValue = StoreDiscoveryUseCase.rankingValue(for: first.store, selectedProgramIDs: selectedProgramIDs)
                let secondValue = StoreDiscoveryUseCase.rankingValue(for: second.store, selectedProgramIDs: selectedProgramIDs)

                if firstValue != secondValue {
                    return firstValue > secondValue
                }

                return first.store.name.localizedCompare(second.store.name) == .orderedAscending
            }
            .map { match in
                StoreSearchResult(
                    store: match.store,
                    intentExplanation: analysis.explanation(for: match.store)
                )
            }
    }
}

struct StoreSearchResult: Identifiable, Hashable {
    let store: Store
    let intentExplanation: String?

    var id: UUID {
        store.id
    }
}

struct ShoppingIntentSearchUseCase {
    func analyze(query: String) -> ShoppingIntentAnalysis {
        let normalizedQuery = StoreSearchNormalizer.normalize(query)
        guard !normalizedQuery.isEmpty else {
            return ShoppingIntentAnalysis(searchTerms: [], matchedIntents: [])
        }

        let queryTerms = StoreSearchNormalizer.normalizedTokens(from: [normalizedQuery])
        let hasBuyingContext = queryTerms.contains { Self.buyingContextTerms.contains($0) }

        let matchedIntents = Self.intentRules.filter { rule in
            rule.triggers.contains { trigger in
                let normalizedTrigger = StoreSearchNormalizer.normalize(trigger)
                guard queryTerms.contains(normalizedTrigger) else { return false }
                return hasBuyingContext || Self.standaloneProductTriggers.contains(normalizedTrigger)
            }
        }

        let searchTerms = matchedIntents.flatMap { $0.searchTerms }
        return ShoppingIntentAnalysis(
            searchTerms: Array(Set(searchTerms)),
            matchedIntents: matchedIntents
        )
    }

    private static let buyingContextTerms: Set<String> = [
        "bestille",
        "billig",
        "handle",
        "kjøp",
        "kjøpe",
        "kjope",
        "ny",
        "nye",
        "skal",
        "til",
        "trenger",
        "uka",
        "uken"
    ]

    private static let standaloneProductTriggers: Set<String> = [
        "android",
        "barneklær",
        "barneklaer",
        "dagligvare",
        "dagligvarer",
        "dagslinser",
        "flybilletter",
        "hundemat",
        "iphone",
        "jakke",
        "kolonial",
        "kontaktlinser",
        "linser",
        "lydbok",
        "lydbøker",
        "lydboker",
        "macbook",
        "mat",
        "middag",
        "maanedslinser",
        "månedslinser",
        "sminke",
        "vaskemaskin"
    ]

    private static let intentRules: [ShoppingIntentRule] = [
        ShoppingIntentRule(
            label: "Matcher elektronikk og mobil",
            triggers: ["iphone", "android", "mobil", "telefon", "smarttelefon"],
            searchTerms: ["elektronikk", "mobil", "telefon"]
        ),
        ShoppingIntentRule(
            label: "Matcher elektronikk og data",
            triggers: ["laptop", "pc", "mac", "macbook", "datamaskin", "gaming", "skjerm"],
            searchTerms: ["elektronikk", "data", "pc", "laptop", "datamaskin", "gaming"]
        ),
        ShoppingIntentRule(
            label: "Matcher reise og overnatting",
            triggers: ["hotell", "overnatting", "weekend", "storbyferie"],
            searchTerms: ["reise", "hotell", "overnatting"]
        ),
        ShoppingIntentRule(
            label: "Matcher reise og fly",
            triggers: ["fly", "flybilletter", "reise", "ferie"],
            searchTerms: ["reise", "fly", "flybilletter"]
        ),
        ShoppingIntentRule(
            label: "Matcher dagligvarer",
            triggers: ["mat", "middag", "dagligvare", "dagligvarer", "kolonial"],
            searchTerms: ["dagligvare", "dagligvarer", "mat", "kolonial"]
        ),
        ShoppingIntentRule(
            label: "Matcher klær og sko",
            triggers: ["klær", "klaer", "sko", "jakke", "bukse", "mote", "barneklær", "barneklaer"],
            searchTerms: ["klær", "klaer", "sko", "mote"]
        ),
        ShoppingIntentRule(
            label: "Matcher kontaktlinser og optikk",
            triggers: ["kontaktlinser", "linser", "dagslinser", "månedslinser", "maanedslinser"],
            searchTerms: ["kontaktlinser", "linser", "optikk"]
        ),
        ShoppingIntentRule(
            label: "Matcher gaver og opplevelser",
            triggers: ["gave", "gaver", "julegave", "julegaver", "opplevelse", "opplevelser"],
            searchTerms: ["gaver", "gave", "opplevelser", "shopping"]
        ),
        ShoppingIntentRule(
            label: "Matcher hus, hjem og hvitevarer",
            triggers: ["hvitevarer", "kjøleskap", "vaskemaskin", "møbler", "interiør", "hjem"],
            searchTerms: ["hjem", "hvitevarer", "møbler", "interiør", "elektronikk"]
        ),
        ShoppingIntentRule(
            label: "Matcher dyr og kjæledyr",
            triggers: ["hundemat", "kattemat", "dyremat", "kjæledyr", "kjaeledyr"],
            searchTerms: ["dyr", "kjæledyr", "kjaeledyr"]
        ),
        ShoppingIntentRule(
            label: "Matcher helse og skjønnhet",
            triggers: ["sminke", "makeup", "hudpleie", "parfyme", "skjønnhet", "skjonnhet"],
            searchTerms: ["helse", "skjønnhet", "skjonnhet"]
        ),
        ShoppingIntentRule(
            label: "Matcher barn og familie",
            triggers: ["barneklær", "barneklaer", "babyutstyr", "barneutstyr", "leker"],
            searchTerms: ["barn", "familie"]
        ),
        ShoppingIntentRule(
            label: "Matcher bøker og abonnement",
            triggers: ["lydbok", "lydbøker", "lydboker", "ebok", "ebøker", "eboker"],
            searchTerms: ["abonnement", "bøker", "boker", "medier"]
        ),
        ShoppingIntentRule(
            label: "Matcher bil og drivstoff",
            triggers: ["drivstoff", "bensin", "diesel", "lading", "bil"],
            searchTerms: ["drivstoff", "bensin", "diesel", "lading"]
        )
    ]
}

struct ShoppingIntentAnalysis: Hashable {
    let searchTerms: [String]
    let matchedIntents: [ShoppingIntentRule]

    var summary: String? {
        matchedIntents.first?.label
    }

    func explanation(for store: Store) -> String? {
        guard let matchedIntent = matchedIntents.first(where: { $0.matches(store: store) }) else {
            return nil
        }

        return matchedIntent.label
    }
}

struct ShoppingIntentRule: Hashable {
    let label: String
    let triggers: [String]
    let searchTerms: [String]

    func matches(store: Store) -> Bool {
        let fields = StoreSearchFields(store: store)
        let storeTerms = Set(fields.allValues)
        let normalizedTerms = StoreSearchNormalizer.normalizedTokens(from: searchTerms)
        return normalizedTerms.contains { storeTerms.contains($0) }
    }
}

struct StoreDiscoveryUseCase {
    func homeShortcutStores(from stores: [Store]) -> [Store] {
        homeShortcutStores(from: stores, selectedProgramIDs: [])
    }

    func homeShortcutStores(from stores: [Store], selectedProgramIDs: Set<UUID>) -> [Store] {
        storesWithEarning(from: stores)
            .sorted { compareHomeShortcutStores($0, $1, selectedProgramIDs: selectedProgramIDs) }
    }

    func storesWithEarning(from stores: [Store]) -> [Store] {
        storesWithEarning(from: stores, selectedProgramIDs: [])
    }

    func storesWithEarning(from stores: [Store], selectedProgramIDs: Set<UUID>) -> [Store] {
        rankedStores(from: stores, selectedProgramIDs: selectedProgramIDs)
            .filter(\.isPublished)
            .filter(\.hasVerifiedEarning)
    }

    func rankedStores(from stores: [Store]) -> [Store] {
        rankedStores(from: stores, selectedProgramIDs: [])
    }

    func rankedStores(from stores: [Store], selectedProgramIDs: Set<UUID>) -> [Store] {
        stores
            .filter(\.isPublished)
            .sorted { compareStores($0, $1, selectedProgramIDs: selectedProgramIDs) }
    }

    private func compareStores(_ first: Store, _ second: Store) -> Bool {
        compareStores(first, second, selectedProgramIDs: [])
    }

    private func compareStores(_ first: Store, _ second: Store, selectedProgramIDs: Set<UUID>) -> Bool {
        let firstHasSelectedEarning = first.hasSelectedProgramEarning(for: selectedProgramIDs)
        let secondHasSelectedEarning = second.hasSelectedProgramEarning(for: selectedProgramIDs)

        if firstHasSelectedEarning != secondHasSelectedEarning {
            return firstHasSelectedEarning
        }

        let firstHasEarning = first.hasVerifiedEarning
        let secondHasEarning = second.hasVerifiedEarning

        if firstHasEarning != secondHasEarning {
            return firstHasEarning
        }

        let firstValue = StoreDiscoveryUseCase.rankingValue(for: first, selectedProgramIDs: selectedProgramIDs)
        let secondValue = StoreDiscoveryUseCase.rankingValue(for: second, selectedProgramIDs: selectedProgramIDs)

        if firstValue != secondValue {
            return firstValue > secondValue
        }

        return first.name.localizedCompare(second.name) == .orderedAscending
    }

    private func compareHomeShortcutStores(_ first: Store, _ second: Store) -> Bool {
        compareHomeShortcutStores(first, second, selectedProgramIDs: [])
    }

    private func compareHomeShortcutStores(_ first: Store, _ second: Store, selectedProgramIDs: Set<UUID>) -> Bool {
        let firstHasSelectedEarning = first.hasSelectedProgramEarning(for: selectedProgramIDs)
        let secondHasSelectedEarning = second.hasSelectedProgramEarning(for: selectedProgramIDs)

        if firstHasSelectedEarning != secondHasSelectedEarning {
            return firstHasSelectedEarning
        }

        let firstHasCurrentEarning = hasCurrentEarning(for: first, selectedProgramIDs: selectedProgramIDs)
        let secondHasCurrentEarning = hasCurrentEarning(for: second, selectedProgramIDs: selectedProgramIDs)

        if firstHasCurrentEarning != secondHasCurrentEarning {
            return firstHasCurrentEarning
        }

        let firstCategoryPriority = homeCategoryPriority(for: first)
        let secondCategoryPriority = homeCategoryPriority(for: second)

        if firstCategoryPriority != secondCategoryPriority {
            return firstCategoryPriority > secondCategoryPriority
        }

        let firstHasBestCombination = first.bestCombination(for: selectedProgramIDs) != nil
        let secondHasBestCombination = second.bestCombination(for: selectedProgramIDs) != nil

        if firstHasBestCombination != secondHasBestCombination {
            return firstHasBestCombination
        }

        let firstValue = StoreDiscoveryUseCase.rankingValue(for: first, selectedProgramIDs: selectedProgramIDs)
        let secondValue = StoreDiscoveryUseCase.rankingValue(for: second, selectedProgramIDs: selectedProgramIDs)

        if firstValue != secondValue {
            return firstValue > secondValue
        }

        return first.name.localizedCompare(second.name) == .orderedAscending
    }

    private func hasCurrentEarning(for store: Store, selectedProgramIDs: Set<UUID>) -> Bool {
        guard !selectedProgramIDs.isEmpty else {
            return !store.activePromotions.isEmpty || store.earningRates.contains { $0.isActive }
        }

        let rates = store.earningRates.filter { $0.matchesSelectedPrograms(selectedProgramIDs) }
        let hasSelectedPromotion = rates.contains { !$0.isBaseRate && $0.isActive }
        let hasSelectedRate = rates.contains(where: \.isActive)
        return hasSelectedPromotion || hasSelectedRate
    }

    private func hasCurrentEarning(for store: Store) -> Bool {
        !store.activePromotions.isEmpty || store.earningRates.contains { $0.isActive }
    }

    private func homeCategoryPriority(for store: Store) -> Int {
        switch store.category?.slug {
        case "dagligvare":
            return 30
        case "shopping":
            return 20
        case "reise":
            return 10
        default:
            return 0
        }
    }

    static func rankingValue(for store: Store) -> Double {
        rankingValue(for: store, selectedProgramIDs: [])
    }

    static func rankingValue(for store: Store, selectedProgramIDs: Set<UUID>) -> Double {
        guard let label = store.bestCombination(for: selectedProgramIDs)?.totalValueLabel else { return 0 }
        let normalized = label.replacingOccurrences(of: ",", with: ".")
        let pattern = #"\d+(\.\d+)?"#

        guard
            let range = normalized.range(of: pattern, options: .regularExpression),
            let value = Double(normalized[range])
        else {
            return 0
        }

        return value
    }
}

private extension Store {
    var hasVerifiedEarning: Bool {
        bestCombination != nil || earningRates.contains { $0.isActive }
    }
}

private struct StoreSearchMatch {
    let score: Int
    let isDirectMatch: Bool

    init(store: Store, query: String) {
        self.init(store: store, query: query, additionalTerms: [])
    }

    init(store: Store, query: String, additionalTerms: [String]) {
        let normalizedQuery = StoreSearchNormalizer.normalize(query)
        guard !normalizedQuery.isEmpty else {
            score = 1
            isDirectMatch = false
            return
        }

        let fields = StoreSearchFields(store: store)
        let directTerms = StoreSearchNormalizer.expandedTerms(from: normalizedQuery)
        let directTermSet = Set(directTerms)
        let fallbackTerms = Array(Set(
            additionalTerms.flatMap { StoreSearchNormalizer.expandedTerms(from: $0) }
        ).subtracting(directTermSet))

        let directScore = max(
            StoreSearchMatch.score(query: normalizedQuery, terms: directTerms, in: fields.names, weight: 100),
            StoreSearchMatch.score(query: normalizedQuery, terms: directTerms, in: fields.categories, weight: 70),
            StoreSearchMatch.score(query: normalizedQuery, terms: directTerms, in: fields.keywords, weight: 90)
        )
        let fallbackScore = max(
            StoreSearchMatch.score(query: "", terms: fallbackTerms, in: fields.names, weight: 40),
            StoreSearchMatch.score(query: "", terms: fallbackTerms, in: fields.categories, weight: 30),
            StoreSearchMatch.score(query: "", terms: fallbackTerms, in: fields.keywords, weight: 35)
        )
        score = max(directScore, fallbackScore)
        isDirectMatch = directScore > 0
    }

    private static func score(query: String, terms: [String], in values: [String], weight: Int) -> Int {
        var bestScore = 0

        for value in values {
            if !query.isEmpty, value == query {
                bestScore = max(bestScore, weight + 40)
            } else if !query.isEmpty, value.hasPrefix(query) {
                bestScore = max(bestScore, weight + 25)
            } else if !query.isEmpty, value.contains(query) {
                bestScore = max(bestScore, weight + 15)
            }

            for term in terms where !term.isEmpty && term != query {
                if value == term {
                    bestScore = max(bestScore, weight + 20)
                } else if value.hasPrefix(term) {
                    bestScore = max(bestScore, weight + 12)
                } else if value.contains(term) {
                    bestScore = max(bestScore, weight + 8)
                }
            }

            if query.count >= 4, StoreSearchNormalizer.editDistance(query, value) <= 1 {
                bestScore = max(bestScore, weight + 5)
            }
        }

        return bestScore
    }
}

private struct StoreSearchFields {
    let names: [String]
    let categories: [String]
    let keywords: [String]

    var allValues: [String] {
        names + categories + keywords
    }

    init(store: Store) {
        names = StoreSearchNormalizer.normalizedTokens(from: [store.name, store.slug])
        categories = StoreSearchNormalizer.normalizedTokens(from: [store.category?.name, store.category?.slug])
        keywords = StoreSearchNormalizer.normalizedTokens(from: store.searchKeywords)
    }
}

private enum StoreSearchNormalizer {
    private static let synonyms: [String: [String]] = [
        "data": ["pc", "laptop", "mac", "datamaskin"],
        "datamaskin": ["data", "pc", "laptop", "mac"],
        "dagligvare": ["mat", "dagligvarer", "kolonial"],
        "dagligvarer": ["dagligvare", "mat", "kolonial"],
        "elektronikk": ["mobil", "telefon", "tv", "pc", "data", "gaming"],
        "klær": ["klaer", "sko", "mote"],
        "klaer": ["klær", "sko", "mote"],
        "laptop": ["pc", "data", "datamaskin"],
        "mat": ["dagligvare", "dagligvarer", "kolonial"],
        "mobil": ["telefon"],
        "pc": ["data", "datamaskin", "laptop", "gaming"],
        "sko": ["klær", "klaer", "mote"],
        "telefon": ["mobil"],
        "tv": ["elektronikk"]
    ]

    static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "nb_NO"))
            .localizedLowercase
    }

    static func normalizedTokens(from values: [String?]) -> [String] {
        values
            .compactMap { $0 }
            .flatMap { normalizedTokens(from: $0) }
    }

    static func normalizedTokens(from values: [String]) -> [String] {
        values.flatMap { normalizedTokens(from: $0) }
    }

    static func expandedTerms(from query: String) -> [String] {
        let terms = normalizedTokens(from: query)
        return Array(Set(terms + terms.flatMap { synonyms[$0] ?? [] }))
    }

    static func editDistance(_ first: String, _ second: String) -> Int {
        let firstCharacters = Array(first)
        let secondCharacters = Array(second)

        guard abs(firstCharacters.count - secondCharacters.count) <= 1 else {
            return 2
        }

        if firstCharacters == secondCharacters {
            return 0
        }

        var previousRow = Array(0...secondCharacters.count)
        for (firstIndex, firstCharacter) in firstCharacters.enumerated() {
            var currentRow = [firstIndex + 1]

            for (secondIndex, secondCharacter) in secondCharacters.enumerated() {
                let insertion = currentRow[secondIndex] + 1
                let deletion = previousRow[secondIndex + 1] + 1
                let substitution = previousRow[secondIndex] + (firstCharacter == secondCharacter ? 0 : 1)
                currentRow.append(min(insertion, deletion, substitution))
            }

            previousRow = currentRow
        }

        return previousRow[secondCharacters.count]
    }

    private static func normalizedTokens(from value: String) -> [String] {
        let normalizedValue = normalize(value)
        let words = normalizedValue
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)

        return Array(Set([normalizedValue] + words))
            .filter { !$0.isEmpty }
    }
}
