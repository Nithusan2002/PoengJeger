import SwiftUI

struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var environment

    private var favorites: [Campaign] {
        let firstPhaseProgramIDs = Set(environment.firstPhasePrograms.map(\.id))
        return environment.favoriteCampaigns.filter { campaign in
            campaign.linkedProgramIDs.contains { firstPhaseProgramIDs.contains($0) }
        }
    }

    private var programNamesByID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: environment.firstPhasePrograms.map { ($0.id, $0.name) })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(favorites) { campaign in
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
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Lagret")
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .refreshable {
            await environment.refresh()
        }
        .overlay {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "Ingen lagrede kampanjer",
                    systemImage: "star",
                    description: Text("Trykk på stjernen på kampanjer du vil sjekke senere.")
                )
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
