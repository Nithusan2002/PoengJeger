import SwiftUI

struct ProgramHero: View {
    let program: BonusProgram
    let title: String
    let kicker: String
    let readingTimeLabel: String
    let lastReviewedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                ProgramMark(program: program, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(kicker)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.accent)

                    Text(title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        ProgramHeroMetaPill(text: readingTimeLabel, systemImage: "book")
                    }
                }

                Spacer(minLength: 8)
            }

            Text(reviewText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
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
            .font(.caption.weight(.bold))
            .foregroundStyle(PoengjegerTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
    }
}

struct ProgramMark: View {
    let program: BonusProgram
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(program.programColor.opacity(0.14))

            Text(program.initials)
                .font(.system(size: size * 0.28, weight: .bold))
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
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .heading(level, text):
                    Text(text)
                        .font(font(for: level))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, level == 1 ? 4 : 10)

                case let .paragraph(text):
                    ProgramGuideParagraph(text: text)

                case let .bullet(text):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Circle()
                            .fill(PoengjegerTheme.accent)
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
            return .title2.weight(.bold)
        case 2:
            return .title3.weight(.bold)
        default:
            return .headline.weight(.bold)
        }
    }
}

struct ProgramGuideParagraph: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
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
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
    }

    private var reviewText: String {
        if let lastReviewedAt {
            return "Sist oppdatert \(lastReviewedAt.formatted(date: .long, time: .omitted))"
        }

        return "Sist oppdatert: ikke satt"
    }
}
