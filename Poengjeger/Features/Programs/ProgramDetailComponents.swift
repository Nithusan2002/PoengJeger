import SwiftUI

struct ProgramHero: View {
    let program: BonusProgram
    let introText: String
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

                    Text(program.name)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        ProgramHeroMetaPill(text: readingTimeLabel, systemImage: "book")
                    }
                }

                Spacer(minLength: 8)
            }

            Text(introText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

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
            return "Redaksjonelt kontrollert \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted)). Programvilkår kan endre seg, så sjekk alltid kilden før større valg."
        }

        return "Guiden har begrenset innhold til den er redaksjonelt kontrollert."
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
            .background(PoengjegerTheme.accentSoft)
            .clipShape(Capsule())
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

struct ProgramInsight: Identifiable {
    let id = UUID()
    let systemImage: String
    let eyebrow: String
    let title: String
    let detail: String
}

struct ProgramInsightRail: View {
    let cards: [ProgramInsight]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(cards) { card in
                    ProgramInsightCard(card: card)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

struct ProgramInsightCard: View {
    let card: ProgramInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: card.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(card.eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(card.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(card.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 166, alignment: .topLeading)
        .frame(minHeight: 160, alignment: .topLeading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

struct ProgramStrategyCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "target")
                .font(.headline.weight(.bold))
                .foregroundStyle(PoengjegerTheme.accent)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
    }
}

struct ProgramDecisionSnapshot: View {
    let title: String
    let earningLabel: String
    let earningTip: String?
    let redemptionLabel: String
    let redemptionTip: String?
    let riskLabel: String
    let riskNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "checklist")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                ProgramDecisionRow(
                    title: earningLabel,
                    text: earningTip?.programGuideNonEmpty ?? "kampanjen passer et kjøp du uansett skal gjøre.",
                    systemImage: "plus.circle",
                    tint: PoengjegerTheme.success
                )

                ProgramDecisionRow(
                    title: redemptionLabel,
                    text: redemptionTip?.programGuideNonEmpty ?? "du kan sammenligne poengbruk med kontantpris og vilkår.",
                    systemImage: "arrow.up.right.circle",
                    tint: PoengjegerTheme.accent
                )

                ProgramDecisionRow(
                    title: riskLabel,
                    text: riskNote?.programGuideNonEmpty ?? "vilkår, frist eller kostnad gjør verdien uklar.",
                    systemImage: "exclamationmark.triangle",
                    tint: PoengjegerTheme.warning
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
    }
}

struct ProgramDecisionRow: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ProgramTipSection: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if items.isEmpty {
                ProgramEmptyGuideRow(text: "Ikke publisert ennå.")
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        ProgramGuideParagraph(text: item)
                            .accessibilityLabel("Avsnitt \(index + 1): \(item)")
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.top, 4)
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

struct ProgramEmptyGuideRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
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
            return "Sist redaksjonelt kontrollert \(lastReviewedAt.formatted(date: .long, time: .omitted)). Sjekk alltid gjeldende programvilkår og kampanjekilde før større valg."
        }

        return "Guiden vises med begrenset innhold til den er kontrollert."
    }
}
