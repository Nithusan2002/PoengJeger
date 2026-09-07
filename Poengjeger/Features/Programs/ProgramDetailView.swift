import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let program: BonusProgram
    let guide: ProgramGuide?
    let entryPoint: String

    init(program: BonusProgram, guide: ProgramGuide?, entryPoint: String = "guide") {
        self.program = program
        self.guide = guide
        self.entryPoint = entryPoint
    }

    private var articleMarkdown: String? {
        guide?.articleMarkdown(for: program)
    }

    private var currentCampaigns: [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.firstPhaseCampaigns,
            selectedProgramIDs: [program.id],
            showsAllPrograms: false,
            selectedCategoryID: nil,
            searchText: "",
            sort: .expiringFirst
        )
        .filter { $0.linkedProgramIDs.contains(program.id) }
        .prefix(3)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.comfortable) {
                ProgramHero(
                    program: program,
                    title: guide?.titleText(for: program) ?? program.name,
                    kicker: guide.guideKickerText,
                    readingTimeLabel: guide.readingTimeLabelText,
                    lastReviewedAt: guide?.lastReviewedAt
                )

                if let articleMarkdown {
                    ProgramMarkdownArticle(markdown: articleMarkdown)
                }

                currentOpportunitiesSection
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.section)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle(guide?.titleText(for: program) ?? program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
        .task(id: program.id) {
            environment.track(.init(
                name: "guide_opened",
                surface: "guide",
                entityType: "guide",
                entityID: guide?.id,
                properties: [
                    "program_id": program.id.uuidString,
                    "entry_point": entryPoint
                ]
            ))
        }
    }

    @ViewBuilder
    private var currentOpportunitiesSection: some View {
        if !currentCampaigns.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                Text("Aktuelle muligheter")
                    .font(DesignTokens.Typography.editorialTitle3)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text("Bruk guiden på kampanjer som er kontrollert akkurat nå.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                ForEach(currentCampaigns) { campaign in
                    NavigationLink {
                        CampaignDetailView(campaign: campaign, entryPoint: "guide_detail")
                    } label: {
                        CampaignCardView(
                            campaign: campaign,
                            primaryProgramName: program.name,
                            isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
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
