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
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.comfortable) {
                header

                scopePicker

                switch selectedScope {
                case .stores:
                    storeFavorites
                case .campaigns:
                    campaignFavorites
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.vertical, DesignTokens.Spacing.comfortable)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Lagret")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign, entryPoint: "favorites")
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Lagret")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Butikker og kampanjer du vil sjekke igjen.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scopePicker: some View {
        Picker("Lagret innhold", selection: $selectedScope) {
            ForEach(FavoriteScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .minimumTouchTarget()
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
            .padding(.vertical, DesignTokens.Spacing.spacious)
        } else {
            ForEach(favoriteStores) { store in
                NavigationLink(value: store) {
                    StoreResultRow(
                        store: store,
                        selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
                    )
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
            .padding(.vertical, DesignTokens.Spacing.spacious)
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
