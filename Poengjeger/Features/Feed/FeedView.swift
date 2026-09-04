import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchVisible = false
    @State private var searchText = ""
    @State private var selectedSort: FeedSort = .expiringFirst
    @State private var selectedCategoryID: UUID?
    @State private var showsAllPrograms = false
    @State private var isProgramSheetPresented = false

    private var campaigns: [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
            showsAllPrograms: showsAllPrograms,
            selectedCategoryID: selectedCategoryID,
            searchText: searchText,
            sort: selectedSort
        )
    }

    private var feedSections: [FeedSectionModel] {
        FeedSectionModel.makeSections(from: campaigns)
    }

    private var priorityStats: FeedPriorityStats {
        FeedPriorityStats(campaigns: activeCampaignsWithoutSearch)
    }

    private var activeCampaignCount: Int {
        activeCampaignsWithoutSearch.count
    }

    private var activeCampaignsWithoutSearch: [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
            showsAllPrograms: showsAllPrograms,
            selectedCategoryID: nil,
            searchText: "",
            sort: selectedSort
        )
    }

    private var categories: [CampaignCategory] {
        Dictionary(
            grouping: environment.firstPhaseCampaigns.compactMap(\.category),
            by: \.id
        )
        .compactMap(\.value.first)
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var programsByID: [UUID: BonusProgram] {
        Dictionary(uniqueKeysWithValues: environment.firstPhasePrograms.map { ($0.id, $0) })
    }

    private var hasSelectedPrograms: Bool {
        !environment.selectedFirstPhaseProgramIDs.isEmpty
    }

    var body: some View {
        @Bindable var environment = environment

        List {
            if let dataSource = environment.dataSource, dataSource.isFallback {
                FeedStatusBanner(text: dataSource.label)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
            }

            if isLoadingInitialData {
                ForEach(0..<6, id: \.self) { _ in
                    FeedPlaceholderRow()
                        .redacted(reason: .placeholder)
                }
            } else {
                ForEach(feedSections) { section in
                    Section {
                        ForEach(section.campaigns) { campaign in
                            NavigationLink(value: campaign) {
                                FeedCampaignRow(
                                    campaign: campaign,
                                    programs: programs(for: campaign)
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
                            .listRowBackground(PoengjegerTheme.background)
                            .accessibilityLabel(accessibilityLabel(for: campaign))
                        }
                    } header: {
                        FeedSectionHeader(title: section.title, detail: section.detail)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PoengjegerTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: 76)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            FeedControlHeader(
                campaignCount: activeCampaignCount,
                priorityStats: priorityStats,
                showsAllPrograms: showsAllPrograms || !hasSelectedPrograms,
                isSearchVisible: isSearchVisible,
                searchText: $searchText,
                selectedSort: $selectedSort,
                selectedCategoryID: $selectedCategoryID,
                categories: categories,
                hasSelectedPrograms: hasSelectedPrograms,
                onToggleSearch: toggleSearch,
                onOpenProgramFilter: { isProgramSheetPresented = true },
                onToggleShowsAllPrograms: { showsAllPrograms.toggle() },
                isSearchFocused: $isSearchFocused
            )
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign, entryPoint: "feed")
        }
        .refreshable {
            await environment.refresh()
        }
        .overlay {
            if case let .failed(message) = environment.loadState, campaigns.isEmpty {
                ContentUnavailableView(
                    "Kunne ikke hente kampanjer",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
            } else if !isLoadingInitialData && campaigns.isEmpty {
                ContentUnavailableView(
                    "Ingen kampanjer matcher filteret ditt akkurat nå.",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
        }
        .sheet(isPresented: $isProgramSheetPresented) {
            ProgramFilterSheet(
                programs: environment.firstPhasePrograms,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )
        }
        .onChange(of: selectedSort) {
            environment.track(.init(
                name: "filter_applied",
                surface: "feed",
                properties: [
                    "filter_type": "sort",
                    "selected_count": "1"
                ]
            ))
        }
        .onChange(of: selectedCategoryID) {
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
        .onChange(of: showsAllPrograms) {
            environment.track(.init(
                name: "filter_applied",
                surface: "feed",
                properties: [
                    "filter_type": "program_scope",
                    "selected_count": showsAllPrograms ? "all" : "\(environment.selectedFirstPhaseProgramIDs.count)"
                ]
            ))
        }
    }

    private var isLoadingInitialData: Bool {
        if case .loading = environment.loadState {
            return environment.campaigns.isEmpty
        }

        return false
    }

    private func toggleSearch() {
        isSearchVisible.toggle()

        if isSearchVisible {
            isSearchFocused = true
        } else {
            searchText = ""
            isSearchFocused = false
        }
    }

    private func programs(for campaign: Campaign) -> [BonusProgram] {
        campaign.linkedProgramIDs.compactMap { programsByID[$0] }
    }

    private func accessibilityLabel(for campaign: Campaign) -> String {
        let expiry = FeedDateHelper.expiryLabel(campaign.endDate).text
        let programNames = programs(for: campaign).map(\.name).joined(separator: ", ")
        return "\(campaign.feedHeadline). \(campaign.feedReason). \(expiry). \(programNames)."
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.mock())
    }
}
