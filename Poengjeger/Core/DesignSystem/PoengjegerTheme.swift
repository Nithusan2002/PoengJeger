import SwiftUI

enum PoengjegerTheme {
    static let primary = Color(red: 0.06, green: 0.46, blue: 0.43)
    static let primarySoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.03, green: 0.19, blue: 0.18, alpha: 1)
        }

        return UIColor(red: 0.87, green: 0.95, blue: 0.94, alpha: 1)
    })

    static let euroBonus = Color(red: 0.15, green: 0.39, blue: 0.65)
    static let euroBonusSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.04, green: 0.10, blue: 0.18, alpha: 1)
        }

        return UIColor(red: 0.91, green: 0.94, blue: 0.98, alpha: 1)
    })

    static let trumf = Color(red: 0.78, green: 0.16, blue: 0.21)
    static let trumfSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.03, blue: 0.05, alpha: 1)
        }

        return UIColor(red: 0.98, green: 0.91, blue: 0.92, alpha: 1)
    })

    static let campaign = Color(red: 0.71, green: 0.33, blue: 0.04)
    static let campaignSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.22, green: 0.13, blue: 0.02, alpha: 1)
        }

        return UIColor(red: 1.00, green: 0.95, blue: 0.88, alpha: 1)
    })

    static let warning = Color(red: 0.71, green: 0.14, blue: 0.09)
    static let warningSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.21, green: 0.06, blue: 0.05, alpha: 1)
        }

        return UIColor(red: 0.99, green: 0.92, blue: 0.91, alpha: 1)
    })

    static let success = Color(red: 0.09, green: 0.50, blue: 0.24)
    static let background = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.06, green: 0.08, blue: 0.07, alpha: 1)
        }

        return UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.09, green: 0.11, blue: 0.10, alpha: 1)
        }

        return UIColor.white
    })
    static let elevatedSurface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.12, green: 0.15, blue: 0.14, alpha: 1)
        }

        return UIColor.white
    })
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
