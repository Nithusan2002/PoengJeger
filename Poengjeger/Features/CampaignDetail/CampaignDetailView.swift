import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false

    let campaign: Campaign
    let entryPoint: String

    init(campaign: Campaign, entryPoint: String = "direct") {
        self.campaign = campaign
        self.entryPoint = entryPoint
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                campaignHeader
                recommendationSection
                primaryAction
                requirementsSection
                importantInformationSection
                sourceSection
                programGuideSection
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
                isFavorite: isFavorite,
                onBack: { dismiss() },
                onToggleFavorite: toggleFavorite
            )
        }
        .task(id: campaign.id) {
            isFavorite = environment.userSession.favoriteCampaignIDs.contains(campaign.id)
            environment.track(.init(
                name: "campaign_detail_opened",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: [
                    "entry_point": entryPoint,
                    "program_ids": campaign.linkedProgramIDs.map(\.uuidString).sorted().joined(separator: ","),
                    "program_count": "\(campaign.linkedProgramIDs.count)"
                ]
            ))
        }
    }

    private var campaignHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let primaryProgram {
                Text(primaryProgram.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.accent)
            }

            Text(campaign.title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if !campaign.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               campaign.summary != campaign.decisionConclusion {
                Text(campaign.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hasEditorialAssessment ? "Vurdering" : "Kort om kampanjen")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.primary)

            Text(campaign.decisionConclusion)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            if let value = nonempty(campaign.editorialAssessment?.estimatedValueText) {
                CampaignDecisionFact(title: "Mulig verdi", value: value)
            }

            CampaignDecisionFact(
                title: "Frist",
                value: campaign.endDate.map { $0.formatted(date: .long, time: .omitted) }
                    ?? "Ikke oppgitt"
            )

            if let requirement = campaign.sortedRequirements.first {
                CampaignDecisionFact(title: "Krav", value: requirement.text)
            }

            // Keep the complete editorial warning before the external action.
            if let warning = nonempty(campaign.editorialAssessment?.riskNote) {
                CampaignDecisionFact(title: "Vær oppmerksom på", value: warning)
            }
            if let notFor = nonempty(campaign.editorialAssessment?.notFor),
               notFor != nonempty(campaign.editorialAssessment?.riskNote) {
                CampaignDecisionFact(title: "Passer ikke for", value: notFor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if let primarySource = campaign.sources.first {
            CampaignSourceCTA(campaign: campaign, source: primarySource)
        }
    }

    @ViewBuilder
    private var requirementsSection: some View {
        if !campaign.requirements.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeading("Dette må du gjøre")

                ForEach(primaryRequirements) { requirement in
                    DetailRequirementRow(text: requirement.text)
                }

                if hasAdditionalRequirements {
                    DisclosureGroup("Vis flere krav (\(campaign.sortedRequirements.count - primaryRequirements.count))") {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(campaign.sortedRequirements.dropFirst(primaryRequirements.count))) { requirement in
                                DetailRequirementRow(text: requirement.text)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .tint(PoengjegerTheme.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var importantInformationSection: some View {
        if nonempty(campaign.details) != nil || !campaign.geoRestrictions.isEmpty
            || nonempty(campaign.editorialAssessment?.bestFor) != nil {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("Viktig å vite")

                if let details = nonempty(campaign.details) {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let bestFor = nonempty(campaign.editorialAssessment?.bestFor) {
                    CampaignDecisionFact(title: "Passer for", value: bestFor)
                }

                if !campaign.geoRestrictions.isEmpty {
                    CampaignDecisionFact(
                        title: "Gjelder",
                        value: campaign.geoRestrictions.map(\.displayName).joined(separator: ", ")
                    )
                }
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            sectionHeading("Kilde og kontroll")

            Text("Sist kontrollert \(campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(campaign.sources) { source in
                SourceLinkRow(source: source)
            }

            Text(campaign.sources.isEmpty
                 ? "Kildelenke mangler. Sjekk vilkårene hos tilbyder før bruk."
                 : "Sjekk alltid gjeldende vilkår hos tilbyder før bruk.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var programGuideSection: some View {
        if let primaryProgram {
            NavigationLink {
                ProgramDetailView(
                    program: primaryProgram,
                    guide: primaryProgramGuide,
                    entryPoint: "campaign_detail_cta"
                )
            } label: {
                Label("Les om \(primaryProgram.name)", systemImage: "book")
                    .font(.subheadline)
                    .frame(minHeight: 44, alignment: .leading)
            }
            .tint(PoengjegerTheme.accent)
            .accessibilityLabel("Åpne programguide for \(primaryProgram.name)")
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
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

    private var primaryRequirements: [CampaignRequirement] {
        Array(campaign.sortedRequirements.prefix(3))
    }

    private var hasAdditionalRequirements: Bool {
        campaign.sortedRequirements.count > primaryRequirements.count
    }

    private func toggleFavorite() {
        if isFavorite {
            isFavorite = false
            environment.userSession.favoriteCampaignIDs.remove(campaign.id)
            environment.track(.init(
                name: "favorite_removed",
                surface: "campaign_detail",
                entityType: "campaign",
                entityID: campaign.id,
                properties: ["favorite_type": "campaign"]
            ))
        } else {
            isFavorite = true
            environment.userSession.favoriteCampaignIDs.insert(campaign.id)
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

private struct CampaignDecisionFact: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
