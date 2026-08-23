import SwiftUI

enum PoengjegerTheme {
    static let primary = Color(red: 0.07, green: 0.38, blue: 0.52)
    static let primarySoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.07, green: 0.20, blue: 0.25, alpha: 1)
        }

        return UIColor(red: 0.85, green: 0.93, blue: 0.95, alpha: 1)
    })

    static let euroBonus = Color(red: 0.12, green: 0.43, blue: 0.66)
    static let euroBonusSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.07, green: 0.18, blue: 0.28, alpha: 1)
        }

        return UIColor(red: 0.87, green: 0.94, blue: 0.98, alpha: 1)
    })

    static let trumf = Color(red: 0.73, green: 0.10, blue: 0.14)
    static let trumfSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.28, green: 0.06, blue: 0.07, alpha: 1)
        }

        return UIColor(red: 1.00, green: 0.90, blue: 0.91, alpha: 1)
    })

    static let campaign = Color(red: 0.86, green: 0.58, blue: 0.12)
    static let campaignSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.24, green: 0.17, blue: 0.06, alpha: 1)
        }

        return UIColor(red: 1.00, green: 0.96, blue: 0.88, alpha: 1)
    })

    static let warning = Color(red: 0.72, green: 0.22, blue: 0.10)
    static let warningSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.26, green: 0.09, blue: 0.04, alpha: 1)
        }

        return UIColor(red: 1.00, green: 0.93, blue: 0.90, alpha: 1)
    })

    static let success = Color(red: 0.13, green: 0.48, blue: 0.31)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevatedSurface = Color(uiColor: .systemBackground)
    static let border = Color(uiColor: .separator).opacity(0.22)

    static let accent = primary
    static let accentSoft = primarySoft
    static let euroBonusBlue = euroBonus
    static let trumfRed = trumf
    static let editorialBlue = euroBonus
    static let highlight = campaign
    static let highlightSoft = campaignSoft

    static func programColor(slug: String?) -> Color {
        switch slug {
        case "sas-eurobonus":
            return euroBonus
        case "trumf":
            return trumf
        default:
            return primary
        }
    }

    static func programSoftColor(slug: String?) -> Color {
        switch slug {
        case "sas-eurobonus":
            return euroBonusSoft
        case "trumf":
            return trumfSoft
        default:
            return primarySoft
        }
    }
}
