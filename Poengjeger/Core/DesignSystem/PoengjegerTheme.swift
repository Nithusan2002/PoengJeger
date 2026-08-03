import SwiftUI

enum PoengjegerTheme {
    static let accent = Color(red: 0.07, green: 0.38, blue: 0.52)
    static let accentSoft = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.07, green: 0.20, blue: 0.25, alpha: 1)
        }

        return UIColor(red: 0.85, green: 0.93, blue: 0.95, alpha: 1)
    })
    static let highlight = Color(red: 0.86, green: 0.58, blue: 0.12)
    static let warning = Color(red: 0.72, green: 0.22, blue: 0.10)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevatedSurface = Color(uiColor: .systemBackground)
    static let border = Color(uiColor: .separator).opacity(0.22)
}
