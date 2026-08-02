import SwiftUI

struct FavoritesView: View {
    @Environment(AppEnvironment.self) private var environment

    private var favorites: [Campaign] {
        environment.campaignRepository.fetchFavorites(for: environment.userSession.favoriteCampaignIDs)
    }

    var body: some View {
        List(favorites) { campaign in
            NavigationLink(value: campaign) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(campaign.title)
                        .font(.headline)
                    Text(campaign.editorialSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Favoritter")
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
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
}
