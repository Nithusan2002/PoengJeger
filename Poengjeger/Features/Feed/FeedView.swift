import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment

    private var campaigns: [Campaign] {
        FeedUseCase(repository: environment.campaignRepository)
            .makeFeed(selectedProgramIDs: environment.userSession.selectedProgramIDs)
    }

    var body: some View {
        List(campaigns) { campaign in
            NavigationLink(value: campaign) {
                CampaignCardView(
                    campaign: campaign,
                    isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                )
            }
        }
        .navigationTitle("Aktive kampanjer")
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .overlay {
            if campaigns.isEmpty {
                ContentUnavailableView(
                    "Ingen kampanjer ennå",
                    systemImage: "tray",
                    description: Text("Velg flere bonusprogrammer eller legg inn redaksjonelt innhold i backend.")
                )
            }
        }
    }
}

private struct CampaignCardView: View {
    let campaign: Campaign
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(campaign.title)
                        .font(.headline)

                    Text(campaign.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if let score = campaign.editorialScore {
                    ScoreBadge(score: score)
                }
            }

            if let endDate = campaign.endDate {
                Label(endDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let categoryName = campaign.category?.name {
                    TagView(title: categoryName)
                }

                if campaign.isFeatured {
                    TagView(title: "Fremhevet", tint: PoengjegerTheme.highlight)
                }

                Spacer()

                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(PoengjegerTheme.highlight)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ScoreBadge: View {
    let score: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)")
                .font(.headline)
                .bold()
            Text("score")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(PoengjegerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TagView: View {
    let title: String
    var tint: Color = PoengjegerTheme.accent

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.bootstrap())
    }
}
