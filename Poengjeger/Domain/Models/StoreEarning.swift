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
        combinations
            .filter { $0.status == .published }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
    }

    func matches(_ query: String) -> Bool {
        StoreSearchMatch(store: self, query: query).score > 0
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
        stores
            .filter(\.isPublished)
            .map { store in
                (store: store, match: StoreSearchMatch(store: store, query: query))
            }
            .filter { $0.match.score > 0 }
            .sorted { first, second in
                if first.match.score != second.match.score {
                    return first.match.score > second.match.score
                }

                let firstValue = StoreDiscoveryUseCase.rankingValue(for: first.store)
                let secondValue = StoreDiscoveryUseCase.rankingValue(for: second.store)

                if firstValue != secondValue {
                    return firstValue > secondValue
                }

                return first.store.name.localizedCompare(second.store.name) == .orderedAscending
            }
            .map(\.store)
    }
}

struct StoreDiscoveryUseCase {
    func homeShortcutStores(from stores: [Store]) -> [Store] {
        storesWithEarning(from: stores)
            .sorted(by: compareHomeShortcutStores)
    }

    func storesWithEarning(from stores: [Store]) -> [Store] {
        rankedStores(from: stores)
            .filter(\.isPublished)
            .filter(\.hasVerifiedEarning)
    }

    func rankedStores(from stores: [Store]) -> [Store] {
        stores
            .filter(\.isPublished)
            .sorted(by: compareStores)
    }

    private func compareStores(_ first: Store, _ second: Store) -> Bool {
        let firstHasEarning = first.hasVerifiedEarning
        let secondHasEarning = second.hasVerifiedEarning

        if firstHasEarning != secondHasEarning {
            return firstHasEarning
        }

        let firstValue = StoreDiscoveryUseCase.rankingValue(for: first)
        let secondValue = StoreDiscoveryUseCase.rankingValue(for: second)

        if firstValue != secondValue {
            return firstValue > secondValue
        }

        return first.name.localizedCompare(second.name) == .orderedAscending
    }

    private func compareHomeShortcutStores(_ first: Store, _ second: Store) -> Bool {
        let firstHasActivePromotion = !first.activePromotions.isEmpty
        let secondHasActivePromotion = !second.activePromotions.isEmpty

        if firstHasActivePromotion != secondHasActivePromotion {
            return firstHasActivePromotion
        }

        let firstCategoryPriority = homeCategoryPriority(for: first)
        let secondCategoryPriority = homeCategoryPriority(for: second)

        if firstCategoryPriority != secondCategoryPriority {
            return firstCategoryPriority > secondCategoryPriority
        }

        let firstHasBestCombination = first.bestCombination != nil
        let secondHasBestCombination = second.bestCombination != nil

        if firstHasBestCombination != secondHasBestCombination {
            return firstHasBestCombination
        }

        let firstValue = StoreDiscoveryUseCase.rankingValue(for: first)
        let secondValue = StoreDiscoveryUseCase.rankingValue(for: second)

        if firstValue != secondValue {
            return firstValue > secondValue
        }

        return first.name.localizedCompare(second.name) == .orderedAscending
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
        guard let label = store.bestCombination?.totalValueLabel else { return 0 }
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

    init(store: Store, query: String) {
        let normalizedQuery = StoreSearchNormalizer.normalize(query)
        guard !normalizedQuery.isEmpty else {
            score = 1
            return
        }

        let fields = StoreSearchFields(store: store)
        let expandedQueryTerms = StoreSearchNormalizer.expandedTerms(from: normalizedQuery)

        score = max(
            StoreSearchMatch.score(query: normalizedQuery, terms: expandedQueryTerms, in: fields.names, weight: 100),
            StoreSearchMatch.score(query: normalizedQuery, terms: expandedQueryTerms, in: fields.categories, weight: 70),
            StoreSearchMatch.score(query: normalizedQuery, terms: expandedQueryTerms, in: fields.keywords, weight: 55)
        )
    }

    private static func score(query: String, terms: [String], in values: [String], weight: Int) -> Int {
        var bestScore = 0

        for value in values {
            if value == query {
                bestScore = max(bestScore, weight + 40)
            } else if value.hasPrefix(query) {
                bestScore = max(bestScore, weight + 25)
            } else if value.contains(query) {
                bestScore = max(bestScore, weight + 15)
            }

            for term in terms where term != query {
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
