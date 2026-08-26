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
            return Color(red: 0.08, green: 0.28, blue: 0.62)
        case "trumf":
            return Color(red: 0.78, green: 0.23, blue: 0.14)
        case "spenn":
            return Color(red: 0.09, green: 0.50, blue: 0.44)
        case "norwegian-cashpoints", "norwegian-reward":
            return Color(red: 0.79, green: 0.10, blue: 0.12)
        case "flying-blue":
            return Color(red: 0.20, green: 0.39, blue: 0.86)
        case "avios":
            return Color(red: 0.05, green: 0.44, blue: 0.68)
        default:
            return PoengjegerTheme.accent
        }
    }
}

extension Optional where Wrapped == ProgramGuide {
    var guideKickerText: String {
        self?.guideKicker?.programGuideNonEmpty ?? "PROGRAMGUIDE"
    }

    var readingTimeLabelText: String {
        self?.readingTimeLabel?.programGuideNonEmpty ?? "4 min lesing"
    }

    var strategySectionTitleText: String {
        self?.strategySectionTitle?.programGuideNonEmpty ?? "Slik bør du bruke det"
    }

    var decisionSectionTitleText: String {
        self?.decisionSectionTitle?.programGuideNonEmpty ?? "Før du går videre"
    }

    var earningDecisionLabelText: String {
        self?.earningDecisionLabel?.programGuideNonEmpty ?? "Tjen poeng når"
    }

    var redemptionDecisionLabelText: String {
        self?.redemptionDecisionLabel?.programGuideNonEmpty ?? "Bruk poeng når"
    }

    var riskDecisionLabelText: String {
        self?.riskDecisionLabel?.programGuideNonEmpty ?? "Stopp opp hvis"
    }

    var earningSectionTitleText: String {
        self?.earningSectionTitle?.programGuideNonEmpty ?? "Slik tjener du poeng"
    }

    var earningSectionIntroText: String {
        self?.earningSectionIntro?.programGuideNonEmpty ?? "Start her før du går for en kampanje."
    }

    var redemptionSectionTitleText: String {
        self?.redemptionSectionTitle?.programGuideNonEmpty ?? "Slik bruker du poengene smart"
    }

    var redemptionSectionIntroText: String {
        self?.redemptionSectionIntro?.programGuideNonEmpty ?? "Bruk poengene der du ser hva du får igjen."
    }

    var riskSectionTitleText: String {
        self?.riskSectionTitle?.programGuideNonEmpty ?? "Vanlige feller"
    }

    var riskSectionIntroText: String {
        self?.riskSectionIntro?.programGuideNonEmpty ?? "Ting som kan gjøre en god kampanje mindre god."
    }

    var campaignsSectionTitleText: String {
        self?.campaignsSectionTitle?.programGuideNonEmpty ?? "Kampanjer nå"
    }

    func campaignsSectionIntroText(for program: BonusProgram) -> String {
        self?.campaignsSectionIntro?.programGuideNonEmpty ?? "Aktive kampanjer knyttet til \(program.name)."
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
