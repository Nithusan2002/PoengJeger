import Foundation
import Observation

@MainActor
@Observable
final class FeedViewModel {
    var isSearchVisible = false
    var searchText = ""
    var selectedSort: FeedSort = .expiringFirst
    var selectedCategoryID: UUID?
    var showsAllPrograms = false
    var isProgramSheetPresented = false

    func campaigns(from campaigns: [Campaign], selectedProgramIDs: Set<UUID>) -> [Campaign] {
        makeFeed(
            from: campaigns,
            selectedProgramIDs: selectedProgramIDs,
            selectedCategoryID: selectedCategoryID,
            searchText: searchText
        )
    }

    func activeCampaigns(from campaigns: [Campaign], selectedProgramIDs: Set<UUID>) -> [Campaign] {
        makeFeed(
            from: campaigns,
            selectedProgramIDs: selectedProgramIDs,
            selectedCategoryID: nil,
            searchText: ""
        )
    }

    func sections(from campaigns: [Campaign], selectedProgramIDs: Set<UUID>) -> [FeedSectionModel] {
        FeedSectionModel.makeSections(
            from: self.campaigns(from: campaigns, selectedProgramIDs: selectedProgramIDs)
        )
    }

    func priorityStats(from campaigns: [Campaign], selectedProgramIDs: Set<UUID>) -> FeedPriorityStats {
        FeedPriorityStats(campaigns: activeCampaigns(from: campaigns, selectedProgramIDs: selectedProgramIDs))
    }

    func categories(from campaigns: [Campaign]) -> [CampaignCategory] {
        Dictionary(grouping: campaigns.compactMap(\.category), by: \.id)
            .compactMap(\.value.first)
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func programs(for campaign: Campaign, from programs: [BonusProgram]) -> [BonusProgram] {
        let programsByID = Dictionary(uniqueKeysWithValues: programs.map { ($0.id, $0) })
        return campaign.linkedProgramIDs.compactMap { programsByID[$0] }
    }

    func accessibilityLabel(for campaign: Campaign, programs: [BonusProgram]) -> String {
        let expiry = FeedDateHelper.expiryLabel(campaign.endDate).text
        let programNames = self.programs(for: campaign, from: programs).map(\.name).joined(separator: ", ")
        return "\(campaign.feedHeadline). \(campaign.feedReason). \(expiry). \(programNames)."
    }

    func isLoadingInitialData(loadState: AppEnvironment.LoadState, campaigns: [Campaign]) -> Bool {
        if case .loading = loadState {
            return campaigns.isEmpty
        }
        return false
    }

    func toggleSearch() -> Bool {
        isSearchVisible.toggle()
        if !isSearchVisible {
            searchText = ""
        }
        return isSearchVisible
    }

    func trackSortChanged(in environment: AppEnvironment) {
        environment.track(.init(
            name: "filter_applied",
            surface: "feed",
            properties: ["filter_type": "sort", "selected_count": "1"]
        ))
    }

    func trackCategoryChanged(in environment: AppEnvironment) {
        environment.track(.init(
            name: "filter_applied",
            surface: "feed",
            entityType: selectedCategoryID == nil ? nil : "category",
            entityID: selectedCategoryID,
            properties: [
                "filter_type": "category",
                "selected_count": selectedCategoryID == nil ? "0" : "1"
            ]
        ))
    }

    func trackProgramScopeChanged(selectedProgramCount: Int, in environment: AppEnvironment) {
        environment.track(.init(
            name: "filter_applied",
            surface: "feed",
            properties: [
                "filter_type": "program_scope",
                "selected_count": showsAllPrograms ? "all" : "\(selectedProgramCount)"
            ]
        ))
    }

    private func makeFeed(
        from campaigns: [Campaign],
        selectedProgramIDs: Set<UUID>,
        selectedCategoryID: UUID?,
        searchText: String
    ) -> [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: campaigns,
            selectedProgramIDs: selectedProgramIDs,
            showsAllPrograms: showsAllPrograms,
            selectedCategoryID: selectedCategoryID,
            searchText: searchText,
            sort: selectedSort
        )
    }
}
