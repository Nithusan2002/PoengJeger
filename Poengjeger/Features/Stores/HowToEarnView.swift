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
            LazyVStack(alignment: .leading, spacing: 22) {
                header

                stepsSection

                compactNotice

                handoffButton

                compactHandoffDisclosure

                detailDisclosure
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Slik gjør du det")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                StoreInitialMark(name: store.name)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(store.category?.name ?? "Butikk")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(combination.rateIDs.count > 1 ? "BESTE KOMBINASJON" : "BESTE DOKUMENTERTE MULIGHET")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(PoengjegerTheme.primary)

                Text(combination.totalValueLabel)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(combination.summary)
                    .lineLimit(2)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("HANDLING")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Følg stegene i rekkefølge")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                    StepInstructionRow(index: index + 1, text: step.text)

                    if step.id != sortedSteps.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(PoengjegerTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PoengjegerTheme.border, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var compactNotice: some View {
        if let importantNotice = noticeBuckets?.importantItems.first {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HowToEarnNoticeStyle.tint)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(importantNotice)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HowToEarnNoticeStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(HowToEarnNoticeStyle.border, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var detailDisclosure: some View {
        DisclosureGroup(isExpanded: $isDetailDisclosureExpanded) {
            VStack(alignment: .leading, spacing: 12) {
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
            .padding(.top, 10)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .accessibilityHidden(true)

                Text("Se beregning og vilkår")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(PoengjegerTheme.primary)
        }
        .padding(14)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }

    private func detailList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var handoffButton: some View {
        if let url = combination.primaryHandoffURL {
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
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(PoengjegerTheme.primaryButtonBackground)
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
            VStack(alignment: .center, spacing: 6) {
                Text("Du sendes videre til \(handoffDestinationNameForDisclosure).")

                Text("Lenken kan gi Poengjeger provisjon. Den påvirker verken rangeringen eller hva vi anbefaler.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
        }
    }

    @ViewBuilder
    private var compactHandoffDisclosure: some View {
        if combination.primaryHandoffURL != nil {
            Text("Lenken kan gi Poengjeger provisjon.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
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
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)
                .frame(width: 26, height: 26)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
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
    static let tint = PoengjegerTheme.adaptive(light: (0.55, 0.34, 0.08), dark: (1.0, 0.76, 0.38))
    static let border = Color(red: 0.86, green: 0.75, blue: 0.53)
    static let background = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.16, blue: 0.09, alpha: 1)
        }

        return UIColor(red: 0.98, green: 0.93, blue: 0.80, alpha: 1)
    })
}

#Preview {
    NavigationStack {
        HowToEarnView(
            store: SampleData.stores[0],
            combination: SampleData.stores[0].bestCombination!
        )
    }
}
