import SwiftUI

struct DetailDisclosure<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.screen) {
                content
            }
            .padding(.top, DesignTokens.Spacing.card)
        } label: {
            Label(title, systemImage: "doc.text.magnifyingglass")
                .font(DesignTokens.Typography.headlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .minimumTouchTarget()
        .accessibilityHint(isExpanded ? "Skjuler detaljer og kilder." : "Viser detaljer og kilder.")
    }
}

struct DetailTopBar: View {
    let isFavorite: Bool
    let onBack: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.controlGap) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(DesignTokens.Typography.title3Semibold)
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .minimumTouchTarget()
            .accessibilityLabel("Tilbake")

            Spacer(minLength: DesignTokens.Spacing.medium)

            SaveToggleButton(
                isSaved: isFavorite,
                savedAccessibilityLabel: "Fjern favoritt",
                unsavedAccessibilityLabel: "Lagre favoritt",
                action: onToggleFavorite
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.screen)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct DetailIntro: View {
    let campaign: Campaign
    let primaryProgram: BonusProgram?
    let primaryProgramGuide: ProgramGuide?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.comfortable) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    if let primaryProgram {
                        NavigationLink {
                            ProgramDetailView(
                                program: primaryProgram,
                                guide: primaryProgramGuide,
                                entryPoint: "campaign_detail_intro"
                            )
                        } label: {
                            Label(primaryProgram.name.uppercased(), systemImage: "book")
                                .font(DesignTokens.Typography.captionSemibold)
                                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        }
                        .minimumTouchTarget()
                        .accessibilityLabel("Åpne programguide for \(primaryProgram.name)")
                    }

                    Text(campaign.title)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DesignTokens.Spacing.medium)
            }

            Text(campaign.summary)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            DetailDecisionSummary(conclusion: campaign.decisionConclusion)

            CampaignFitSummary(
                fitText: campaign.suitabilityFitText,
                caveatText: campaign.suitabilityCaveatText
            )

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
                DetailQuickFactCard(
                    title: "Mulig verdi",
                    value: campaign.detailValueLabel,
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                HStack(spacing: DesignTokens.Spacing.controlGap) {
                    DetailQuickFactCard(
                        title: "Frist",
                        value: FeedDateHelper.expiryLabel(campaign.endDate).text,
                        systemImage: "calendar"
                    )

                    DetailQuickFactCard(
                        title: "Krav",
                        value: campaign.requirementSignal,
                        systemImage: "checklist"
                    )
                }
            }

            DetailSourceSummary(campaign: campaign)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

struct DetailDecisionSummary: View {
    let conclusion: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Label("Kort sagt", systemImage: "checkmark.seal")
                .font(DesignTokens.Typography.subheadlineBold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)

            Text(conclusion)
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.brandPrimarySoft)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct DetailSourceSummary: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Label("Fakta og kilde", systemImage: "checkmark.seal")
                .font(DesignTokens.Typography.subheadlineBold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
                    sourceItems
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                    sourceItems
                }
            }

            Text("Kampanjer kvalitetssikres fra offentlige kilder. Sjekk alltid vilkårene hos tilbyder før bruk.")
                .font(DesignTokens.Typography.footnote)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var sourceItems: some View {
        SourceSummaryItem(
            title: "Kontrollert",
            value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted),
            systemImage: "calendar.badge.checkmark"
        )

        if let primarySource = campaign.sources.first {
            SourceSummaryItem(
                title: "Kilde",
                value: primarySource.sourceName,
                systemImage: "link"
            )
        }
    }
}

struct SourceSummaryItem: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
                Text(title.uppercased())
                    .font(DesignTokens.Typography.caption2Bold)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text(value)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
        }
        .labelStyle(.titleAndIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CampaignFitSummary: View {
    let fitText: String
    let caveatText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            FitLine(
                systemImage: "person.crop.circle.badge.checkmark",
                title: "Passer for",
                text: fitText,
                tint: DesignTokens.Colors.brandPrimary
            )

            if let caveatText {
                Divider()

                FitLine(
                    systemImage: "exclamationmark.triangle",
                    title: "Passer ikke for",
                    text: caveatText,
                    tint: DesignTokens.Colors.warning
                )
            }
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FitLine: View {
    let systemImage: String
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(title)
                    .font(DesignTokens.Typography.captionBold)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text(text)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .labelStyle(.titleAndIcon)
    }
}

struct DetailQuickFactCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.smallPlus) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(DesignTokens.Typography.caption2Bold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineLimit(1)

            Text(value)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.standard)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CampaignSourceCTA: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.openURL) private var openURL

    let campaign: Campaign
    let source: CampaignSourceReference

    var body: some View {
        Button {
            environment.track(.init(
                name: "external_destination_opened",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: [
                    "destination_type": "campaign_source",
                    "source_name": source.sourceName
                ]
            ))
            openURL(source.url)
        } label: {
            Label("Åpne kampanjen", systemImage: "arrow.up.right.square")
                .font(DesignTokens.Typography.headlineSemibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(DesignTokens.Colors.brandPrimaryButton)
        .accessibilityLabel("Åpne kampanjesiden hos \(source.sourceName)")
    }
}

struct ProgramGuideCTA: View {
    let program: BonusProgram
    let guide: ProgramGuide?

    var body: some View {
        NavigationLink {
            ProgramDetailView(
                program: program,
                guide: guide,
                entryPoint: "campaign_detail_cta"
            )
        } label: {
            Label(programGuideTitle, systemImage: "graduationcap")
                .font(DesignTokens.Typography.headlineSemibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(DesignTokens.Colors.brandPrimary)
        .accessibilityLabel("Åpne programguide for \(program.name)")
    }

    private var programGuideTitle: String {
        switch program.slug {
        case "sas-eurobonus":
            return "Forstå EuroBonus-poeng"
        case "trumf":
            return "Forstå Trumf-bonus"
        default:
            return "Forstå \(program.name)"
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            Label(title, systemImage: systemImage)
                .font(DesignTokens.Typography.headlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            content
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
    }
}

struct DetailFactLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
            Text(title)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DetailRequirementRow: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
                .font(DesignTokens.Typography.body)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
        }
        .labelStyle(.titleAndIcon)
    }
}

struct CampaignFactList: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
            facts
        }
    }

    @ViewBuilder
    private var facts: some View {
        if let categoryName = campaign.category?.name {
            FactRow(
                systemImage: "tag",
                title: "Kategori",
                value: categoryName
            )
        }

        FactRow(
            systemImage: "checkmark.seal",
            title: "Kontrollert",
            value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted)
        )

        if let firstSource = campaign.sources.first {
            FactRow(
                systemImage: "link",
                title: "Kilde",
                value: firstSource.sourceName
            )
        }

    }
}

struct SourceLinkRow: View {
    let source: CampaignSourceReference

    var body: some View {
        Link(destination: source.url) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                Label("Åpne kilde", systemImage: "arrow.up.right.square")
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)

                Text(source.title)
                    .font(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Sjekket hos \(source.sourceName) \(source.checkedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FactRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxSmall) {
                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Text(value)
                    .font(DesignTokens.Typography.subheadlineMedium)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
    }
}

struct DetailTextBlock: View {
    enum Prominence {
        case body
        case lead
    }

    let text: String
    var prominence: Prominence = .body

    var body: some View {
        Text(text)
            .font(prominence == .lead ? DesignTokens.Typography.headline : DesignTokens.Typography.body)
            .foregroundStyle(
                prominence == .lead
                    ? DesignTokens.Colors.textPrimary
                    : DesignTokens.Colors.textSecondary
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}
