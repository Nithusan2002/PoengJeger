import SwiftUI

struct StoreDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    let store: Store

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header

                bestCombinationSection

                rateSection(title: "Vanlig opptjening", rates: store.baseRates)

                rateSection(title: "Akkurat nå", rates: store.activePromotions)

                allMethodsSection

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
            HStack(spacing: 8) {
                Text(store.category?.name.uppercased() ?? "BUTIKK")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.primary)

                if !store.activePromotions.isEmpty {
                    Text("\(store.activePromotions.count) AKTIV")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(PoengjegerTheme.campaign)
                        .clipShape(Capsule())
                }
            }

            Text(store.name)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Sjekk opptjening og krav før du starter handelen.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let lastVerifiedAt = store.lastVerifiedAt {
                Label("Sist kontrollert \(DateFormatter.localizedString(from: lastVerifiedAt, dateStyle: .medium, timeStyle: .none))", systemImage: "checkmark.seal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rateSection(title: String, rates: [StoreEarningRate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: title,
                subtitle: title == "Vanlig opptjening" ? "Stabil grunnopptjening du kan regne med først." : "Tidsbegrensede forbedringer over normalen."
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
                subtitle: "Slik kan du tjene poeng her."
            )

            ForEach(store.sortedEarningRates) { rate in
                EarningMethodRow(rate: rate)
            }
        }
    }

    @ViewBuilder
    private var bestCombinationSection: some View {
        if let combination = store.bestCombination {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(
                    title: "Beste valg nå",
                    subtitle: "Vist først fordi dette er handlingen brukeren kom for."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Label("Redaksjonelt valgt", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.success)

                    Text(combination.totalValueLabel)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(combination.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    let includedRates = rates(in: combination)
                    if !includedRates.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(includedRates) { rate in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(PoengjegerTheme.programColor(slug: programSlug(for: rate)))
                                        .frame(width: 7, height: 7)
                                        .accessibilityHidden(true)

                                    Text("\(rate.method.name): \(rate.rateLabel)")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if let easierAlternativeLabel = combination.easierAlternativeLabel {
                        Label(easierAlternativeLabel, systemImage: "arrow.triangle.branch")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.primary)
                    }

                    NavigationLink(value: combination) {
                        Label("Vis steg", systemImage: "arrow.right.circle.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PoengjegerTheme.primary)
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
            Text("Kilde og kontroll")
                .font(.headline.weight(.semibold))

            Text("Opptjening og beste valg er redaksjonelt kvalitetssikret. Kontroller alltid satsen i portalen før kjøp.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.lastVerifiedAt.map { "Sist kontrollert \(DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none))." } ?? "Kontrolltidspunkt mangler.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rates(in combination: EarningCombination) -> [StoreEarningRate] {
        combination.rateIDs.compactMap { rateID in
            store.earningRates.first { $0.id == rateID }
        }
    }

    private func programSlug(for rate: StoreEarningRate) -> String? {
        guard let programID = rate.method.programID else { return nil }
        return environment.programs.first { $0.id == programID }?.slug
    }
}

private struct EarningRateCard: View {
    let rate: StoreEarningRate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                MethodIcon(method: rate.method)

                VStack(alignment: .leading, spacing: 3) {
                    Text(rate.method.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(rate.rateLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
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

private struct EarningMethodRow: View {
    let rate: StoreEarningRate

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MethodIcon(method: rate.method)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(rate.method.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Text(rate.rateLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .multilineTextAlignment(.trailing)
                }

                if let requirementSummary = rate.requirementSummary {
                    Text(requirementSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }
}

private struct MethodIcon: View {
    let method: EarningMethod

    var body: some View {
        Image(systemName: iconName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(PoengjegerTheme.primary)
            .frame(width: 30, height: 30)
            .background(PoengjegerTheme.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }

    private var iconName: String {
        switch method.type {
        case .portal:
            return "arrow.up.forward.app"
        case .card:
            return "creditcard"
        case .loyalty:
            return "person.text.rectangle"
        case .campaign:
            return "tag"
        case .manual:
            return "checklist"
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: SampleData.stores[0])
    }
}
