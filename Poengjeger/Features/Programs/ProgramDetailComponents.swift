import SwiftUI

struct ProgramHero: View {
    let program: BonusProgram
    let title: String
    let kicker: String
    let readingTimeLabel: String
    let lastReviewedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.comfortable) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.card) {
                ProgramMark(program: program, size: 56)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text(kicker)
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)

                    Text(title)
                        .font(DesignTokens.Typography.title)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DesignTokens.Spacing.medium) {
                        ProgramHeroMetaPill(text: readingTimeLabel, systemImage: "book")
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.medium)
            }

            Text(reviewText)
                .font(DesignTokens.Typography.footnote)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignTokens.Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private var reviewText: String {
        if let lastReviewedAt {
            return "Sist oppdatert \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return "Sist oppdatert: ikke satt"
    }
}

struct ProgramHeroMetaPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(DesignTokens.Typography.captionBold)
            .foregroundStyle(DesignTokens.Colors.brandPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, DesignTokens.Spacing.mediumPlus)
            .padding(.vertical, DesignTokens.Spacing.small)
    }
}

struct ProgramMark: View {
    let program: BonusProgram
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(program.programColor.opacity(DesignTokens.Opacity.selected))

            Text(program.initials)
                .font(DesignTokens.Typography.programMark(containerSize: size))
                .foregroundStyle(program.programColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ProgramMarkdownArticle: View {
    let markdown: String

    private var blocks: [ProgramGuideMarkdownBlock] {
        markdown.programGuideMarkdownBlocks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.screen) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .heading(level, text):
                    Text(text)
                        .font(font(for: level))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(
                            .top,
                            level == 1
                                ? DesignTokens.Spacing.xSmall
                                : DesignTokens.Spacing.controlGap
                        )

                case let .paragraph(text):
                    ProgramGuideParagraph(text: text)

                case let .bullet(text):
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.controlGap) {
                        Circle()
                            .fill(DesignTokens.Colors.brandPrimary)
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)

                        ProgramGuideParagraph(text: text)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1:
            return DesignTokens.Typography.title2Bold
        case 2:
            return DesignTokens.Typography.title3Bold
        default:
            return DesignTokens.Typography.headlineBold
        }
    }
}

struct ProgramGuideParagraph: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.body)
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgramReviewNote: View {
    let lastReviewedAt: Date?

    var body: some View {
        Text(reviewText)
            .font(DesignTokens.Typography.footnote)
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, DesignTokens.Spacing.xxSmall)
    }

    private var reviewText: String {
        if let lastReviewedAt {
            return "Sist oppdatert \(lastReviewedAt.formatted(date: .long, time: .omitted))"
        }

        return "Sist oppdatert: ikke satt"
    }
}
