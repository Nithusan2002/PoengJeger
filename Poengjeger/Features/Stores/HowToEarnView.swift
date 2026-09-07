import SwiftUI

struct HowToEarnView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.openURL) private var openURL
    @State private var isDetailDisclosureExpanded = false

    let store: Store
    let combination: EarningCombination

    private var sortedSteps: [EarningCombinationStep] {
        combination.steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
                header

                stepsSection

                compactNotice

                handoffButton

                compactHandoffDisclosure

                detailDisclosure
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.standard)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Slik gjør du det")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
        .task(id: combination.id) {
            environment.track(.init(
                name: "how_to_earn_opened",
                surface: "how_to_earn",
                entityType: "earning_combination",
                entityID: combination.id,
                properties: [
                    "store_id": store.id.uuidString,
                    "requires_warning": combination.warningText == nil ? "false" : "true"
                ]
            ))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
                StoreInitialMark(name: store.name)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text(store.name)
                        .font(DesignTokens.Typography.headlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(store.category?.name ?? "Butikk")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                Text(combination.rateIDs.count > 1 ? "BESTE KOMBINASJON" : "BESTE DOKUMENTERTE MULIGHET")
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)

                Text(combination.totalValueLabel)
                    .font(DesignTokens.Typography.valueDisplay)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(combination.summary)
                    .lineLimit(2)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.brandPrimaryBorder, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("HANDLING")
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("Følg stegene i rekkefølge")
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            if sortedSteps.isEmpty {
                ContentUnavailableView(
                    "Stegene mangler",
                    systemImage: "list.number",
                    description: Text("Handelssteg må bekreftes før denne kombinasjonen kan brukes.")
                )
            } else {
                VStack(spacing: DesignTokens.Spacing.none) {
                    ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                        StepInstructionRow(index: index + 1, text: step.text)

                        if step.id != sortedSteps.last?.id {
                            Divider()
                                .padding(.leading, DesignTokens.Spacing.searchLeadingInset)
                        }
                    }
                }
                .background(DesignTokens.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                        .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                }
            }
        }
    }

    @ViewBuilder
    private var compactNotice: some View {
        if let importantNotice = noticeBuckets?.importantItems.first {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.controlGap) {
                Image(systemName: "exclamationmark.triangle")
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(HowToEarnNoticeStyle.tint)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(importantNotice)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HowToEarnNoticeStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                    .stroke(HowToEarnNoticeStyle.border, lineWidth: DesignTokens.Stroke.standard)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var detailDisclosure: some View {
        DisclosureGroup(isExpanded: $isDetailDisclosureExpanded) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                if let buckets = noticeBuckets {
                    if !buckets.importantItems.isEmpty {
                        detailList(title: "Vilkår", items: buckets.importantItems)
                    }

                    if !buckets.calculationItems.isEmpty {
                        detailList(title: "Beregning", items: buckets.calculationItems)
                    }
                }

                handoffDisclosure
            }
            .padding(.top, DesignTokens.Spacing.controlGap)
        } label: {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: "info.circle")
                    .accessibilityHidden(true)

                Text("Se beregning og vilkår")
                    .font(DesignTokens.Typography.subheadlineSemibold)
            }
            .foregroundStyle(DesignTokens.Colors.brandPrimary)
        }
        .padding(DesignTokens.Spacing.card)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .minimumTouchTarget()
    }

    private func detailList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title.uppercased())
                .font(DesignTokens.Typography.captionBold)
                .tracking(1.4)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var handoffButton: some View {
        if sortedSteps.isEmpty {
            EmptyView()
        } else if let url = combination.primaryHandoffURL {
            Button {
                var properties = [
                    "store_id": store.id.uuidString,
                    "destination_type": handoffDestinationName(for: url)
                ]

                if let programID = primaryHandoffProgramID(for: url) {
                    properties["program_id"] = programID.uuidString
                }

                environment.track(.init(
                    name: "external_destination_opened",
                    surface: "how_to_earn",
                    entityType: "earning_combination",
                    entityID: combination.id,
                    properties: properties
                ))
                openURL(url)
            } label: {
                Label("Start handelen", systemImage: "arrow.up.forward.app.fill")
                    .font(DesignTokens.Typography.headlineSemibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(DesignTokens.Colors.brandPrimaryButton)
            .accessibilityHint("Åpner \(handoffDestinationName(for: url)) eksternt.")
        } else {
            ContentUnavailableView(
                "Ingen handoff-lenke ennå",
                systemImage: "link.badge.plus",
                description: Text("Riktig portal må bekreftes før direkte handoff kan brukes.")
            )
        }
    }

    private func primaryHandoffProgramID(for url: URL) -> UUID? {
        let combinationRateIDs = Set(combination.rateIDs)
        return store.earningRates.first { rate in
            combinationRateIDs.contains(rate.id) && rate.handoffURL == url
        }?.method.programID
    }

    @ViewBuilder
    private var handoffDisclosure: some View {
        if combination.primaryHandoffURL != nil {
            VStack(alignment: .center, spacing: DesignTokens.Spacing.small) {
                Text("Du sendes videre til \(handoffDestinationNameForDisclosure).")

            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignTokens.Spacing.controlGap)
        }
    }

    @ViewBuilder
    private var compactHandoffDisclosure: some View {
        if combination.primaryHandoffURL != nil && !sortedSteps.isEmpty {
            Text("Lenken kan gi Poengjeger provisjon.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DesignTokens.Spacing.controlGap)
        }
    }

    private var noticeBuckets: HowToEarnNoticeBuckets? {
        guard let warningText = combination.warningText, !warningText.isEmpty else {
            return nil
        }

        return HowToEarnNoticeBuckets(text: warningText)
    }

    private var handoffDestinationNameForDisclosure: String {
        guard let url = combination.primaryHandoffURL else { return "riktig portal" }
        return handoffDestinationName(for: url)
    }

    private func handoffDestinationName(for url: URL) -> String {
        if let matchingRate = store.earningRates.first(where: { $0.handoffURL == url }) {
            return matchingRate.method.name
        }

        let host = url.host()?.localizedLowercase ?? ""
        if host.contains("sas") {
            return "EuroBonus Shopping"
        }
        if host.contains("trumf") {
            return "Trumf"
        }

        return store.name
    }
}

private struct StepInstructionRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
            Text("\(index)")
                .font(DesignTokens.Typography.captionBold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .frame(width: 26, height: 26)
                .background(DesignTokens.Colors.brandPrimarySoft)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: DesignTokens.Spacing.none)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.standardPlus)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Steg \(index). \(text)")
    }
}

private struct HowToEarnNoticeBuckets {
    let importantItems: [String]
    let calculationItems: [String]

    init(text: String) {
        let sentences = HowToEarnTextNormalizer.sentences(from: text)
        calculationItems = HowToEarnTextNormalizer.unique(sentences.filter(Self.isCalculation))
        importantItems = HowToEarnTextNormalizer.unique(sentences.filter { !Self.isCalculation($0) })
    }

    private static func isCalculation(_ text: String) -> Bool {
        let normalized = text.localizedLowercase
        return normalized.contains("beregningen")
            || normalized.contains("trumf-krone")
            || normalized.contains("automatisk overføring")
            || normalized.contains("engangsoverføring")
    }
}

private enum HowToEarnTextNormalizer {
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

    private static func key(_ text: String) -> String {
        text
            .localizedLowercase
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .joined(separator: " ")
    }
}

private enum HowToEarnNoticeStyle {
    static let tint = DesignTokens.Colors.noticeText
    static let border = DesignTokens.Colors.noticeBorder
    static let background = DesignTokens.Colors.noticeBackground
}

#Preview {
    NavigationStack {
        HowToEarnView(
            store: SampleData.stores[0],
            combination: SampleData.stores[0].bestCombination!
        )
    }
}
