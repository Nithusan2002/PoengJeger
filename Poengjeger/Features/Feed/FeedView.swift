import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedFilter: FeedFilter = .all

    private var campaigns: [Campaign] {
        FeedUseCase()
            .makeFeed(
                campaigns: environment.campaigns,
                selectedProgramIDs: environment.userSession.selectedProgramIDs,
                filter: selectedFilter
            )
    }

    private var unfilteredCampaigns: [Campaign] {
        FeedUseCase()
            .makeFeed(
                campaigns: environment.campaigns,
                selectedProgramIDs: environment.userSession.selectedProgramIDs
            )
    }

    private var unfilteredCampaignCount: Int {
        unfilteredCampaigns.count
    }

    private var programNamesByID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: environment.programs.map { ($0.id, $0.name) })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                FeedHeader(
                    campaignCount: campaigns.count,
                    unfilteredCampaignCount: unfilteredCampaignCount,
                    selectedFilter: selectedFilter,
                    selectedProgramCount: environment.userSession.selectedProgramIDs.count
                )

                if let dataSource = environment.dataSource, dataSource.isFallback {
                    FeedStatusBanner(text: dataSource.label)
                }

                FeedFilterPicker(selectedFilter: $selectedFilter)

                ForEach(campaigns) { campaign in
                    NavigationLink(value: campaign) {
                        CampaignCardView(
                            campaign: campaign,
                            primaryProgramName: primaryProgramName(for: campaign),
                            isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Aktive kampanjer")
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .refreshable {
            await environment.refresh()
        }
        .overlay {
            switch environment.loadState {
            case .loading where campaigns.isEmpty:
                ProgressView("Laster feed")
            case let .failed(message) where campaigns.isEmpty:
                ContentUnavailableView(
                    "Kunne ikke hente kampanjer",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
            case _ where campaigns.isEmpty && selectedFilter != .all:
                ContentUnavailableView(
                    "Ingen treff",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Prøv et annet filter eller juster bonusprogrammene dine.")
                )
            case _ where campaigns.isEmpty:
                ContentUnavailableView(
                    "Ingen kampanjer ennå",
                    systemImage: "tag",
                    description: Text("Velg bonusprogrammer for å se relevante kampanjer med frister, vilkår og kildegrunnlag.")
                )
            default:
                EmptyView()
            }
        }
    }

    private func primaryProgramName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return programNamesByID[primaryProgramID]
    }
}

private struct FeedHeader: View {
    let campaignCount: Int
    let unfilteredCampaignCount: Int
    let selectedFilter: FeedFilter
    let selectedProgramCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Prioritert for deg")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Text("\(campaignCount)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.accent)
                    .accessibilityLabel("\(campaignCount) aktive kampanjer")
            }

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }

    private var headerSubtitle: String {
        if selectedProgramCount == 0 {
            return "Velg bonusprogrammer for å gjøre feeden personlig."
        }

        if selectedFilter != .all {
            return "\(campaignCount) av \(unfilteredCampaignCount) relevante kampanjer vises med filteret \(selectedFilter.title.lowercased())."
        }

        return "Aktive kampanjer fra \(selectedProgramCount) valgte bonusprogram\(selectedProgramCount == 1 ? "" : "mer"), sortert etter redaksjonell vurdering."
    }
}

private struct FeedFilterPicker: View {
    @Binding var selectedFilter: FeedFilter

    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(FeedFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Filtrer kampanjer")
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.mock())
    }
}
