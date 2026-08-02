import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment

    private var campaigns: [Campaign] {
        FeedUseCase()
            .makeFeed(
                campaigns: environment.campaigns,
                selectedProgramIDs: environment.userSession.selectedProgramIDs
            )
    }

    var body: some View {
        List {
            if let dataSource = environment.dataSource, dataSource.isFallback {
                Section {
                    Label(dataSource.label, systemImage: "exclamationmark.bubble")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(campaigns) { campaign in
                NavigationLink(value: campaign) {
                    CampaignCardView(
                        campaign: campaign,
                        primaryProgramName: programName(for: campaign),
                        isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                    )
                }
            }
        }
        .navigationTitle("Aktive kampanjer")
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
            case _ where campaigns.isEmpty:
                ContentUnavailableView(
                    "Ingen kampanjer ennå",
                    systemImage: "tray",
                    description: Text("Velg flere bonusprogrammer eller legg inn redaksjonelt innhold i backend.")
                )
            default:
                EmptyView()
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

private struct CampaignCardView: View {
    let campaign: Campaign
    let primaryProgramName: String?
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let primaryProgramName {
                    TagView(title: primaryProgramName, tint: PoengjegerTheme.accent)
                }

                if let categoryName = campaign.category?.name {
                    TagView(title: categoryName, tint: .secondary)
                }

                if campaign.isFeatured {
                    TagView(title: "Fremhevet", tint: PoengjegerTheme.highlight)
                }
            }

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

            HStack(alignment: .center, spacing: 12) {
                MetadataLabel(
                    title: "Kontrollert",
                    value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "checkmark.seal"
                )

                if let endDate = campaign.endDate {
                    MetadataLabel(
                        title: "Utløper",
                        value: endDate.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "calendar"
                    )
                }

                if let firstSource = campaign.sources.first {
                    MetadataLabel(
                        title: "Kilde",
                        value: firstSource.sourceName,
                        systemImage: "link"
                    )
                }

                Spacer(minLength: 0)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(PoengjegerTheme.highlight)
                        .accessibilityLabel("Lagret som favoritt")
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

private struct MetadataLabel: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
        .labelStyle(.titleAndIcon)
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.mock())
    }
}
