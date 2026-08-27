import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let program: BonusProgram
    let guide: ProgramGuide?
    let campaigns: [Campaign]

    private var activeCampaigns: [Campaign] {
        campaigns
            .filter { $0.isActive && $0.linkedProgramIDs.contains(program.id) }
            .sorted { first, second in
                switch (first.endDate, second.endDate) {
                case let (firstDate?, secondDate?):
                    return firstDate < secondDate
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return first.title.localizedCompare(second.title) == .orderedAscending
                }
            }
    }

    private var introText: String {
        guide?.introText?.programGuideNonEmpty
            ?? guide?.strategy.programGuideNonEmpty
            ?? "Ingen publisert programguide for \(program.name) ennå. Aktive kampanjer vises fortsatt under."
    }

    private var strategyText: String? {
        guard guide?.introText?.programGuideNonEmpty != nil else {
            return nil
        }

        return guide?.strategy.programGuideNonEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ProgramHero(
                    program: program,
                    activeCampaignCount: activeCampaigns.count,
                    introText: introText,
                    kicker: guide.guideKickerText,
                    readingTimeLabel: guide.readingTimeLabelText,
                    lastReviewedAt: guide?.lastReviewedAt
                )

                ProgramInsightRail(
                    cards: [
                        ProgramInsight(
                            systemImage: "centsign.circle",
                            eyebrow: "Verdi",
                            title: guide?.valueEstimateLabel?.programGuideNonEmpty ?? "Ukjent",
                            detail: guide?.valueEstimateDetail?.programGuideNonEmpty ?? "Verdien legges inn når den er kontrollert."
                        ),
                        ProgramInsight(
                            systemImage: "hourglass",
                            eyebrow: "Utløp",
                            title: guide?.expirationSummary?.programGuideNonEmpty ?? "Sjekk vilkår",
                            detail: guide?.expirationDetail?.programGuideNonEmpty ?? "Kontroller programmets egne vilkår før du lar poeng stå ubrukt."
                        ),
                        ProgramInsight(
                            systemImage: "ticket",
                            eyebrow: "Kampanjer",
                            title: "\(activeCampaigns.count) aktive",
                            detail: activeCampaigns.isEmpty ? "Ingen publiserte kampanjer akkurat nå." : "Se aktuelle muligheter for \(program.name) lenger ned."
                        )
                    ]
                )

                ProgramDecisionSnapshot(
                    title: guide.decisionSectionTitleText,
                    earningLabel: guide.earningDecisionLabelText,
                    earningTip: guide?.earningTips.first,
                    redemptionLabel: guide.redemptionDecisionLabelText,
                    redemptionTip: guide?.redemptionTips.first,
                    riskLabel: guide.riskDecisionLabelText,
                    riskNote: guide?.riskNotes.first
                )

                if let strategyText {
                    ProgramStrategyCard(title: guide.strategySectionTitleText, text: strategyText)
                }

                ProgramTipSection(
                    title: guide.earningSectionTitleText,
                    subtitle: guide.earningSectionIntroText,
                    systemImage: "plus.circle",
                    items: guide?.earningTips ?? []
                )

                ProgramTipSection(
                    title: guide.redemptionSectionTitleText,
                    subtitle: guide.redemptionSectionIntroText,
                    systemImage: "arrow.up.right.circle",
                    items: guide?.redemptionTips ?? []
                )

                ProgramTipSection(
                    title: guide.riskSectionTitleText,
                    subtitle: guide.riskSectionIntroText,
                    systemImage: "exclamationmark.triangle",
                    items: guide?.riskNotes ?? []
                )

                ProgramCampaignSection(
                    program: program,
                    title: guide.campaignsSectionTitleText,
                    subtitle: guide.campaignsSectionIntroText(for: program),
                    campaigns: activeCampaigns
                )

                ProgramReviewNote(lastReviewedAt: guide?.lastReviewedAt)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .task(id: program.id) {
            environment.track(.init(
                name: "guide_opened",
                surface: "guide",
                entityType: "guide",
                entityID: guide?.id,
                properties: [
                    "program_id": program.id.uuidString,
                    "entry_point": "guide"
                ]
            ))
        }
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(
            program: SampleData.trumf,
            guide: SampleData.programGuides.first { $0.programID == SampleData.trumf.id },
            campaigns: SampleData.campaigns
        )
    }
}
