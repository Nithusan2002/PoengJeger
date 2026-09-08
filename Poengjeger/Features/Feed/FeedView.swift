import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var viewModel = FeedViewModel()

    private var campaigns: [Campaign] {
        viewModel.campaigns(
            from: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var feedSections: [FeedSectionModel] {
        viewModel.sections(
            from: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var priorityStats: FeedPriorityStats {
        viewModel.priorityStats(
            from: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var activeCampaignCount: Int {
        activeCampaignsWithoutSearch.count
    }

    private var activeCampaignsWithoutSearch: [Campaign] {
        viewModel.activeCampaigns(
            from: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var categories: [CampaignCategory] {
        viewModel.categories(from: environment.firstPhaseCampaigns)
    }

    private var hasSelectedPrograms: Bool {
        !environment.selectedFirstPhaseProgramIDs.isEmpty
    }

    var body: some View {
        @Bindable var environment = environment
        @Bindable var viewModel = viewModel

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
                            .listRowBackground(DesignTokens.Colors.background)
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
        .background(DesignTokens.Colors.background)
        .safeAreaInset(edge: .bottom, spacing: DesignTokens.Spacing.none) {
            DesignTokens.Colors.clear
                .frame(height: 76)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: DesignTokens.Spacing.none) {
            FeedControlHeader(
                campaignCount: activeCampaignCount,
                priorityStats: priorityStats,
                showsAllPrograms: viewModel.showsAllPrograms || !hasSelectedPrograms,
                isSearchVisible: viewModel.isSearchVisible,
                searchText: $viewModel.searchText,
                selectedSort: $viewModel.selectedSort,
                selectedCategoryID: $viewModel.selectedCategoryID,
                categories: categories,
                hasSelectedPrograms: hasSelectedPrograms,
                onToggleSearch: toggleSearch,
                onOpenProgramFilter: { viewModel.isProgramSheetPresented = true },
                onToggleShowsAllPrograms: { viewModel.showsAllPrograms.toggle() },
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
        .sheet(isPresented: $viewModel.isProgramSheetPresented) {
            ProgramFilterSheet(
                programs: environment.firstPhasePrograms,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )
        }
        .onChange(of: viewModel.selectedSort) {
            viewModel.trackSortChanged(in: environment)
        }
        .onChange(of: viewModel.selectedCategoryID) {
            viewModel.trackCategoryChanged(in: environment)
        }
        .onChange(of: viewModel.showsAllPrograms) {
            viewModel.trackProgramScopeChanged(
                selectedProgramCount: environment.selectedFirstPhaseProgramIDs.count,
                in: environment
            )
        }
    }

    private var isLoadingInitialData: Bool {
        viewModel.isLoadingInitialData(loadState: environment.loadState, campaigns: environment.campaigns)
    }

    private func toggleSearch() {
        isSearchFocused = viewModel.toggleSearch()
    }

    private func programs(for campaign: Campaign) -> [BonusProgram] {
        viewModel.programs(for: campaign, from: environment.firstPhasePrograms)
    }

    private func accessibilityLabel(for campaign: Campaign) -> String {
        viewModel.accessibilityLabel(for: campaign, programs: environment.firstPhasePrograms)
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.mock())
    }
}
