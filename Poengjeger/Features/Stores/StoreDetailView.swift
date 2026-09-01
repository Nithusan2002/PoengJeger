import SwiftUI

struct StoreDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
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
        VStack(spacing: 0) {
            topBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 30) {
                    header
                    bestOpportunitySection
                    referenceRateSection
                    currentCampaignSection
                    allMethodsSection
                    otherMethodsSection
                    actionSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .background(LovableStoreStyle.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: EarningCombination.self) { combination in
            HowToEarnView(store: store, combination: combination)
        }
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
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))

                    Text("Tilbake")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tilbake")

            Spacer()

            SaveToggleButton(
                isSaved: isFavorite,
                savedAccessibilityLabel: "Fjern butikk fra lagret",
                unsavedAccessibilityLabel: "Lagre butikk",
                action: toggleFavorite
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.pageBackground)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            StoreInitialMark(name: store.name)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(store.name)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(categoryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let lastVerifiedAt = store.lastVerifiedAt {
                    Label("Sist kontrollert \(shortDate(lastVerifiedAt))", systemImage: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var bestOpportunitySection: some View {
        if let combination = preferredCombination {
            let includedRates = rates(in: combination)

            VStack(alignment: .leading, spacing: 14) {
                Text(bestCombinationEyebrow(for: combination))
                    .font(.caption.weight(.bold))
                    .tracking(2.6)
                    .foregroundStyle(PoengjegerTheme.primary)

                Text(combination.totalValueLabel)
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(TextListNormalizer.firstSentence(from: combination.summary))
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                bestOpportunityMeta(rates: includedRates, verifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt)

                NavigationLink(value: combination) {
                    LovablePrimaryButtonLabel(title: "Slik gjør du det")
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    environment.track(.init(
                        name: "handoff_opened",
                        surface: "store_detail",
                        entityType: "earning_combination",
                        entityID: combination.id,
                        properties: ["store_id": store.id.uuidString]
                    ))
                })

                Button {
                    withAnimation(.snappy) {
                        isRecommendationExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Hvorfor er dette best?")
                        Image(systemName: isRecommendationExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(isRecommendationExpanded ? LovableStoreStyle.warningBackground : LovableStoreStyle.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LovableStoreStyle.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                if isRecommendationExpanded {
                    RecommendationExplanation(
                        combination: combination,
                        rates: includedRates,
                        lastVerifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt,
                        sourceFormatter: sourceDestinationName
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LovableStoreStyle.recommendationBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LovableStoreStyle.primaryBorder, lineWidth: 1.2)
            }
            .accessibilityElement(children: .contain)
        } else {
            EmptyBestOpportunityCard()
        }
    }

    private func bestOpportunityMeta(rates: [StoreEarningRate], verifiedAt: Date?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }

            VStack(alignment: .leading, spacing: 8) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }
        }
        .font(.caption.weight(.semibold))
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
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var referenceRateSection: some View {
        if !visibleReferenceRates.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
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
            VStack(alignment: .leading, spacing: 12) {
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
            VStack(alignment: .leading, spacing: 12) {
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
            VStack(alignment: .leading, spacing: 12) {
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

    @ViewBuilder
    private var actionSection: some View {
        if let combination = preferredCombination {
            VStack(alignment: .leading, spacing: 14) {
                LovableSectionHeading(eyebrow: "HANDLING", title: "Slik gjør du det")

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(combination.steps.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { index, step in
                        StoreActionStepRow(index: index + 1, text: step.text)
                    }

                    if let warningText = combination.warningText {
                        StoreNoticeCard(
                            title: "Viktig før kjøp",
                            text: warningText,
                            systemImage: "exclamationmark.triangle",
                            tint: LovableStoreStyle.noticeTint,
                            background: LovableStoreStyle.noticeBackground,
                            border: LovableStoreStyle.noticeBorder
                        )
                        .padding(.horizontal, 14)
                        .padding(.top, 6)
                    }

                    NavigationLink(value: combination) {
                        LovablePrimaryButtonLabel(title: "Start handelen")
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .simultaneousGesture(TapGesture().onEnded {
                        environment.track(.init(
                            name: "handoff_opened",
                            surface: "store_detail_action",
                            entityType: "earning_combination",
                            entityID: combination.id,
                            properties: ["store_id": store.id.uuidString]
                        ))
                    })

                    Text("Du sendes videre til \(handoffDestinationNameForDisclosure(combination)). Lenken kan gi Poengjeger provisjon. Den påvirker verken rangeringen eller hva vi anbefaler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 16)
                }
                .background(LovableStoreStyle.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LovableStoreStyle.border, lineWidth: 1)
                }
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KILDE OG KONTROLL")
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text("Opptjening og beste valg er redaksjonelt kvalitetssikret. Kontroller alltid satsen i portalen før kjøp.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.lastVerifiedAt.map { "Sist kontrollert \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))." } ?? "Kontrolltidspunkt mangler.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
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
                "program_count": "\(programIDs.count)",
                "has_active_campaign": activePromotions.isEmpty ? "false" : "true",
                "has_best_combination": preferredCombination == nil ? "false" : "true",
                "uses_selected_program": preferredCombination.map { combinationUsesSelectedPrograms($0) ? "true" : "false" } ?? "false"
            ]
        ))

        if let bestCombination = preferredCombination {
            environment.track(.init(
                name: "best_combination_viewed",
                surface: "store_detail",
                entityType: "earning_combination",
                entityID: bestCombination.id,
                properties: [
                    "store_id": store.id.uuidString,
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
        VStack(alignment: .leading, spacing: 12) {
            Text("BESTE DOKUMENTERTE MULIGHET")
                .font(.caption.weight(.bold))
                .tracking(2.6)
                .foregroundStyle(PoengjegerTheme.primary)

            Text("Ingen trygg kombinasjon ennå")
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text("Redaksjonen har ikke publisert en anbefalt kombinasjon for denne butikken. Bruk vanlig opptjening og aktive kampanjer som separate valg.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.recommendationBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LovableStoreStyle.primaryBorder, lineWidth: 1.2)
        }
    }
}

private struct LovablePrimaryButtonLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 9) {
            Text(title)
            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.bold))
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(LovableStoreStyle.primary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct LovableSectionHeading: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(2.6)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReferenceRateCard: View {
    let rate: StoreEarningRate

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(rate.method.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let checkedAt = rate.checkedAt {
                    Label("Sist kontrollert \(checkedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(rate.rateLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CurrentCampaignCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(rate.method.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(rate.rateLabel)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.warning)
                    .multilineTextAlignment(.trailing)
            }

            if let normalRateLabel = rate.normalRateLabel {
                Text("Normalt: \(normalRateLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let valueSummary = rate.valueSummary {
                Text(valueSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    campaignMeta
                }

                VStack(alignment: .leading, spacing: 8) {
                    campaignMeta
                }
            }
            .font(.caption.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.campaignBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LovableStoreStyle.campaignBorder, lineWidth: 1)
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
                .foregroundStyle(.secondary)
        }
    }
}

private struct EarningMethodCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(rate.method.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(rate.rateLabel)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        if let normalRateLabel = rate.normalRateLabel {
                            Text("(normalt \(normalRateLabel))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(programBadge)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(PoengjegerTheme.primarySoft)
                    .foregroundStyle(PoengjegerTheme.primary)
                    .clipShape(Capsule())
            }

            if let disclosurePreview {
                Text(disclosurePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if rate.warningText != nil {
                Label("Vilkår gjelder", systemImage: "info.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.primary)
            }

            if let checkedAt = rate.checkedAt {
                Label("Sist kontrollert \(checkedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Derfor anbefaler vi denne")
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rates) { rate in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(rate.method.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            Text(rate.rateLabel)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PoengjegerTheme.primary)
                                .multilineTextAlignment(.trailing)
                        }

                        if let sourceTitle = rate.sourceTitle {
                            Text("Kilde: \(sourceTitle)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if rates.count > 1 {
                    Divider()

                    HStack(alignment: .firstTextBaseline) {
                        Text("Totalt")
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text(combination.totalValueLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PoengjegerTheme.primary)
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let lastVerifiedAt {
                Label("Sist kontrollert \(lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let links = sourceLinks
            if !terms.calculationItems.isEmpty || !links.isEmpty {
                DisclosureGroup(isExpanded: $isDetailDisclosureExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !terms.calculationItems.isEmpty {
                            ExplanationList(title: "Beregning", items: terms.calculationItems, systemImage: "equal.circle")
                        }

                        if !links.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kilder")
                                    .font(.caption.weight(.bold))
                                    .tracking(2.2)
                                    .foregroundStyle(.secondary)

                                ForEach(links, id: \.self) { url in
                                    Link(destination: url) {
                                        Label(sourceFormatter(url), systemImage: "arrow.up.right.square")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(PoengjegerTheme.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Se beregning og kilder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LovableStoreStyle.border, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .accessibilityHidden(true)

                    Text(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
                .foregroundStyle(.primary)
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(tint)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(border, lineWidth: 1)
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

private struct StoreActionStepRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)
                .frame(width: 28, height: 28)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Steg \(index). \(text)")
    }
}

private struct EmptyStoreDetailCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LovableStoreStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LovableStoreStyle.border, lineWidth: 1)
            }
    }
}

private enum LovableStoreStyle {
    static let primary = PoengjegerTheme.primary
    static let primaryBorder = PoengjegerTheme.primaryBorder
    static let border = PoengjegerTheme.border
    static let expiryText = Color(red: 0.62, green: 0.31, blue: 0.09)
    static let campaignBorder = Color(red: 0.89, green: 0.72, blue: 0.58)

    static let pageBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.06, green: 0.07, blue: 0.06, alpha: 1)
        }

        return UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1)
    })

    static let cardBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.11, green: 0.13, blue: 0.12, alpha: 1)
        }

        return UIColor.white
    })

    static let recommendationBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.10, green: 0.13, blue: 0.11, alpha: 1)
        }

        return UIColor(red: 0.97, green: 0.98, blue: 0.96, alpha: 1)
    })

    static let campaignBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.17, green: 0.11, blue: 0.07, alpha: 1)
        }

        return UIColor(red: 1.00, green: 0.97, blue: 0.93, alpha: 1)
    })

    static let warningBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.23, green: 0.18, blue: 0.10, alpha: 1)
        }

        return UIColor(red: 0.96, green: 0.90, blue: 0.78, alpha: 1)
    })
    static let noticeTint = Color(red: 0.55, green: 0.34, blue: 0.08)
    static let noticeBorder = Color(red: 0.86, green: 0.75, blue: 0.53)
    static let noticeBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.16, blue: 0.09, alpha: 1)
        }

        return UIColor(red: 0.98, green: 0.93, blue: 0.80, alpha: 1)
    })
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
