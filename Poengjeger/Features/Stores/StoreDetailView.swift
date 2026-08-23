import SwiftUI

struct StoreDetailView: View {
    let store: Store

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header

                rateSection(title: "Vanlig opptjening", rates: store.baseRates)

                rateSection(title: "Akkurat nå", rates: store.activePromotions)

                allMethodsSection

                bestCombinationSection

                sourceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: EarningCombination.self) { combination in
            HowToEarnView(store: store, combination: combination)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.category?.name.uppercased() ?? "BUTIKK")
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.accent)

            Text(store.name)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)

            Text("Sjekk opptjening og krav før du starter handelen.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rateSection(title: String, rates: [StoreEarningRate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: title,
                subtitle: title == "Vanlig opptjening" ? "Stabil grunnopptjening vises først." : "Tidsbegrensede forbedringer."
            )

            if rates.isEmpty {
                Text(title == "Vanlig opptjening" ? "Ingen publisert grunnopptjening ennå." : "Ingen aktive kampanjer for denne butikken akkurat nå.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ForEach(rates) { rate in
                    EarningRateCard(rate: rate)
                }
            }
        }
    }

    private var allMethodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: "Alle opptjeningsmuligheter",
                subtitle: "Mekanismene vises separat før kombinasjonen."
            )

            ForEach(store.sortedEarningRates) { rate in
                EarningRateCard(rate: rate)
            }
        }
    }

    @ViewBuilder
    private var bestCombinationSection: some View {
        if let combination = store.bestCombination {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "Beste kombinasjon",
                    subtitle: "Redaksjonelt valgt for denne butikken."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text(combination.totalValueLabel)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(combination.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let easierAlternativeLabel = combination.easierAlternativeLabel {
                        Label(easierAlternativeLabel, systemImage: "arrow.triangle.branch")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.accent)
                    }

                    NavigationLink(value: combination) {
                        Label("Slik gjør du det", systemImage: "arrow.right.circle.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PoengjegerTheme.accent)
                }
                .padding(16)
                .background(PoengjegerTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PoengjegerTheme.border, lineWidth: 1)
                }
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kontroll")
                .font(.headline.weight(.semibold))

            Text(store.lastVerifiedAt.map { "Sist kontrollert \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))." } ?? "Kontrolltidspunkt mangler.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EarningRateCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(rate.method.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text(rate.rateLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.accent)
                    .multilineTextAlignment(.trailing)
            }

            if let normalRateLabel = rate.normalRateLabel {
                Text("Normal: \(normalRateLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let valueSummary = rate.valueSummary {
                Text(valueSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let requirementSummary = rate.requirementSummary {
                Label(requirementSummary, systemImage: "checklist")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let warningText = rate.warningText {
                Label(warningText, systemImage: "exclamationmark.triangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: SampleData.stores[0])
    }
}
