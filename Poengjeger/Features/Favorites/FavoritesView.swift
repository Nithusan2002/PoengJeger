import SwiftUI

struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var environment

    private var favorites: [Campaign] {
        environment.favoriteCampaigns
    }

    var body: some View {
        List(favorites) { campaign in
            NavigationLink(value: campaign) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let programName = programName(for: campaign) {
                            Text(programName)
                                .font(.caption)
                                .foregroundStyle(PoengjegerTheme.accent)
                        }

                        if let categoryName = campaign.category?.name {
                            Text(categoryName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(campaign.title)
                        .font(.headline)
                    Text(!campaign.editorialSummary.isEmpty ? campaign.editorialSummary : campaign.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Sist kontrollert \(campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Favoritter")
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .refreshable {
            await environment.refresh()
        }
        .overlay {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "Ingen favoritter",
                    systemImage: "star",
                    description: Text("Lagrede kampanjer dukker opp her.")
                )
            }
        }
    }

    private func programName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return environment.programs.first(where: { $0.id == primaryProgramID })?.name
    }
}
