import SwiftUI

struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedScope: FavoriteScope = .stores

    private var favoriteCampaigns: [Campaign] {
        let firstPhaseProgramIDs = Set(environment.firstPhasePrograms.map(\.id))
        return environment.favoriteCampaigns.filter { campaign in
            campaign.linkedProgramIDs.contains { firstPhaseProgramIDs.contains($0) }
        }
    }

    private var favoriteStores: [Store] {
        environment.favoriteStores
    }

    private var programNamesByID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: environment.firstPhasePrograms.map { ($0.id, $0.name) })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                scopePicker

                switch selectedScope {
                case .stores:
                    storeFavorites
                case .campaigns:
                    campaignFavorites
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Lagret")
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var scopePicker: some View {
        Picker("Lagret innhold", selection: $selectedScope) {
            ForEach(FavoriteScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Velg lagret innhold")
    }

    @ViewBuilder
    private var storeFavorites: some View {
        if favoriteStores.isEmpty {
            ContentUnavailableView(
                "Ingen lagrede butikker",
                systemImage: "star",
                description: Text("Trykk på stjernen på en butikkside du vil sjekke igjen.")
            )
            .padding(.vertical, 40)
        } else {
            ForEach(favoriteStores) { store in
                NavigationLink(value: store) {
                    StoreResultRow(store: store)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var campaignFavorites: some View {
        if favoriteCampaigns.isEmpty {
            ContentUnavailableView(
                "Ingen lagrede kampanjer",
                systemImage: "star",
                description: Text("Trykk på stjernen på en kampanje du vil sjekke senere.")
            )
            .padding(.vertical, 40)
        } else {
            ForEach(favoriteCampaigns) { campaign in
                NavigationLink(value: campaign) {
                    CampaignCardView(
                        campaign: campaign,
                        primaryProgramName: programName(for: campaign),
                        isFavorite: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func programName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return programNamesByID[primaryProgramID]
    }
}

private enum FavoriteScope: String, CaseIterable, Identifiable {
    case stores
    case campaigns

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stores:
            return "Butikker"
        case .campaigns:
            return "Kampanjer"
        }
    }
}
