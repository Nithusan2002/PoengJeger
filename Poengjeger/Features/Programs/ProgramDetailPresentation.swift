import SwiftUI

extension BonusProgram {
    var initials: String {
        switch slug {
        case "sas-eurobonus":
            return "EUR"
        case "trumf":
            return "TRU"
        case "spenn":
            return "SPE"
        case "norwegian-cashpoints", "norwegian-reward":
            return "CAS"
        case "flying-blue":
            return "FLY"
        case "avios":
            return "AVI"
        default:
            let words = name.split(separator: " ")
            let letters = words.prefix(2).compactMap(\.first)
            let value = String(letters).uppercased()
            return value.isEmpty ? String(name.prefix(2)).uppercased() : value
        }
    }

    var programColor: Color {
        switch slug {
        case "sas-eurobonus":
            return PoengjegerTheme.adaptive(light: (0.08, 0.28, 0.62), dark: (0.48, 0.72, 1.0))
        case "trumf":
            return PoengjegerTheme.adaptive(light: (0.78, 0.23, 0.14), dark: (1.0, 0.55, 0.59))
        case "spenn":
            return PoengjegerTheme.adaptive(light: (0.09, 0.5, 0.44), dark: (0.4, 0.82, 0.65))
        case "norwegian-cashpoints", "norwegian-reward":
            return PoengjegerTheme.adaptive(light: (0.79, 0.1, 0.12), dark: (1.0, 0.55, 0.59))
        case "flying-blue":
            return PoengjegerTheme.adaptive(light: (0.2, 0.39, 0.86), dark: (0.48, 0.72, 1.0))
        case "avios":
            return PoengjegerTheme.adaptive(light: (0.05, 0.44, 0.68), dark: (0.48, 0.72, 1.0))
        default:
            return PoengjegerTheme.accent
        }
    }
}

extension Optional where Wrapped == ProgramGuide {
    var introTextValue: String? {
        self?.introText?.programGuideNonEmpty ?? self?.bodyMarkdownExcerpt
    }

    var guideKickerText: String {
        self?.guideKicker?.programGuideNonEmpty ?? "PROGRAMGUIDE"
    }

    var readingTimeLabelText: String {
        self?.readingTimeLabel?.programGuideNonEmpty ?? "4 min lesing"
    }
}

extension ProgramGuide {
    func titleText(for program: BonusProgram) -> String {
        title?.programGuideNonEmpty ?? "Slik fungerer \(program.name)"
    }

    var bodyMarkdownExcerpt: String? {
        bodyMarkdown?
            .programGuideMarkdownBlocks
            .compactMap { block -> String? in
                switch block {
                case let .paragraph(text), let .bullet(text):
                    return text
                case .heading:
                    return nil
                }
            }
            .first?
            .programGuideNonEmpty
    }

    func articleMarkdown(for program: BonusProgram) -> String? {
        if let bodyMarkdown = bodyMarkdown?.programGuideNonEmpty {
            return bodyMarkdown
        }

        var sections: [String] = []
        sections.append("# \(titleText(for: program))")

        if let intro = introText?.programGuideNonEmpty {
            sections.append(intro)
        }

        if let strategy = strategy.programGuideNonEmpty {
            sections.append("## \(strategySectionTitle?.programGuideNonEmpty ?? "Slik bør du bruke det")\n\n\(strategy)")
        }

        appendMarkdownSection(
            title: earningSectionTitle?.programGuideNonEmpty ?? "Slik tjener du poeng",
            intro: earningSectionIntro?.programGuideNonEmpty,
            items: earningTips,
            to: &sections
        )
        appendMarkdownSection(
            title: redemptionSectionTitle?.programGuideNonEmpty ?? "Slik bruker du poengene smart",
            intro: redemptionSectionIntro?.programGuideNonEmpty,
            items: redemptionTips,
            to: &sections
        )
        appendMarkdownSection(
            title: riskSectionTitle?.programGuideNonEmpty ?? "Vanlige feller",
            intro: riskSectionIntro?.programGuideNonEmpty,
            items: riskNotes,
            to: &sections
        )

        let markdown = sections.joined(separator: "\n\n")
        return markdown.programGuideMarkdownBlocks.isEmpty ? nil : markdown
    }

    private func appendMarkdownSection(
        title: String,
        intro: String?,
        items: [String],
        to sections: inout [String]
    ) {
        var lines = ["## \(title)"]

        if let intro {
            lines.append("")
            lines.append(intro)
        }

        let normalizedItems = items.compactMap(\.programGuideNonEmpty)
        if !normalizedItems.isEmpty {
            lines.append("")
            lines.append(contentsOf: normalizedItems.map { "- \($0)" })
        }

        if lines.count > 1 {
            sections.append(lines.joined(separator: "\n"))
        }
    }
}

enum ProgramGuideMarkdownBlock: Hashable, Identifiable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullet(String)

    var id: Int {
        hashValue
    }
}

extension String {
    var programGuideMarkdownBlocks: [ProgramGuideMarkdownBlock] {
        var blocks: [ProgramGuideMarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            let text = paragraphLines.joined(separator: " ").programGuideNonEmpty
            if let text {
                blocks.append(.paragraph(text))
            }
            paragraphLines.removeAll()
        }

        for rawLine in components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if line.hasPrefix("#") {
                flushParagraph()
                let level = min(line.prefix(while: { $0 == "#" }).count, 3)
                let text = line.dropFirst(level).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    blocks.append(.heading(level: level, text: text))
                }
                continue
            }

            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                let text = line.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    blocks.append(.bullet(text))
                }
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        return blocks
    }
}

extension Date {
    var relativeDeadlineText: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: self)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days < 0 {
            return "UTLØPT"
        }

        if days == 0 {
            return "I DAG"
        }

        if days == 1 {
            return "1 DAG IGJEN"
        }

        return "\(days) DAGER IGJEN"
    }
}

extension String {
    var programGuideNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
