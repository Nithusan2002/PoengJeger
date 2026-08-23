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

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
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
            .padding(.top, 18)
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
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .foregroundStyle(PoengjegerTheme.primary)
                    .accessibilityHidden(true)

                Text("SJEKK FØR DU HANDLER")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.primary)
            }

            Text("Finn beste opptjening før kjøpet")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Søk butikk eller kategori, se kombinasjonen og gå riktig vei videre.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 2)
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
        .padding(14)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityLabel("Søk etter butikk eller kategori")
    }

    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: searchText.isEmpty ? "Populære søk" : "Søkeresultat",
                subtitle: searchText.isEmpty ? "Butikker og kjøp du kan sjekke raskt." : "\(matchingStores.count) treff"
            )

            if environment.loadState == .loading && environment.publishedStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if shownStores.isEmpty {
                EmptyStoreSearchView(isSearching: !searchText.isEmpty)
            } else {
                ForEach(shownStores) { store in
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

        return VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: "Kategorier",
                subtitle: "Bruk når du vet hva du skal kjøpe, men ikke hvilken butikk."
            )

            if categories.isEmpty {
                Text("Kategorier vises når butikkdata er publisert.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            searchText = category
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: iconName(for: category))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(PoengjegerTheme.primary)
                                    .frame(width: 34, height: 34)
                                    .background(PoengjegerTheme.primarySoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .accessibilityHidden(true)

                                Text(category)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .frame(height: 104, alignment: .topLeading)
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
                        .accessibilityHint("Filtrerer butikker i kategorien \(category).")
                    }
                }
            }
        }
    }

    private var popularCampaignsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: "Muligheter nå",
                subtitle: "Aktuelle kampanjer som kan påvirke valget ditt."
            )

            ForEach(environment.firstPhaseCampaigns.prefix(3)) { campaign in
                NavigationLink(value: campaign) {
                    CompactCampaignRow(campaign: campaign)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func iconName(for category: String) -> String {
        switch category.localizedLowercase {
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
}

struct StoreResultRow: View {
    let store: Store

    var body: some View {
        HStack(spacing: 12) {
            StoreInitialMark(name: store.name)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(store.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !store.activePromotions.isEmpty {
                        Text("NÅ")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(PoengjegerTheme.campaign)
                            .clipShape(Capsule())
                    }
                }

                Text(store.category?.name ?? "Butikk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let bestCombination = store.bestCombination {
                    Label(bestCombination.totalValueLabel, systemImage: "sparkles")
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

private struct StoreInitialMark: View {
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

private struct CompactCampaignRow: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(campaign.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(campaign.displaySummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
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
