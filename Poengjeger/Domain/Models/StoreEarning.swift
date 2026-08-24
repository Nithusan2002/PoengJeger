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
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        guard !normalizedQuery.isEmpty else { return true }

        let values = [name, slug, category?.name].compactMap { $0 } + searchKeywords
        return values.contains { $0.localizedLowercase.contains(normalizedQuery) }
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
            .filter { $0.matches(query) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}

struct StoreDiscoveryUseCase {
    func storesWithEarning(from stores: [Store]) -> [Store] {
        rankedStores(from: stores)
            .filter(\.isPublished)
            .filter { $0.bestCombination != nil || !$0.sortedEarningRates.isEmpty }
    }

    func rankedStores(from stores: [Store]) -> [Store] {
        stores
            .filter(\.isPublished)
            .sorted(by: compareStores)
    }

    private func compareStores(_ first: Store, _ second: Store) -> Bool {
        let firstHasEarning = first.bestCombination != nil || !first.sortedEarningRates.isEmpty
        let secondHasEarning = second.bestCombination != nil || !second.sortedEarningRates.isEmpty

        if firstHasEarning != secondHasEarning {
            return firstHasEarning
        }

        let firstValue = rankingValue(for: first)
        let secondValue = rankingValue(for: second)

        if firstValue != secondValue {
            return firstValue > secondValue
        }

        return first.name.localizedCompare(second.name) == .orderedAscending
    }

    private func rankingValue(for store: Store) -> Double {
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
