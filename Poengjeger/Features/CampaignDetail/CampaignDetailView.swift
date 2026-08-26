import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var isDetailDisclosureExpanded = false

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DetailIntro(
                    campaign: campaign,
                    primaryProgram: primaryProgram,
                    primaryProgramGuide: primaryProgramGuide,
                    campaigns: environment.firstPhaseCampaigns
                )

                if !campaign.requirements.isEmpty {
                    DetailSection(title: "Dette må du gjøre", systemImage: "checklist") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(primaryRequirements) { requirement in
                                DetailRequirementRow(text: requirement.text)
                            }
                        }
                    }
                }

                if let primarySource = campaign.sources.first {
                    CampaignSourceCTA(source: primarySource)
                }

                if let primaryProgram {
                    ProgramGuideCTA(
                        program: primaryProgram,
                        guide: primaryProgramGuide,
                        campaigns: environment.firstPhaseCampaigns
                    )
                }

                DetailDisclosure(
                    isExpanded: $isDetailDisclosureExpanded,
                    title: "Detaljer og kilde"
                ) {
                    detailedContent
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
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

    @ViewBuilder
    private var detailedContent: some View {
        if hasEditorialAssessment {
            DetailSection(title: "Hvorfor vi viser den", systemImage: "chart.line.uptrend.xyaxis") {
                VStack(alignment: .leading, spacing: 12) {
                    if !campaign.editorialSummary.isEmpty {
                        DetailTextBlock(text: campaign.editorialSummary, prominence: .lead)
                    }

                    if let assessment = campaign.editorialAssessment {
                        DetailTextBlock(text: assessment.reasonWhyItMatters)

                        if let estimatedValueText = assessment.estimatedValueText {
                            DetailFactLine(title: "Hva kan du få?", value: estimatedValueText)
                        }
                    } else if campaign.editorialScore != nil {
                        DetailTextBlock(text: campaign.editorialTierLabel)
                    }
                }
            }
        }

        DetailSection(title: "Slik fungerer det", systemImage: "gift") {
            DetailTextBlock(text: campaign.details)
        }

        if hasAdditionalRequirements {
            DetailSection(title: "Alle krav", systemImage: "checklist") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(campaign.sortedRequirements) { requirement in
                        DetailRequirementRow(text: requirement.text)
                    }
                }
            }
        }

        if hasLimitations {
            DetailSection(title: "Begrensninger", systemImage: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: 12) {
                    if let riskNote = campaign.editorialAssessment?.riskNote {
                        DetailTextBlock(text: riskNote)
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

        DetailSection(title: "Fakta og kilde", systemImage: "link") {
            VStack(alignment: .leading, spacing: 14) {
                CampaignFactList(campaign: campaign)

                if !campaign.sources.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(campaign.sources) { source in
                            SourceLinkRow(source: source)
                        }
                    }
                }
            }
        }
    }

    private func toggleFavorite(in favoriteIDs: inout Set<UUID>) {
        if favoriteIDs.contains(campaign.id) {
            favoriteIDs.remove(campaign.id)
        } else {
            favoriteIDs.insert(campaign.id)
        }
    }

}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
