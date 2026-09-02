import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let program: BonusProgram
    let guide: ProgramGuide?

    private var introText: String {
        guide.introTextValue
            ?? guide?.strategy.programGuideNonEmpty
            ?? "Ingen publisert programguide for \(program.name) ennå."
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
                    introText: introText,
                    kicker: guide.guideKickerText,
                    readingTimeLabel: guide.readingTimeLabelText,
                    lastReviewedAt: guide?.lastReviewedAt
                )

                if let bodyMarkdown = guide?.bodyMarkdown?.programGuideNonEmpty {
                    ProgramMarkdownArticle(markdown: bodyMarkdown)
                } else {
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
                }

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
            guide: SampleData.programGuides.first { $0.programID == SampleData.trumf.id }
        )
    }
}
