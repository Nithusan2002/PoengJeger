import SwiftUI

struct FeedStatusBanner: View {
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

struct CampaignCardView: View {
    let campaign: Campaign
    let primaryProgramName: String?
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(campaign.cardAccent)
                .frame(width: 5)
                .accessibilityHidden(true)

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

                        Text(campaign.opportunitySignal)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(campaign.cardAccent)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(campaign.displaySummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    if campaign.editorialScore != nil {
                        EditorialTierBadge(label: campaign.editorialTierLabel, tint: campaign.cardAccent)
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
                .padding(.top, 1)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(campaign.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

struct TagRow: View {
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

struct EditorialTierBadge: View {
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .accessibilityHidden(true)
            Text(label)
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 84)
        .background(tint.opacity(0.13))
        .foregroundStyle(tint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Redaksjonell vurdering: \(label)")
    }
}

struct TagView: View {
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

extension Campaign {
    var isHighScore: Bool {
        (editorialScore ?? 0) >= 75
    }

    var isExpiringSoon: Bool {
        guard let endDate else { return false }
        let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
        return daysUntilEnd.map { $0 >= 0 && $0 <= 7 } == true
    }

    var cardAccent: Color {
        if isExpiringSoon {
            return PoengjegerTheme.highlight
        }

        if isHighScore {
            return PoengjegerTheme.editorialBlue
        }

        return PoengjegerTheme.accent
    }

    var cardSurface: Color {
        isExpiringSoon ? PoengjegerTheme.highlightSoft : PoengjegerTheme.elevatedSurface
    }

    var opportunitySignal: String {
        let valueText: String
        switch editorialScore {
        case let score? where score >= 80:
            valueText = "Sterk mulighet"
        case let score? where score >= 65:
            valueText = "Relevant"
        case .some:
            valueText = "Nisjetilbud"
        case nil:
            valueText = "Mangler vurdering"
        }

        if let difficulty = editorialAssessment?.difficultyLevel {
            return "\(valueText), \(difficulty.signalText)"
        }

        if let endDate {
            let daysUntilEnd = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
            if daysUntilEnd.map({ $0 >= 0 && $0 <= 7 }) == true {
                return "\(valueText), utløper snart"
            }
        }

        return valueText
    }
}

extension DifficultyLevel {
    var signalText: String {
        switch self {
        case .low:
            return "lav friksjon"
        case .medium:
            return "middels friksjon"
        case .high:
            return "høy friksjon"
        }
    }
}

struct CampaignMetadataStrip: View {
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

struct MetadataLabel: View {
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
