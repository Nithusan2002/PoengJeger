import SwiftUI

/// The single source of truth for Poengjeger's visual primitives.
///
/// Components should choose tokens by purpose. Feature code should not introduce
/// new RGB values, spacing numbers, corner radii, or font constructions directly.
enum DesignTokens {
    enum Colors {
        // App identity and actions
        static let brandPrimary = adaptive(light: (15, 118, 110), dark: (89, 204, 186))
        static let brandPrimaryButton = rgb(15, 118, 110)
        static let brandPrimarySoft = adaptive(light: (221, 243, 240), dark: (8, 48, 46))
        static let brandPrimaryTint = adaptive(light: (242, 250, 245), dark: (13, 36, 33))
        static let brandPrimaryBorder = adaptive(light: (171, 199, 184), dark: (48, 107, 99))

        // Bonus-program identity
        static let euroBonus = adaptive(light: (37, 99, 166), dark: (122, 184, 255))
        static let euroBonusSoft = adaptive(light: (232, 240, 250), dark: (10, 26, 46))
        static let trumf = adaptive(light: (199, 41, 54), dark: (255, 140, 150))
        static let trumfSoft = adaptive(light: (250, 232, 235), dark: (51, 8, 13))

        // Existing program presentation colors. Only EuroBonus and Trumf are in MVP scope.
        static let programEuroBonus = adaptive(light: (20, 71, 158), dark: (122, 184, 255))
        static let programTrumf = adaptive(light: (199, 59, 36), dark: (255, 140, 150))
        static let programSpenn = adaptive(light: (23, 128, 112), dark: (102, 209, 166))
        static let programNorwegian = adaptive(light: (201, 26, 31), dark: (255, 140, 150))
        static let programFlyingBlue = adaptive(light: (51, 99, 219), dark: (122, 184, 255))
        static let programAvios = adaptive(light: (13, 112, 173), dark: (122, 184, 255))
        static let feedTrumf = adaptive(light: (26, 122, 71), dark: (102, 209, 166))
        static let feedSpenn = adaptive(light: (158, 77, 194), dark: (179, 166, 255))

        // Meaning and status
        static let opportunity = adaptive(light: (84, 110, 74), dark: (166, 201, 135))
        static let opportunitySoft = adaptive(light: (242, 245, 232), dark: (26, 38, 26))
        static let warning = adaptive(light: (181, 36, 23), dark: (255, 145, 122))
        static let warningSoft = adaptive(light: (252, 235, 232), dark: (54, 15, 13))
        static let success = adaptive(light: (23, 128, 61), dark: (102, 209, 140))

        // Editorial workflow status
        static let statusNew = Color.blue
        static let statusNeedsReview = Color.orange
        static let statusApproved = Color.green
        static let statusRejected = Color.red
        static let statusPromoted = brandPrimary

        // Content surfaces and text
        static let background = adaptive(light: (247, 247, 245), dark: (15, 20, 18))
        static let surface = adaptive(light: (255, 255, 255), dark: (31, 38, 36))
        static let surfaceElevated = adaptive(light: (255, 255, 255), dark: (41, 48, 46))
        static let neutralSoft = adaptive(light: (242, 240, 232), dark: (38, 36, 31))
        static let border = adaptive(light: (227, 222, 212), dark: (82, 92, 87))
        static let shadow = Color.black.opacity(Opacity.shadow)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(uiColor: .tertiaryLabel)
        static let textOnStrongColor = Color.white
        static let clear = Color.clear

        // Store decision surfaces
        static let storePageBackground = adaptive(light: (252, 250, 242), dark: (15, 18, 15))
        static let storeCardBackground = adaptive(light: (255, 255, 255), dark: (28, 33, 31))
        static let recommendationBackground = adaptive(light: (247, 250, 245), dark: (26, 33, 28))
        static let campaignBackground = adaptive(light: (255, 247, 237), dark: (43, 28, 18))
        static let cautionBackground = adaptive(light: (245, 230, 199), dark: (59, 46, 26))
        static let noticeBackground = adaptive(light: (250, 237, 204), dark: (51, 41, 23))
        static let campaignBorder = rgb(227, 184, 148)
        static let noticeBorder = rgb(219, 191, 135)
        static let expiryText = adaptive(light: (158, 79, 23), dark: (255, 194, 97))
        static let noticeText = adaptive(light: (140, 87, 20), dark: (255, 194, 97))

        static func program(slug: String?) -> Color {
            switch slug {
            case "sas-eurobonus": euroBonus
            case "trumf": trumf
            default: brandPrimary
            }
        }

        static func programSoft(slug: String?) -> Color {
            switch slug {
            case "sas-eurobonus": euroBonusSoft
            case "trumf": trumfSoft
            default: brandPrimarySoft
            }
        }
    }

    /// Core spacing follows a four-point rhythm. The named compatibility values
    /// cover layouts already present in the app and should not grow casually.
    enum Spacing {
        static let negativeTight: CGFloat = -4
        static let none: CGFloat = 0
        static let hairline: CGFloat = 1
        static let xxSmall: CGFloat = 2
        static let micro: CGFloat = 3
        static let xSmall: CGFloat = 4
        static let compact: CGFloat = 5
        static let small: CGFloat = 6
        static let smallPlus: CGFloat = 7
        static let medium: CGFloat = 8
        static let mediumPlus: CGFloat = 9
        static let controlGap: CGFloat = 10
        static let controlGapPlus: CGFloat = 11
        static let standard: CGFloat = 12
        static let standardPlus: CGFloat = 13
        static let card: CGFloat = 14
        static let cardPlus: CGFloat = 15
        static let screen: CGFloat = 16
        static let screenPlus: CGFloat = 17
        static let comfortable: CGFloat = 18
        static let large: CGFloat = 20
        static let largePlus: CGFloat = 22
        static let section: CGFloat = 24
        static let sectionLarge: CGFloat = 28
        static let emptyState: CGFloat = 30
        static let xxLarge: CGFloat = 32
        static let detailBottom: CGFloat = 36
        static let spacious: CGFloat = 40
        static let searchLeadingInset: CGFloat = 44
        static let iconLeadingInset: CGFloat = 52
        static let onboardingTop: CGFloat = 76
        static let largeIconLeadingInset: CGFloat = 78
    }

    enum Radius {
        static let badge: CGFloat = 6
        static let small: CGFloat = 8
        static let control: CGFloat = 10
        static let medium: CGFloat = 12
        static let card: CGFloat = 14
        static let largeCard: CGFloat = 16
        static let prominentCard: CGFloat = 18
        static let hero: CGFloat = 22
    }

    enum Typography {
        // Brand and editorial display
        static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let heroMetric = Font.system(.callout, design: .rounded).weight(.heavy)
        static let valueDisplay = Font.system(size: 34, weight: .bold, design: .serif)
        static let feedValue = Font.system(size: 20, weight: .heavy, design: .rounded)
        static let editorialLargeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
        static let editorialTitle = Font.system(.title, design: .serif).weight(.bold)
        static let editorialTitle2 = Font.system(.title2, design: .serif).weight(.bold)
        static let editorialTitle3 = Font.system(.title3, design: .serif).weight(.bold)
        static let editorialHeadline = Font.system(.headline, design: .serif).weight(.bold)

        // System hierarchy
        static let title = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title2Bold = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.medium)
        static let title3Semibold = Font.title3.weight(.semibold)
        static let title3Bold = Font.title3.weight(.bold)
        static let headline = Font.headline
        static let headlineSemibold = Font.headline.weight(.semibold)
        static let headlineBold = Font.headline.weight(.bold)
        static let body = Font.body
        static let bodySemibold = Font.body.weight(.semibold)
        static let callout = Font.callout
        static let calloutSemibold = Font.callout.weight(.semibold)
        static let subheadline = Font.subheadline
        static let subheadlineMedium = Font.subheadline.weight(.medium)
        static let subheadlineSemibold = Font.subheadline.weight(.semibold)
        static let subheadlineBold = Font.subheadline.weight(.bold)
        static let footnote = Font.footnote
        static let footnoteBold = Font.footnote.weight(.bold)
        static let caption = Font.caption
        static let captionMedium = Font.caption.weight(.medium)
        static let captionSemibold = Font.caption.weight(.semibold)
        static let captionBold = Font.caption.weight(.bold)
        static let caption2 = Font.caption2
        static let caption2Bold = Font.caption2.weight(.bold)

        static func programMark(containerSize: CGFloat) -> Font {
            .system(size: containerSize * 0.28, weight: .bold)
        }
    }

    enum Stroke {
        static let standard: CGFloat = 1
        static let emphasized: CGFloat = 1.2
        static let selected: CGFloat = 1.5
    }

    enum Size {
        static let minimumTouchTarget: CGFloat = 44
    }

    enum Opacity {
        static let shadow = 0.04
        static let subtle = 0.10
        static let soft = 0.12
        static let softStrong = 0.13
        static let selected = 0.14
        static let muted = 0.24
        static let mutedStrong = 0.26
        static let medium = 0.28
        static let border = 0.34
        static let selectedBorder = 0.72
    }

    fileprivate static func adaptive(
        light: (UInt8, UInt8, UInt8),
        dark: (UInt8, UInt8, UInt8)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            rgbUIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    fileprivate static func rgb(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Color {
        Color(uiColor: rgbUIColor((red, green, blue)))
    }

    private static func rgbUIColor(_ rgb: (UInt8, UInt8, UInt8)) -> UIColor {
        UIColor(
            red: CGFloat(rgb.0) / 255,
            green: CGFloat(rgb.1) / 255,
            blue: CGFloat(rgb.2) / 255,
            alpha: 1
        )
    }
}

extension View {
    /// Expands the interactive layout without scaling the control's visible content.
    func minimumTouchTarget(_ minimumSize: CGFloat = DesignTokens.Size.minimumTouchTarget) -> some View {
        frame(minWidth: minimumSize, minHeight: minimumSize)
            .contentShape(Rectangle())
    }
}
