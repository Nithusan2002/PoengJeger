import SwiftUI

struct StoreDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isRecommendationExpanded = false
    @State private var isFavorite = false

    let store: Store

    private var publishedRates: [StoreEarningRate] {
        store.sortedEarningRates.filter { $0.status == .published }
    }

    private var selectedProgramIDs: Set<UUID> {
        environment.selectedFirstPhaseProgramIDs
    }

    private var preferredCombination: EarningCombination? {
        store.bestCombination(for: selectedProgramIDs)
    }

    private var bestRateIDs: Set<UUID> {
        Set(preferredCombination?.rateIDs ?? [])
    }

    private var primaryRates: [StoreEarningRate] {
        guard !selectedProgramIDs.isEmpty else { return publishedRates }
        let selectedRates = publishedRates.filter { $0.matchesSelectedPrograms(selectedProgramIDs) }
        return selectedRates.isEmpty ? publishedRates : selectedRates
    }

    private var secondaryRates: [StoreEarningRate] {
        guard !selectedProgramIDs.isEmpty else { return [] }
        return publishedRates.filter { !$0.matchesSelectedPrograms(selectedProgramIDs) }
    }

    private var activePromotions: [StoreEarningRate] {
        primaryRates
            .filter { !$0.isBaseRate && $0.isActive }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var bestOpportunityUsesPromotion: Bool {
        activePromotions.contains { bestRateIDs.contains($0.id) }
    }

    private var visibleReferenceRates: [StoreEarningRate] {
        let baseRates = primaryRates
            .filter(\.isBaseRate)
            .sorted { $0.sortOrder < $1.sortOrder }

        if bestOpportunityUsesPromotion {
            return baseRates
        }

        return baseRates.filter { !bestRateIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.none) {
            topBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
                    header
                    bestOpportunitySection
                    referenceRateSection
                    currentCampaignSection
                    allMethodsSection
                    otherMethodsSection
                    sourceSection
                }
                .padding(.horizontal, DesignTokens.Spacing.comfortable)
                .padding(.top, DesignTokens.Spacing.controlGap)
                .padding(.bottom, DesignTokens.Spacing.xxLarge)
            }
        }
        .background(LovableStoreStyle.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task(id: store.id) {
            isFavorite = environment.userSession.favoriteStoreIDs.contains(store.id)
            trackStoreDetailOpened()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    Image(systemName: "chevron.left")
                        .font(DesignTokens.Typography.subheadlineSemibold)

                    Text("Tilbake")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .minimumTouchTarget()
            .accessibilityLabel("Tilbake")

            Spacer()

            SaveToggleButton(
                isSaved: isFavorite,
                savedAccessibilityLabel: "Fjern butikk fra lagret",
                unsavedAccessibilityLabel: "Lagre butikk",
                action: toggleFavorite
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.comfortable)
        .padding(.top, DesignTokens.Spacing.medium)
        .padding(.bottom, DesignTokens.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.pageBackground)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.card) {
            StoreInitialMark(name: store.name)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text(store.name)
                    .font(DesignTokens.Typography.editorialTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(categoryLine)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer(minLength: DesignTokens.Spacing.none)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var bestOpportunitySection: some View {
        if let combination = preferredCombination {
            let includedRates = rates(in: combination)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                Text(bestCombinationEyebrow(for: combination))
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)

                Text(combination.totalValueLabel)
                    .font(DesignTokens.Typography.valueDisplay)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(TextListNormalizer.firstSentence(from: combination.summary))
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                bestOpportunityMeta(rates: includedRates, verifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt)

                NavigationLink {
                    HowToEarnView(store: store, combination: combination)
                } label: {
                    LovablePrimaryButtonLabel(title: "Slik gjør du det")
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    environment.track(.init(
                        name: "how_to_earn_opened",
                        surface: "store_detail",
                        entityType: "earning_combination",
                        entityID: combination.id,
                        properties: [
                            "store_id": store.id.uuidString,
                            "destination_type": handoffDestinationNameForDisclosure(combination),
                            "requires_warning": combination.warningText == nil ? "false" : "true"
                        ]
                    ))
                })

                Button {
                    withAnimation(recommendationDisclosureAnimation) {
                        isRecommendationExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Hvorfor er dette best?")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.down")
                            .font(DesignTokens.Typography.captionBold)
                            .foregroundStyle(DesignTokens.Colors.brandPrimary)
                            .rotationEffect(.degrees(isRecommendationExpanded ? 180 : 0))
                    }
                    .font(DesignTokens.Typography.subheadlineMedium)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.xxSmall)
                    .padding(.vertical, DesignTokens.Spacing.xSmall)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DisclosureToggleButtonStyle())
                .minimumTouchTarget()
                .animation(recommendationDisclosureAnimation, value: isRecommendationExpanded)

                if isRecommendationExpanded {
                    RecommendationExplanation(
                        combination: combination,
                        rates: includedRates,
                        lastVerifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt,
                        sourceFormatter: sourceDestinationName
                    )
                    .transition(recommendationExplanationTransition)
                }
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
        } else {
            EmptyBestOpportunityCard()
        }
    }

    private func bestOpportunityMeta(rates: [StoreEarningRate], verifiedAt: Date?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DesignTokens.Spacing.card) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }
        }
        .font(DesignTokens.Typography.captionSemibold)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func metaItems(rates: [StoreEarningRate], verifiedAt: Date?) -> some View {
        if let expiryText = expiryText(for: rates) {
            Text(expiryText)
                .foregroundStyle(LovableStoreStyle.expiryText)
        }

        if let verifiedAt {
            Label("Sist kontrollert \(shortDate(verifiedAt))", systemImage: "checkmark")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var referenceRateSection: some View {
        if !visibleReferenceRates.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                LovableSectionHeading(eyebrow: "REFERANSEPUNKT", title: "Vanlig opptjening")

                ForEach(visibleReferenceRates) { rate in
                    ReferenceRateCard(rate: rate)
                }
            }
        }
    }

    @ViewBuilder
    private var currentCampaignSection: some View {
        if !activePromotions.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                LovableSectionHeading(eyebrow: "AKTUELL KAMPANJE", title: "Akkurat nå")

                ForEach(activePromotions) { rate in
                    CurrentCampaignCard(rate: rate)
                }
            }
        }
    }

    @ViewBuilder
    private var allMethodsSection: some View {
        if primaryRates.count > 1 {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                LovableSectionHeading(
                    eyebrow: "OVERSIKT",
                    title: selectedProgramIDs.isEmpty ? "Alle opptjeningsmuligheter" : "Dine programmer først",
                    subtitle: "EuroBonus og Trumf vises hver for seg - vi blander ikke bonusvalutaene."
                )

                ForEach(primaryRates) { rate in
                    EarningMethodCard(rate: rate)
                }
            }
        }
    }

    @ViewBuilder
    private var otherMethodsSection: some View {
        if !secondaryRates.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                LovableSectionHeading(
                    eyebrow: "ANDRE MULIGHETER",
                    title: "Ikke valgt program",
                    subtitle: "Disse er dokumentert, men ligger utenfor programmene du har valgt i Profil."
                )

                ForEach(secondaryRates) { rate in
                    EarningMethodCard(rate: rate)
                }
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
            Text("KILDE OG KONTROLL")
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text("Opptjening og beste valg er bekreftet og vurdert. Kontroller alltid satsen i portalen før kjøp.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.lastVerifiedAt.map { "Sist kontrollert \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))." } ?? "Kontrolltidspunkt mangler.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.top, DesignTokens.Spacing.xxSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryLine: String {
        if let categoryName = store.category?.name {
            return categoryName
        }

        return "Butikk"
    }

    private func rates(in combination: EarningCombination) -> [StoreEarningRate] {
        combination.rateIDs.compactMap { rateID in
            store.earningRates.first { $0.id == rateID && $0.status == .published }
        }
    }

    private func bestCombinationEyebrow(for combination: EarningCombination) -> String {
        if !selectedProgramIDs.isEmpty && !combinationUsesSelectedPrograms(combination) {
            return "ANNEN DOKUMENTERT MULIGHET"
        }

        return combination.rateIDs.count > 1 ? "BESTE KOMBINASJON" : "BESTE DOKUMENTERTE MULIGHET"
    }

    private func combinationUsesSelectedPrograms(_ combination: EarningCombination) -> Bool {
        guard !selectedProgramIDs.isEmpty else { return true }
        let programIDs = Set(rates(in: combination).compactMap(\.method.programID))
        return !programIDs.isEmpty && programIDs.isSubset(of: selectedProgramIDs)
    }

    private func expiryText(for rates: [StoreEarningRate]) -> String? {
        let expiryDates = rates.compactMap(\.endsAt).sorted()
        guard let firstExpiry = expiryDates.first else { return nil }
        return "Gyldig til \(shortDate(firstExpiry))"
    }

    private func sourceDestinationName(for url: URL) -> String {
        let host = url.host()?.localizedLowercase ?? ""
        if host.contains("trumf") {
            return "Trumf"
        }
        if host.contains("sas") || host.contains("eurobonus") {
            return "EuroBonus Shopping"
        }
        return url.host() ?? "Kilde"
    }

    private func handoffDestinationNameForDisclosure(_ combination: EarningCombination) -> String {
        guard let url = combination.primaryHandoffURL else { return "riktig portal" }

        if let matchingRate = store.earningRates.first(where: { $0.handoffURL == url }) {
            return matchingRate.method.name
        }

        return sourceDestinationName(for: url)
    }

    private var recommendationDisclosureAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.34, dampingFraction: 0.86)
    }

    private var recommendationExplanationTransition: AnyTransition {
        if accessibilityReduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity
                .combined(with: .move(edge: .top))
                .combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity
                .combined(with: .scale(scale: 0.98, anchor: .top))
        )
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .locale(Locale(identifier: "nb_NO"))
        )
    }

    private func trackStoreDetailOpened() {
        let programIDs = Set(primaryRates.compactMap(\.method.programID))
        environment.track(.init(
            name: "store_detail_opened",
            surface: "store_detail",
            entityType: "store",
            entityID: store.id,
            properties: [
                "program_ids": programIDs.map(\.uuidString).sorted().joined(separator: ","),
                "program_count": "\(programIDs.count)",
                "has_active_campaign": activePromotions.isEmpty ? "false" : "true",
                "has_best_combination": preferredCombination == nil ? "false" : "true",
                "uses_selected_program": preferredCombination.map { combinationUsesSelectedPrograms($0) ? "true" : "false" } ?? "false"
            ]
        ))

        if let bestCombination = preferredCombination {
            let bestProgramIDs = Set(rates(in: bestCombination).compactMap(\.method.programID))
            environment.track(.init(
                name: "best_combination_viewed",
                surface: "store_detail",
                entityType: "earning_combination",
                entityID: bestCombination.id,
                properties: [
                    "store_id": store.id.uuidString,
                    "program_ids": bestProgramIDs.map(\.uuidString).sorted().joined(separator: ","),
                    "mechanism_count": "\(bestCombination.rateIDs.count)"
                ]
            ))
        }
    }

    private func toggleFavorite() {
        if isFavorite {
            isFavorite = false
            environment.userSession.favoriteStoreIDs.remove(store.id)
            environment.track(.init(
                name: "favorite_removed",
                surface: "store_detail",
                entityType: "store",
                entityID: store.id,
                properties: ["favorite_type": "store"]
            ))
        } else {
            isFavorite = true
            environment.userSession.favoriteStoreIDs.insert(store.id)
            environment.track(.init(
                name: "favorite_added",
                surface: "store_detail",
                entityType: "store",
                entityID: store.id,
                properties: ["favorite_type": "store"]
            ))
        }
    }
}

private struct EmptyBestOpportunityCard: View {
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

private struct LovablePrimaryButtonLabel: View {
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

private struct DisclosureToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct LovableSectionHeading: View {
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

private struct ReferenceRateCard: View {
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

private struct CurrentCampaignCard: View {
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

private struct EarningMethodCard: View {
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

private struct RecommendationExplanation: View {
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

private struct ExplanationList: View {
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

private struct StoreNoticeCard: View {
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

private struct ExplanationTextBuckets {
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

private enum TextListNormalizer {
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

private struct EmptyStoreDetailCard: View {
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

private enum LovableStoreStyle {
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

private extension EarningMethod.MethodType {
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
