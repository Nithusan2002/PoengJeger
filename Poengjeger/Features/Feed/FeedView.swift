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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                FeedHeader(
                    campaignCount: campaigns.count,
                    selectedProgramCount: environment.userSession.selectedProgramIDs.count
                )

                if let dataSource = environment.dataSource, dataSource.isFallback {
                    FeedStatusBanner(text: dataSource.label)
                }

                ForEach(campaigns) { campaign in
                    NavigationLink(value: campaign) {
                        CampaignCardView(
                            campaign: campaign,
                            primaryProgramName: programName(for: campaign),
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
                    systemImage: "tag",
                    description: Text("Velg bonusprogrammer for å se relevante kampanjer med frister, vilkår og kildegrunnlag.")
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

private struct FeedHeader: View {
    let campaignCount: Int
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

        return "Aktive kampanjer fra \(selectedProgramCount) valgte bonusprogram\(selectedProgramCount == 1 ? "" : "mer")."
    }
}

private struct FeedStatusBanner: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .font(.footnote)
        .foregroundStyle(PoengjegerTheme.warning)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.warning.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct CampaignCardView: View {
    let campaign: Campaign
    let primaryProgramName: String?
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    TagRow(
                        primaryProgramName: primaryProgramName,
                        categoryName: campaign.category?.name,
                        isFeatured: campaign.isFeatured
                    )

                    Text(campaign.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(!campaign.editorialSummary.isEmpty ? campaign.editorialSummary : campaign.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let score = campaign.editorialScore {
                    ScoreBadge(score: score)
                }
            }

            Divider()

            HStack(alignment: .center, spacing: 10) {
                CampaignMetadataStrip(campaign: campaign)

                Spacer(minLength: 8)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.highlight)
                        .accessibilityLabel("Lagret som favoritt")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

private struct TagRow: View {
    let primaryProgramName: String?
    let categoryName: String?
    let isFeatured: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                tags
            }

            VStack(alignment: .leading, spacing: 6) {
                tags
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        if let primaryProgramName {
            TagView(title: primaryProgramName, tint: PoengjegerTheme.accent)
        }

        if let categoryName {
            TagView(title: categoryName, tint: .secondary)
        }

        if isFeatured {
            TagView(title: "Fremhevet", tint: PoengjegerTheme.highlight)
        }
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
        .background(PoengjegerTheme.accentSoft)
        .foregroundStyle(PoengjegerTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Poengjeger-score \(score) av 100")
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
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct CampaignMetadataStrip: View {
    let campaign: Campaign

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                labels
            }

            VStack(alignment: .leading, spacing: 8) {
                labels
            }
        }
    }

    @ViewBuilder
    private var labels: some View {
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
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
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
