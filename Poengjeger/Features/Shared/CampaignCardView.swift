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
        .font(DesignTokens.Typography.footnote)
        .foregroundStyle(DesignTokens.Colors.warning)
        .padding(DesignTokens.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.warning.opacity(DesignTokens.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct CampaignCardView: View {
    let campaign: Campaign
    let primaryProgramName: String?
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.none) {
            Rectangle()
                .fill(campaign.cardAccent)
                .frame(width: 5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                        TagRow(
                            primaryProgramName: primaryProgramName,
                            categoryName: campaign.category?.name,
                            isFeatured: campaign.isFeatured
                        )

                        Text(campaign.title)
                            .font(DesignTokens.Typography.headlineSemibold)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(campaign.opportunitySignal)
                            .font(DesignTokens.Typography.subheadlineSemibold)
                            .foregroundStyle(campaign.cardAccent)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(campaign.displaySummary)
                            .font(DesignTokens.Typography.subheadline)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: DesignTokens.Spacing.medium)

                    if campaign.editorialScore != nil {
                        EditorialTierBadge(label: campaign.editorialTierLabel, tint: campaign.cardAccent)
                    }
                }

                Divider()

                HStack(alignment: .center, spacing: DesignTokens.Spacing.controlGap) {
                    CampaignMetadataStrip(campaign: campaign)

                    Spacer(minLength: DesignTokens.Spacing.medium)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(DesignTokens.Typography.bodySemibold)
                            .foregroundStyle(DesignTokens.Colors.opportunity)
                            .accessibilityLabel("Lagret som favoritt")
                    }
                }
                .padding(.top, DesignTokens.Spacing.hairline)
            }
            .padding(DesignTokens.Spacing.screen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(campaign.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .shadow(color: DesignTokens.Colors.shadow, radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }
}

struct TagRow: View {
    let primaryProgramName: String?
    let categoryName: String?
    let isFeatured: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                tags
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                tags
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        if let primaryProgramName {
            TagView(title: primaryProgramName, tint: DesignTokens.Colors.brandPrimary)
        }

        if let categoryName {
            TagView(title: categoryName, tint: DesignTokens.Colors.textSecondary)
        }

        if isFeatured {
            TagView(title: "Fremhevet", tint: DesignTokens.Colors.opportunity)
        }
    }
}

struct EditorialTierBadge: View {
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.compact) {
            Image(systemName: "sparkles")
                .font(DesignTokens.Typography.captionBold)
                .accessibilityHidden(true)
            Text(label)
                .font(DesignTokens.Typography.captionBold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .frame(width: 84)
        .background(tint.opacity(DesignTokens.Opacity.softStrong))
        .foregroundStyle(tint)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vurdering: \(label)")
    }
}

struct TagView: View {
    let title: String
    var tint: Color = DesignTokens.Colors.brandPrimary

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.xSmall)
            .background(tint.opacity(DesignTokens.Opacity.soft))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.badge, style: .continuous))
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
            return DesignTokens.Colors.opportunity
        }

        if isHighScore {
            return DesignTokens.Colors.euroBonus
        }

        return DesignTokens.Colors.brandPrimary
    }

    var cardSurface: Color {
        isExpiringSoon ? DesignTokens.Colors.opportunitySoft : DesignTokens.Colors.surfaceElevated
    }

    var opportunitySignal: String {
        let valueText: String
        switch editorialScore {
        case let score? where score >= 80:
            valueText = "God deal"
        case let score? where score >= 65:
            valueText = "Verdt å sjekke"
        case .some:
            valueText = "For spesielt interesserte"
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
            return "lett å bruke"
        case .medium:
            return "sjekk kravene"
        case .high:
            return "krevende"
        }
    }
}

struct CampaignMetadataStrip: View {
    let campaign: Campaign

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.standard) {
                labels
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.hairline) {
                Text(title)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Text(value)
                    .font(DesignTokens.Typography.captionMedium)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .labelStyle(.titleAndIcon)
    }
}
