import SwiftUI

struct ExploreView: View {
    @Environment(AppEnvironment.self) private var environment

    private var campaignItems: [ExplorePromotionItem] {
        environment.publishedStores
            .flatMap { store in
                store.activePromotions.map { rate in
                    ExplorePromotionItem(store: store, rate: rate)
                }
            }
            .sorted { first, second in
                switch (first.rate.endsAt, second.rate.endsAt) {
                case let (firstDate?, secondDate?) where firstDate != secondDate:
                    return firstDate < secondDate
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return first.store.name.localizedCompare(second.store.name) == .orderedAscending
                }
            }
    }

    private var categories: [String] {
        Array(Set(environment.publishedStores.compactMap { $0.category?.name }))
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    private var earningStores: [Store] {
        StoreDiscoveryUseCase().storesWithEarning(from: environment.publishedStores)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header

                earningStoresSection

                campaignSection

                categoryBrowseSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Utforsk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .navigationDestination(for: StoreCategoryRoute.self) { route in
            CategoryStoresView(categoryName: route.name)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Utforsk")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text("Kampanjer og bredere oppdagelse når du ikke leter etter en bestemt butikk.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var earningStoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BUTIKKER MED OPPTJENING")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Sjekk disse først")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Publiserte butikker der redaksjonen har verifisert minst én opptjeningsmulighet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if earningStores.isEmpty {
                Text("Ingen butikker med verifisert opptjening er publisert ennå.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(PoengjegerTheme.border, lineWidth: 1)
                    }
            } else {
                VStack(spacing: 0) {
                    ForEach(earningStores) { store in
                        NavigationLink(value: store) {
                            ExploreStoreMiniRow(store: store)
                        }
                        .buttonStyle(.plain)

                        if store.id != earningStores.last?.id {
                            Divider()
                                .padding(.leading, 64)
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
    }

    private var campaignSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TIDSBEGRENSET")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Kampanjer akkurat nå")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Kun kampanjer med kjent sluttdato. Utløpte kampanjer vises aldri.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if campaignItems.isEmpty {
                Text("Ingen aktive tidsbegrensede kampanjer akkurat nå.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(PoengjegerTheme.border, lineWidth: 1)
                    }
            } else {
                ForEach(campaignItems.prefix(3)) { item in
                    NavigationLink(value: item.store) {
                        ExplorePromotionRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryBrowseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ALLE BUTIKKER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Bla etter kategori")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            ForEach(categories, id: \.self) { category in
                ExploreCategoryGroup(
                    categoryName: category,
                    stores: rankedStores(in: category).prefix(3).map { $0 }
                )
            }
        }
    }

    private func rankedStores(in category: String) -> [Store] {
        StoreDiscoveryUseCase()
            .rankedStores(from: environment.publishedStores)
            .filter { $0.category?.name == category }
    }
}

private struct ExplorePromotionItem: Identifiable {
    let store: Store
    let rate: StoreEarningRate

    var id: UUID {
        rate.id
    }
}

private struct ExplorePromotionRow: View {
    let item: ExplorePromotionItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StoreInitialMark(name: item.store.name)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.store.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(rateLine)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.campaign)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    if let endsAt = item.rate.endsAt {
                        Text("Gyldig til \(DateFormatter.localizedString(from: endsAt, dateStyle: .medium, timeStyle: .none))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.campaign)
                    }

                    if let checkedAt = item.rate.checkedAt ?? item.store.lastVerifiedAt {
                        Label(
                            "Sist kontrollert \(DateFormatter.localizedString(from: checkedAt, dateStyle: .medium, timeStyle: .none))",
                            systemImage: "checkmark"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 6)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 18)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(PoengjegerTheme.campaignSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.campaign.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var rateLine: String {
        if let normalRateLabel = item.rate.normalRateLabel {
            return "\(item.rate.rateLabel) · normalt \(normalRateLabel)"
        }

        return item.rate.rateLabel
    }
}

private struct ExploreCategoryGroup: View {
    let categoryName: String
    let stores: [Store]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(categoryName)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Spacer()

                NavigationLink(value: StoreCategoryRoute(name: categoryName)) {
                    Label("Se alle", systemImage: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }
                .foregroundStyle(PoengjegerTheme.primary)
            }

            VStack(spacing: 0) {
                ForEach(stores) { store in
                    NavigationLink(value: store) {
                        ExploreStoreMiniRow(store: store)
                    }
                    .buttonStyle(.plain)

                    if store.id != stores.last?.id {
                        Divider()
                            .padding(.leading, 64)
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
}

private struct ExploreStoreMiniRow: View {
    let store: Store

    var body: some View {
        HStack(spacing: 12) {
            StoreInitialMark(name: store.name)

            Text(store.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(store.bestCombination?.totalValueLabel ?? "Se opptjening")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppEnvironment.mock())
    }
}
