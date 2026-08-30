import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                campaignHeader
                recommendationSection
                factsSection
                requirementsSection
                programGuideSection
                detailAndSourceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .background(PoengjegerTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            DetailTopBar(
                isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id),
                onBack: { dismiss() },
                onToggleFavorite: { toggleFavorite(in: &environment.userSession.favoriteCampaignIDs) }
            )
        }
        .task(id: campaign.id) {
            environment.track(.init(
                name: "campaign_detail_opened",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: ["entry_point": "direct"]
            ))
        }
    }

    private var campaignHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let primaryProgram {
                NavigationLink {
                    ProgramDetailView(
                        program: primaryProgram,
                        guide: primaryProgramGuide,
                        campaigns: environment.firstPhaseCampaigns
                    )
                } label: {
                    Label(primaryProgram.name.uppercased(), systemImage: "book")
                        .font(.caption.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(PoengjegerTheme.accent)
                }
                .accessibilityLabel("Åpne programguide for \(primaryProgram.name)")
            }

            Text(campaign.title)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(campaign.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("REDAKSJONELL VURDERING")
                .font(.caption.weight(.bold))
                .tracking(2.6)
                .foregroundStyle(PoengjegerTheme.primary)

            Text(campaign.decisionConclusion)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !campaign.suitabilityFitText.isEmpty {
                CampaignFitLine(
                    title: "Passer for",
                    text: campaign.suitabilityFitText,
                    systemImage: "person.crop.circle.badge.checkmark",
                    tint: PoengjegerTheme.primary
                )
            }

            if let caveatText = campaign.suitabilityCaveatText {
                CampaignFitLine(
                    title: "Passer ikke for",
                    text: caveatText,
                    systemImage: "exclamationmark.triangle",
                    tint: PoengjegerTheme.warning
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    CampaignMetricCard(title: "Mulig verdi", value: campaign.detailValueLabel, systemImage: "chart.line.uptrend.xyaxis")
                    CampaignMetricCard(title: "Frist", value: FeedDateHelper.expiryLabel(campaign.endDate).text, systemImage: "calendar")
                    CampaignMetricCard(title: "Krav", value: campaign.requirementSignal, systemImage: "checklist")
                }

                VStack(alignment: .leading, spacing: 10) {
                    CampaignMetricCard(title: "Mulig verdi", value: campaign.detailValueLabel, systemImage: "chart.line.uptrend.xyaxis")

                    HStack(spacing: 10) {
                        CampaignMetricCard(title: "Frist", value: FeedDateHelper.expiryLabel(campaign.endDate).text, systemImage: "calendar")
                        CampaignMetricCard(title: "Krav", value: campaign.requirementSignal, systemImage: "checklist")
                    }
                }
            }

            if let primarySource = campaign.sources.first {
                CampaignSourceCTA(campaign: campaign, source: primarySource)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 10, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CampaignLovableSectionHeading(eyebrow: "KILDE OG KONTROLL", title: "Fakta og kilde")

            VStack(alignment: .leading, spacing: 16) {
                CampaignFactGrid(campaign: campaign)

                Text("Kampanjer kvalitetssikres fra offentlige kilder. Sjekk alltid vilkårene hos tilbyder før bruk.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PoengjegerTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PoengjegerTheme.border, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var requirementsSection: some View {
        if !campaign.requirements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                CampaignLovableSectionHeading(eyebrow: "HANDLING", title: "Dette må du gjøre")

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(primaryRequirements) { requirement in
                        CampaignRequirementStep(text: requirement.text)
                    }

                    if hasAdditionalRequirements {
                        Divider()

                        ForEach(Array(campaign.sortedRequirements.dropFirst(primaryRequirements.count))) { requirement in
                            CampaignRequirementStep(text: requirement.text)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PoengjegerTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PoengjegerTheme.border, lineWidth: 1)
                }
            }
        }
    }

    @ViewBuilder
    private var programGuideSection: some View {
        if let primaryProgram {
            ProgramGuideCTA(
                program: primaryProgram,
                guide: primaryProgramGuide,
                campaigns: environment.firstPhaseCampaigns
            )
        }
    }

    private var detailAndSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CampaignLovableSectionHeading(eyebrow: "DETALJER OG KILDE", title: "Derfor viser vi den")

            VStack(alignment: .leading, spacing: 16) {
                explanationCard
                howItWorksCard
                limitationsCard
                sourceLinksCard
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PoengjegerTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PoengjegerTheme.border, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var explanationCard: some View {
        if hasEditorialAssessment {
            CampaignDetailInfoCard(title: "Hvorfor vi viser den", systemImage: "chart.line.uptrend.xyaxis") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(campaign.decisionConclusion)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let assessment = campaign.editorialAssessment {
                        Text(assessment.reasonWhyItMatters)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let estimatedValueText = assessment.estimatedValueText {
                            DetailFactLine(title: "Hva kan du få?", value: estimatedValueText)
                        }
                    } else if !campaign.editorialSummary.isEmpty {
                        Text(campaign.editorialSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var howItWorksCard: some View {
        CampaignDetailInfoCard(title: "Slik fungerer det", systemImage: "gift") {
            Text(campaign.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var limitationsCard: some View {
        if hasLimitations {
            CampaignDetailInfoCard(title: "Begrensninger", systemImage: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: 12) {
                    if let riskNote = campaign.editorialAssessment?.riskNote {
                        Text(riskNote)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !campaign.geoRestrictions.isEmpty {
                        DetailFactLine(
                            title: "Gjelder",
                            value: campaign.geoRestrictions.map(\.displayName).joined(separator: ", ")
                        )
                    }

                    if let endDate = campaign.endDate {
                        DetailFactLine(
                            title: "Utløper",
                            value: endDate.formatted(date: .long, time: .omitted)
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sourceLinksCard: some View {
        if !campaign.sources.isEmpty {
            CampaignDetailInfoCard(title: "Kilder", systemImage: "link") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(campaign.sources) { source in
                        SourceLinkRow(source: source)
                    }
                }
            }
        }
    }

    private var primaryProgram: BonusProgram? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return environment.firstPhasePrograms.first(where: { $0.id == primaryProgramID })
            ?? environment.programs.first(where: { $0.id == primaryProgramID })
    }

    private var primaryProgramGuide: ProgramGuide? {
        guard let primaryProgram else { return nil }
        return environment.programGuide(for: primaryProgram)
    }

    private var hasEditorialAssessment: Bool {
        campaign.editorialScore != nil || campaign.editorialAssessment != nil || !campaign.editorialSummary.isEmpty
    }

    private var hasLimitations: Bool {
        campaign.editorialAssessment?.riskNote != nil || !campaign.geoRestrictions.isEmpty || campaign.endDate != nil
    }

    private var primaryRequirements: [CampaignRequirement] {
        Array(campaign.sortedRequirements.prefix(3))
    }

    private var hasAdditionalRequirements: Bool {
        campaign.sortedRequirements.count > primaryRequirements.count
    }

    private func toggleFavorite(in favoriteIDs: inout Set<UUID>) {
        if favoriteIDs.contains(campaign.id) {
            favoriteIDs.remove(campaign.id)
            environment.track(.init(
                name: "favorite_removed",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: ["favorite_type": "campaign"]
            ))
        } else {
            favoriteIDs.insert(campaign.id)
            environment.track(.init(
                name: "favorite_added",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: ["favorite_type": "campaign"]
            ))
        }
    }
}

private struct CampaignLovableSectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(2.6)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CampaignFitLine: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CampaignMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CampaignFactGrid: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let categoryName = campaign.category?.name {
                CampaignFactPill(systemImage: "tag", title: "Kategori", value: categoryName)
            }

            CampaignFactPill(
                systemImage: "calendar.badge.checkmark",
                title: "Kontrollert",
                value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted)
            )

            if let firstSource = campaign.sources.first {
                CampaignFactPill(systemImage: "link", title: "Kilde", value: firstSource.sourceName)
            }
        }
    }
}

private struct CampaignFactPill: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
    }
}

private struct CampaignRequirementStep: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.accent)
                .frame(width: 28)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CampaignDetailInfoCard<Content: View>: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
