import SwiftUI

struct CompactRateSummary: View {
    let rate: StoreEarningRate

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
            Text(rate.method.name)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: DesignTokens.Spacing.medium)

            Text(rate.rateLabel)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct BaseEarningSummaryCard: View {
    let rates: [StoreEarningRate]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            Text("DOKUMENTERT OPPTJENING")
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.2)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)

            Text("Vanlig opptjening")
                .font(DesignTokens.Typography.editorialTitle2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ForEach(rates) { rate in
                CompactRateSummary(rate: rate)
            }

            Text("Ingen trygg kombinasjon er bekreftet ennå.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.recommendationBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                .stroke(LovableStoreStyle.primaryBorder, lineWidth: DesignTokens.Stroke.emphasized)
        }
        .accessibilityElement(children: .contain)
    }
}

struct CompactEarningMethodRow: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.openURL) private var openURL

    let rate: StoreEarningRate
    let storeID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
                Text(rate.method.name)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Text(rate.rateLabel)
                    .font(DesignTokens.Typography.subheadlineBold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let requirement = rate.requirementSummary, !requirement.isEmpty {
                Text(TextListNormalizer.firstSentence(from: requirement))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let warningText = rate.warningText, !warningText.isEmpty {
                Label(TextListNormalizer.firstSentence(from: warningText), systemImage: "info.circle")
                    .font(DesignTokens.Typography.captionSemibold)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let handoffURL = rate.handoffURL {
                Button {
                    environment.track(.init(
                        name: "external_destination_opened",
                        surface: "store_detail",
                        entityType: "store_earning_rate",
                        entityID: rate.id,
                        properties: [
                            "store_id": storeID.uuidString,
                            "destination_type": rate.method.name
                        ]
                    ))
                    openURL(handoffURL)
                } label: {
                    Label("Start via \(rate.method.name)", systemImage: "arrow.up.right.square")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .frame(minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .minimumTouchTarget()
                .accessibilityHint("Åpner \(rate.method.name) eksternt.")
            }
        }
        .padding(.vertical, DesignTokens.Spacing.standard)
        .accessibilityElement(children: .contain)
    }
}

struct EmptyBestOpportunityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            Text("BESTE DOKUMENTERTE MULIGHET")
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.6)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)

            Text("Ingen trygg kombinasjon ennå")
                .font(DesignTokens.Typography.editorialTitle2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Ingen anbefalt kombinasjon er bekreftet for denne butikken ennå. Bruk vanlig opptjening og aktive kampanjer som separate valg.")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.recommendationBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.hero, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.hero, style: .continuous)
                .stroke(LovableStoreStyle.primaryBorder, lineWidth: DesignTokens.Stroke.emphasized)
        }
    }
}

struct LovablePrimaryButtonLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.mediumPlus) {
            Text(title)
            Image(systemName: "arrow.right")
                .font(DesignTokens.Typography.subheadlineBold)
        }
        .font(DesignTokens.Typography.headlineSemibold)
        .foregroundStyle(DesignTokens.Colors.textOnStrongColor)
        .padding(.vertical, DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.brandPrimaryButton)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
    }
}

struct DisclosureToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct LovableSectionHeading: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(eyebrow)
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.6)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(title)
                .font(DesignTokens.Typography.editorialTitle2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReferenceRateCard: View {
    let rate: StoreEarningRate

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                Text(rate.method.name)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                if let checkedAt = rate.checkedAt {
                    Label("Sist kontrollert \(checkedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Text(rate.rateLabel)
                .font(DesignTokens.Typography.subheadlineBold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CurrentCampaignCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
                Text(rate.method.name)
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Text(rate.rateLabel)
                    .font(DesignTokens.Typography.headlineBold)
                    .foregroundStyle(DesignTokens.Colors.warning)
                    .multilineTextAlignment(.trailing)
            }

            if let normalRateLabel = rate.normalRateLabel {
                Text("Normalt: \(normalRateLabel)")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            if let valueSummary = rate.valueSummary {
                Text(valueSummary)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.card) {
                    campaignMeta
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    campaignMeta
                }
            }
            .font(DesignTokens.Typography.captionSemibold)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.campaignBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                .stroke(LovableStoreStyle.campaignBorder, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var campaignMeta: some View {
        if let endsAt = rate.endsAt {
            Text("Gyldig til \(endsAt.formatted(date: .abbreviated, time: .omitted))")
                .foregroundStyle(LovableStoreStyle.expiryText)
        }

        if let checkedAt = rate.checkedAt {
            Label("Sist kontrollert \(checkedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }
}

struct EarningMethodCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.mediumPlus) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.controlGap) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                    Text(rate.method.name)
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)

                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.compact) {
                        Text(rate.rateLabel)
                            .font(DesignTokens.Typography.title3Bold)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        if let normalRateLabel = rate.normalRateLabel {
                            Text("(normalt \(normalRateLabel))")
                                .font(DesignTokens.Typography.subheadline)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DesignTokens.Spacing.medium)

                Text(programBadge)
                    .font(DesignTokens.Typography.caption2Bold)
                    .padding(.horizontal, DesignTokens.Spacing.mediumPlus)
                    .padding(.vertical, DesignTokens.Spacing.compact)
                    .background(DesignTokens.Colors.brandPrimarySoft)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)
                    .clipShape(Capsule())
            }

            if let disclosurePreview {
                Text(disclosurePreview)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if rate.warningText != nil {
                Label("Vilkår gjelder", systemImage: "info.circle")
                    .font(DesignTokens.Typography.captionSemibold)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)
            }

            if let checkedAt = rate.checkedAt {
                Label("Sist kontrollert \(checkedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .contain)
    }

    private var programBadge: String {
        let methodName = rate.method.name.localizedLowercase
        if methodName.contains("trumf") {
            return "Trumf"
        }
        if methodName.contains("eurobonus") || methodName.contains("sas") {
            return "EuroBonus"
        }
        return rate.method.type.displayName
    }

    private var disclosurePreview: String? {
        if let requirementSummary = rate.requirementSummary, !requirementSummary.isEmpty {
            return TextListNormalizer.firstSentence(from: requirementSummary)
        }

        if let warningText = rate.warningText, !warningText.isEmpty {
            return TextListNormalizer.firstSentence(from: warningText)
        }

        return nil
    }
}

struct RecommendationExplanation: View {
    @State private var isDetailDisclosureExpanded = false

    let combination: EarningCombination
    let rates: [StoreEarningRate]
    let lastVerifiedAt: Date?
    let sourceFormatter: (URL) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            Text("Derfor anbefaler vi denne")
                .font(DesignTokens.Typography.editorialTitle3)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
                ForEach(rates) { rate in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
                        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.controlGap) {
                            Text(rate.method.name)
                                .font(DesignTokens.Typography.subheadlineSemibold)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: DesignTokens.Spacing.medium)

                            Text(rate.rateLabel)
                                .font(DesignTokens.Typography.subheadlineBold)
                                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                                .multilineTextAlignment(.trailing)
                        }

                        if let sourceTitle = rate.sourceTitle {
                            Text("Kilde: \(sourceTitle)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }

                if rates.count > 1 {
                    Divider()

                    HStack(alignment: .firstTextBaseline) {
                        Text("Totalt")
                            .font(DesignTokens.Typography.subheadlineSemibold)

                        Spacer()

                        Text(combination.totalValueLabel)
                            .font(DesignTokens.Typography.subheadlineBold)
                            .foregroundStyle(DesignTokens.Colors.brandPrimary)
                    }
                }
            }

            let requirements = requirementTexts
            if !requirements.isEmpty {
                ExplanationList(title: "Krav", items: requirements, systemImage: "checkmark.circle")
            }

            let terms = ExplanationTextBuckets(requirements: requirements, warnings: warningTexts)

            if !terms.importantItems.isEmpty {
                ExplanationList(title: "Viktig", items: terms.importantItems, systemImage: "exclamationmark.triangle")
            }

            Text(recommendationReason)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let lastVerifiedAt {
                Label("Sist kontrollert \(lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            let links = sourceLinks
            if !terms.calculationItems.isEmpty || !links.isEmpty {
                DisclosureGroup(isExpanded: $isDetailDisclosureExpanded) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                        if !terms.calculationItems.isEmpty {
                            ExplanationList(title: "Beregning", items: terms.calculationItems, systemImage: "equal.circle")
                        }

                        if !links.isEmpty {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                                Text("Kilder")
                                    .font(DesignTokens.Typography.captionBold)
                                    .tracking(2.2)
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                                ForEach(links, id: \.self) { url in
                                    Link(destination: url) {
                                        Label(sourceFormatter(url), systemImage: "arrow.up.right.square")
                                            .font(DesignTokens.Typography.subheadlineSemibold)
                                            .foregroundStyle(DesignTokens.Colors.brandPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .minimumTouchTarget()
                                }
                            }
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.medium)
                } label: {
                    Text("Se beregning og kilder")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                }
                .minimumTouchTarget()
            }
        }
        .padding(DesignTokens.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.largeCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.largeCard, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .contain)
    }

    private var requirementTexts: [String] {
        TextListNormalizer.unique(rates.compactMap(\.requirementSummary).filter { !$0.isEmpty })
    }

    private var warningTexts: [String] {
        let rateWarnings = rates.compactMap(\.warningText).filter { !$0.isEmpty }
        guard let combinationWarning = combination.warningText, !combinationWarning.isEmpty else {
            return TextListNormalizer.unique(rateWarnings)
        }
        return TextListNormalizer.unique(rateWarnings + [combinationWarning])
    }

    private var sourceLinks: [URL] {
        Array(Set(rates.compactMap { $0.sourceURL ?? $0.handoffURL }))
            .sorted { $0.absoluteString < $1.absoluteString }
    }

    private var recommendationReason: String {
        if rates.count > 1 {
            return "Dette er den beste dokumenterte kombinasjonen vi kjenner til akkurat nå. Portalopptjeningen registreres på klikket fra portalen, mens kortopptjeningen følger betalingskortet. Mekanismene er derfor vurdert som kombinerbare."
        }

        return "Dette er den beste dokumenterte muligheten vi kjenner til akkurat nå. Kontroller alltid vilkårene hos tilbyderen før bruk."
    }
}

struct ExplanationList: View {
    let title: String
    let items: [String]
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(title.uppercased())
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: DesignTokens.Spacing.medium) {
                    Text("•")
                        .accessibilityHidden(true)

                    Text(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
        }
    }
}

struct StoreNoticeCard: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color
    let background: Color
    let border: Color

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.controlGap) {
            Image(systemName: systemImage)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(tint)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(title)
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(tint)

                Text(text)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExplanationTextBuckets {
    let importantItems: [String]
    let calculationItems: [String]

    init(requirements: [String], warnings: [String]) {
        let requirementSentences = Set(
            requirements
                .flatMap(TextListNormalizer.sentences)
                .map(TextListNormalizer.key)
        )
        let warningSentences = warnings
            .flatMap(TextListNormalizer.sentences)
            .filter { !requirementSentences.contains(TextListNormalizer.key($0)) }

        calculationItems = TextListNormalizer.unique(
            warningSentences.filter(Self.isCalculation)
        )
        importantItems = TextListNormalizer.unique(
            warningSentences.filter { !Self.isCalculation($0) }
        )
    }

    private static func isCalculation(_ text: String) -> Bool {
        let normalized = text.localizedLowercase
        return normalized.contains("beregningen")
            || normalized.contains("trumf-krone")
            || normalized.contains("automatisk overføring")
            || normalized.contains("engangsoverføring")
    }
}

enum TextListNormalizer {
    static func unique(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { item in
            let normalizedKey = key(item)
            guard !seen.contains(normalizedKey) else { return false }
            seen.insert(normalizedKey)
            return true
        }
    }

    static func sentences(from text: String) -> [String] {
        text
            .split(separator: ".", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? $0 : "\($0)." }
    }

    static func firstSentence(from text: String) -> String {
        sentences(from: text).first ?? text
    }

    static func key(_ text: String) -> String {
        text
            .localizedLowercase
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
    }
}

struct EmptyStoreDetailCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.subheadline)
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .padding(DesignTokens.Spacing.screen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LovableStoreStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                    .stroke(LovableStoreStyle.border, lineWidth: DesignTokens.Stroke.standard)
            }
    }
}

enum LovableStoreStyle {
    static let primary = DesignTokens.Colors.brandPrimary
    static let primaryBorder = DesignTokens.Colors.brandPrimaryBorder
    static let border = DesignTokens.Colors.border
    static let expiryText = DesignTokens.Colors.expiryText
    static let campaignBorder = DesignTokens.Colors.campaignBorder
    static let pageBackground = DesignTokens.Colors.storePageBackground
    static let cardBackground = DesignTokens.Colors.storeCardBackground
    static let recommendationBackground = DesignTokens.Colors.recommendationBackground
    static let campaignBackground = DesignTokens.Colors.campaignBackground
    static let warningBackground = DesignTokens.Colors.cautionBackground
    static let noticeTint = DesignTokens.Colors.noticeText
    static let noticeBorder = DesignTokens.Colors.noticeBorder
    static let noticeBackground = DesignTokens.Colors.noticeBackground
}

extension EarningMethod.MethodType {
    var displayName: String {
        switch self {
        case .portal:
            return "Portal"
        case .card:
            return "Kort"
        case .loyalty:
            return "Program"
        case .campaign:
            return "Kampanje"
        case .manual:
            return "Manuell"
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: SampleData.stores[0])
            .environment(AppEnvironment.mock())
    }
}

