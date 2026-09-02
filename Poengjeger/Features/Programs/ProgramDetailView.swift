import SwiftUI

struct ProgramDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let program: BonusProgram
    let guide: ProgramGuide?

    private var articleMarkdown: String? {
        guide?.articleMarkdown(for: program)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ProgramHero(
                    program: program,
                    kicker: guide.guideKickerText,
                    readingTimeLabel: guide.readingTimeLabelText,
                    lastReviewedAt: guide?.lastReviewedAt
                )

                if let articleMarkdown {
                    ProgramMarkdownArticle(markdown: articleMarkdown)
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
