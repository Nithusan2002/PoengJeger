import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var searchText = ""
    private var hasTrackedCurrentSearch = false

    var isSearching: Bool {
        !trimmedSearchText.isEmpty
    }

    var searchResultTitle: String {
        if let summary = shoppingIntent.summary {
            return summary
                .replacingOccurrences(of: "Matcher ", with: "", options: [.anchored])
                .capitalized
        }

        return "Treff for «\(trimmedSearchText)»"
    }

    func matchingStoreResults(
        stores: [Store],
        selectedProgramIDs: Set<UUID>
    ) -> [StoreSearchResult] {
        StoreSearchUseCase().searchResults(
            stores: stores,
            query: searchText,
            selectedProgramIDs: selectedProgramIDs
        )
    }

    func trackSearchStartedIfNeeded(
        using track: (ProductAnalyticsEvent) -> Void
    ) {
        guard isSearching else {
            hasTrackedCurrentSearch = false
            return
        }

        guard !hasTrackedCurrentSearch else { return }
        hasTrackedCurrentSearch = true
        track(.init(
            name: "store_search_started",
            surface: "store_search",
            properties: ["entry_point": "home"]
        ))
    }

    func selectQuickSearch(
        title: String,
        using track: (ProductAnalyticsEvent) -> Void
    ) {
        track(.init(
            name: "store_quick_search_selected",
            surface: "store_search",
            properties: ["query": title.lowercased()]
        ))
        searchText = title
    }

    func trackStoreOpen(
        _ store: Store,
        entryPoint: String,
        rank: Int,
        selectedProgramIDs: Set<UUID>,
        using track: (ProductAnalyticsEvent) -> Void
    ) {
        let bestCombination = store.bestCombination(for: selectedProgramIDs)
        var properties = [
            "entry_point": entryPoint,
            "rank": "\(rank)",
            "has_active_campaign": store.activePromotions.isEmpty ? "false" : "true",
            "has_best_combination": bestCombination == nil ? "false" : "true"
        ]

        if let categoryID = store.category?.id {
            properties["category_id"] = categoryID.uuidString
        }

        track(.init(
            name: "store_search_result_opened",
            surface: "store_search",
            entityType: "store",
            entityID: store.id,
            properties: properties
        ))
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shoppingIntent: ShoppingIntentAnalysis {
        ShoppingIntentSearchUseCase().analyze(query: searchText)
    }
}
