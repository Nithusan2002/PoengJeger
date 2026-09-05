import SwiftUI

enum PoengjegerTheme {
    // Text accents need lighter variants on dark surfaces. Filled buttons retain
    // a darker background so their white labels remain readable.
    static let primaryButtonBackground = Color(red: 0.06, green: 0.46, blue: 0.43)

    static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }

    static let primary = adaptive(light: (0.06, 0.46, 0.43), dark: (0.35, 0.8, 0.73))
    static let primarySoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.03, green: 0.19, blue: 0.18, alpha: 1)
        }

        return UIColor(red: 0.87, green: 0.95, blue: 0.94, alpha: 1)
    })
    static let primaryTint = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.05, green: 0.14, blue: 0.13, alpha: 1)
        }

        return UIColor(red: 0.95, green: 0.98, blue: 0.96, alpha: 1)
    })

    static let euroBonus = adaptive(light: (0.15, 0.39, 0.65), dark: (0.48, 0.72, 1.0))
    static let euroBonusSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.04, green: 0.10, blue: 0.18, alpha: 1)
        }

        return UIColor(red: 0.91, green: 0.94, blue: 0.98, alpha: 1)
    })

    static let trumf = adaptive(light: (0.78, 0.16, 0.21), dark: (1.0, 0.55, 0.59))
    static let trumfSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.03, blue: 0.05, alpha: 1)
        }

        return UIColor(red: 0.98, green: 0.91, blue: 0.92, alpha: 1)
    })

    static let campaign = adaptive(light: (0.33, 0.43, 0.29), dark: (0.65, 0.79, 0.53))
    static let campaignSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.10, green: 0.15, blue: 0.10, alpha: 1)
        }

        return UIColor(red: 0.95, green: 0.96, blue: 0.91, alpha: 1)
    })

    static let warning = adaptive(light: (0.71, 0.14, 0.09), dark: (1.0, 0.57, 0.48))
    static let warningSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.21, green: 0.06, blue: 0.05, alpha: 1)
        }

        return UIColor(red: 0.99, green: 0.92, blue: 0.91, alpha: 1)
    })

    static let success = adaptive(light: (0.09, 0.5, 0.24), dark: (0.4, 0.82, 0.55))
    static let neutralSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.15, green: 0.14, blue: 0.12, alpha: 1)
        }

        return UIColor(red: 0.95, green: 0.94, blue: 0.91, alpha: 1)
    })
    static let background = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.06, green: 0.08, blue: 0.07, alpha: 1)
        }

        return UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.12, green: 0.15, blue: 0.14, alpha: 1)
        }

        return UIColor.white
    })
    static let elevatedSurface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.16, green: 0.19, blue: 0.18, alpha: 1)
        }

        return UIColor.white
    })
    static let border = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.32, green: 0.36, blue: 0.34, alpha: 1)
        }

        return UIColor(red: 0.89, green: 0.87, blue: 0.83, alpha: 1)
    })
    static let primaryBorder = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.19, green: 0.42, blue: 0.39, alpha: 1)
        }

        return UIColor(red: 0.67, green: 0.78, blue: 0.72, alpha: 1)
    })
    static let shadow = Color.black.opacity(0.04)

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
