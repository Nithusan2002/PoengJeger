import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var searchText = ""

    private var matchingStores: [Store] {
        StoreSearchUseCase().search(stores: environment.publishedStores, query: searchText)
    }

    private var shownStores: [Store] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? environment.featuredStores
            : matchingStores
    }

    private var highlightedEarningItems: [HomeEarningPromotionItem] {
        environment.publishedStores
            .flatMap { store in
                store.activePromotions.compactMap { rate in
                    guard rate.endsAt != nil else { return nil }
                    return HomeEarningPromotionItem(store: store, rate: rate)
                }
            }
            .sorted { first, second in
                switch (first.rate.endsAt, second.rate.endsAt) {
                case let (firstDate?, secondDate?) where firstDate != secondDate:
                    return firstDate < secondDate
                default:
                    return first.store.name.localizedCompare(second.store.name) == .orderedAscending
                }
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header

                searchField

                if environment.dataSource?.isFallback == true {
                    Text(environment.dataSource?.label ?? "Mock-data")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PoengjegerTheme.primarySoft)
                        .clipShape(Capsule())
                }

                storeSection

                categorySection

                popularCampaignsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Hjem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .navigationDestination(for: StoreCategoryRoute.self) { route in
            CategoryStoresView(categoryName: route.name)
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Poengjeger")
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)

            Text("Sjekk før du handler")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Finn bonusmulighetene du ellers kunne gått glipp av - med EuroBonus og Trumf.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 22)
        .padding(.bottom, -8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Søk etter Elkjøp, TV, hotell...", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Tøm søk")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 10, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityLabel("Søk etter butikk eller kategori")
    }

    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            EyebrowSectionHeading(
                eyebrow: searchText.isEmpty ? "POPULÆRE BUTIKKER" : "SØKERESULTAT",
                title: searchText.isEmpty ? "Mest sjekket nå" : "\(matchingStores.count) treff"
            )

            if environment.loadState == .loading && environment.publishedStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if shownStores.isEmpty {
                EmptyStoreSearchView(isSearching: !searchText.isEmpty)
            } else {
                ForEach(shownStores.prefix(searchText.isEmpty ? 4 : shownStores.count)) { store in
                    NavigationLink(value: store) {
                        StoreResultRow(store: store)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categorySection: some View {
        let categories = Array(
            Set(environment.publishedStores.compactMap { $0.category?.name })
        )
        .sorted { $0.localizedCompare($1) == .orderedAscending }

        return VStack(alignment: .leading, spacing: 14) {
            CategorySectionHeader()

            if categories.isEmpty {
                Text("Kategorier vises når butikkdata er publisert.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(value: StoreCategoryRoute(name: category)) {
                            VStack(spacing: 16) {
                                Image(systemName: iconName(for: category))
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 58, height: 58)
                                    .background(PoengjegerTheme.neutralSoft)
                                    .clipShape(Circle())
                                    .accessibilityHidden(true)

                                VStack(spacing: 6) {
                                    Text(category)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)

                                    Text(categorySubtitle(for: category))
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 28)
                            .frame(minHeight: 174, alignment: .center)
                            .frame(maxWidth: .infinity)
                            .background(PoengjegerTheme.elevatedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(PoengjegerTheme.border, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Åpner butikker i kategorien \(category).")
                    }
                }
            }
        }
    }

    private var popularCampaignsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                EyebrowSectionHeading(
                    eyebrow: "AKTUELT AKKURAT NÅ",
                    title: "Forhøyet opptjening"
                )

                Text("Et lite, utvalgt antall kampanjer med kjent sluttdato.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if highlightedEarningItems.isEmpty {
                Text("Ingen forhøyede opptjeninger med kjent sluttdato akkurat nå.")
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
                ForEach(highlightedEarningItems.prefix(3)) { item in
                    NavigationLink(value: item.store) {
                        HomeEarningPromotionRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func iconName(for category: String) -> String {
        switch category.localizedLowercase {
        case let value where value.contains("elektronikk"):
            return "desktopcomputer"
        case let value where value.contains("daglig"):
            return "basket"
        case let value where value.contains("reise") || value.contains("hotell"):
            return "bed.double"
        case let value where value.contains("nett") || value.contains("shopping"):
            return "bag"
        default:
            return "square.grid.2x2"
        }
    }

    private func categorySubtitle(for category: String) -> String {
        switch category.localizedLowercase {
        case let value where value.contains("elektronikk"):
            return "TV, lyd, data og hvitevarer"
        case let value where value.contains("hotell"):
            return "Overnatting i inn- og utland"
        case let value where value.contains("reise"):
            return "Fly, tog og pakkereiser"
        case let value where value.contains("daglig"):
            return "Mat og hverdagsvarer"
        case let value where value.contains("nett") || value.contains("shopping"):
            return "Mote, skjønnhet og livsstil"
        default:
            return "Finn relevante opptjeningsmuligheter"
        }
    }
}

struct StoreCategoryRoute: Hashable {
    let name: String
}

private struct CategorySectionHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("KATEGORIER")
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text("Hva skal du kjøpe?")
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StoreResultRow: View {
    let store: Store

    var body: some View {
        HStack(spacing: 12) {
            StoreInitialMark(name: store.name)

            VStack(alignment: .leading, spacing: 5) {
                Text(store.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(store.category?.name ?? "Butikk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let bestCombination = store.bestCombination {
                    Text(bestCombination.totalValueLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct EyebrowSectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(.title2, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeEarningPromotionItem: Identifiable {
    let store: Store
    let rate: StoreEarningRate

    var id: UUID {
        rate.id
    }
}

private struct HomeEarningPromotionRow: View {
    let item: HomeEarningPromotionItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StoreInitialMark(name: item.store.name)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.store.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(rateText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.campaign)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    if let endsAt = item.rate.endsAt {
                        Text("Gyldig til \(shortDate(endsAt))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.campaign)
                    }

                    if let checkedAt = item.rate.checkedAt ?? item.store.lastVerifiedAt {
                        Label("Sist kontrollert \(shortDate(checkedAt))", systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.top, 6)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 20)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .background(PoengjegerTheme.campaignSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.campaign.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var rateText: String {
        if let normalRateLabel = item.rate.normalRateLabel {
            return "\(item.rate.rateLabel) · normalt \(normalRateLabel)"
        }

        return item.rate.rateLabel
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(Locale(identifier: "nb_NO"))
        )
    }
}

struct StoreInitialMark: View {
    let name: String

    var body: some View {
        Text(String(name.prefix(1)))
            .font(.headline.weight(.bold))
            .foregroundStyle(PoengjegerTheme.primary)
            .frame(width: 42, height: 42)
            .background(PoengjegerTheme.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyStoreSearchView: View {
    let isSearching: Bool

    var body: some View {
        ContentUnavailableView(
            isSearching ? "Ingen butikker matcher søket" : "Ingen butikker klare ennå",
            systemImage: "magnifyingglass",
            description: Text(isSearching ? "Prøv en annen butikk eller kategori." : "Butikksøk vises her når redaksjonen har publisert opptjeningsdata.")
        )
        .padding(.vertical, 24)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppEnvironment.mock())
    }
}
