import SwiftUI

struct StoreDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    let store: Store

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                bestCombinationSection

                rateSection(title: "Vanlig opptjening", rates: store.baseRates)

                rateSection(title: "Akkurat nå", rates: store.activePromotions)

                allMethodsSection

                sourceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
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
        HStack(alignment: .top, spacing: 14) {
            StoreInitialMark(name: store.name)
                .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text(store.name)
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(store.category?.name ?? "Butikk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let lastVerifiedAt = store.lastVerifiedAt {
                    Label("Sist kontrollert \(shortDate(lastVerifiedAt))", systemImage: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
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
                VStack(alignment: .leading, spacing: 14) {
                    Text("BESTE KOMBINASJON")
                        .font(.caption.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(PoengjegerTheme.primary)

                    Text(combination.totalValueLabel)
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(combination.summary)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
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
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    if let easierAlternativeLabel = combination.easierAlternativeLabel {
                        Text(easierAlternativeLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.primary)
                    }

                    NavigationLink(value: combination) {
                        Label("Slik gjør du det", systemImage: "arrow.right")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PoengjegerTheme.primary)
                }
                .padding(16)
                .background(PoengjegerTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
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

    private func rates(in combination: EarningCombination) -> [StoreEarningRate] {
        combination.rateIDs.compactMap { rateID in
            store.earningRates.first { $0.id == rateID }
        }
    }

    private func programSlug(for rate: StoreEarningRate) -> String? {
        guard let programID = rate.method.programID else { return nil }
        return environment.programs.first { $0.id == programID }?.slug
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

            if let url = rate.handoffURL ?? rate.sourceURL {
                Link(destination: url) {
                    Label("Start hos \(destinationName(for: rate, url: url))", systemImage: "arrow.up.forward.app.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PoengjegerTheme.primary)
                .padding(.top, 4)
                .accessibilityHint("Åpner \(destinationName(for: rate, url: url)) eksternt.")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rate.isBaseRate ? PoengjegerTheme.elevatedSurface : PoengjegerTheme.campaignSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(rate.isBaseRate ? PoengjegerTheme.border : PoengjegerTheme.campaign.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func destinationName(for rate: StoreEarningRate, url: URL) -> String {
        if let sourceTitle = rate.sourceTitle, !sourceTitle.isEmpty {
            return sourceTitle
        }

        let host = url.host()?.localizedLowercase ?? ""
        if host.contains("trumf") {
            return "Trumf"
        }
        if host.contains("sas") || host.contains("eurobonus") {
            return "EuroBonus"
        }

        return rate.method.name
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
