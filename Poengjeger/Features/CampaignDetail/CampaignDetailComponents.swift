import SwiftUI

struct DetailDisclosure<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(.top, 14)
        } label: {
            Label(title, systemImage: "doc.text.magnifyingglass")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityHint(isExpanded ? "Skjuler detaljer og kilder." : "Viser detaljer og kilder.")
    }
}

struct DetailTopBar: View {
    let isFavorite: Bool
    let onBack: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tilbake")

            Spacer(minLength: 8)

            SaveToggleButton(
                isSaved: isFavorite,
                savedAccessibilityLabel: "Fjern favoritt",
                unsavedAccessibilityLabel: "Lagre favoritt",
                action: onToggleFavorite
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    if let primaryProgram {
                        NavigationLink {
                            ProgramDetailView(
                                program: primaryProgram,
                                guide: primaryProgramGuide,
                                entryPoint: "campaign_detail_intro"
                            )
                        } label: {
                            Label(primaryProgram.name.uppercased(), systemImage: "book")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PoengjegerTheme.accent)
                        }
                        .accessibilityLabel("Åpne programguide for \(primaryProgram.name)")
                    }

                    Text(campaign.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            Text(campaign.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            DetailDecisionSummary(conclusion: campaign.decisionConclusion)

            CampaignFitSummary(
                fitText: campaign.suitabilityFitText,
                caveatText: campaign.suitabilityCaveatText
            )

            VStack(alignment: .leading, spacing: 10) {
                DetailQuickFactCard(
                    title: "Mulig verdi",
                    value: campaign.detailValueLabel,
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                HStack(spacing: 10) {
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Kort sagt", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PoengjegerTheme.accent)

            Text(conclusion)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct DetailSourceSummary: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fakta og kilde", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    sourceItems
                }

                VStack(alignment: .leading, spacing: 12) {
                    sourceItems
                }
            }

            Text("Kampanjer kvalitetssikres fra offentlige kilder. Sjekk alltid vilkårene hos tilbyder før bruk.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
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
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CampaignFitSummary: View {
    let fitText: String
    let caveatText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FitLine(
                systemImage: "person.crop.circle.badge.checkmark",
                title: "Passer for",
                text: fitText,
                tint: PoengjegerTheme.accent
            )

            if let caveatText {
                Divider()

                FitLine(
                    systemImage: "exclamationmark.triangle",
                    title: "Passer ikke for",
                    text: caveatText,
                    tint: PoengjegerTheme.warning
                )
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
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
        VStack(alignment: .leading, spacing: 7) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
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
            Label("Åpne kampanjen hos \(source.sourceName)", systemImage: "arrow.up.right.square")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(PoengjegerTheme.accent)
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
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(PoengjegerTheme.accent)
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
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

struct DetailFactLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
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
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
    }
}

struct CampaignFactList: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            VStack(alignment: .leading, spacing: 8) {
                Label("Åpne kilde", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.accent)

                Text(source.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Sjekket hos \(source.sourceName) \(source.checkedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(PoengjegerTheme.accent)
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
            .font(prominence == .lead ? .headline : .body)
            .foregroundStyle(prominence == .lead ? .primary : .secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
