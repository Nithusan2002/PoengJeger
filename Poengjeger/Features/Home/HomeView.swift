import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var hasTrackedCurrentSearch = false

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var matchingStores: [Store] {
        StoreSearchUseCase().search(stores: environment.publishedStores, query: searchText)
    }

    private var quickSuggestions: [Store] {
        environment.featuredStores
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header

                searchSection

                if environment.dataSource?.isFallback == true {
                    Text(environment.dataSource?.label ?? "Mock-data")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PoengjegerTheme.primarySoft)
                        .clipShape(Capsule())
                }

                if isSearching {
                    searchResultsSection
                } else {
                    quickSuggestionsSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Hjem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .onChange(of: searchText) {
            trackSearchStartedIfNeeded()
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Poengjeger")
                .font(.system(.headline, design: .serif).weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)

            Text("Sjekk før du handler")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Søk butikk, kategori eller produkt.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, -4)
    }

    private var searchSection: some View {
        searchField
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)
            .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Søk butikk, kategori eller produkt", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .focused($isSearchFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Ferdig") {
                            isSearchFocused = false
                        }
                    }
                }

            if isSearching {
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
        .padding(.vertical, 17)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 12, y: 5)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityLabel("Søk etter butikk, kategori eller produkt")
    }

    private var quickSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SNARVEIER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Butikker med opptjening")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Start med en verifisert butikk, eller søk etter det du skal kjøpe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if environment.loadState == .loading && environment.publishedStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if quickSuggestions.isEmpty {
                EmptyStoreSearchView(isSearching: false)
            } else {
                ForEach(quickSuggestions) { store in
                    NavigationLink(value: store) {
                        StoreResultRow(store: store)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        trackStoreOpen(store, entryPoint: "suggestion")
                    })
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SØKERESULTAT")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("\(matchingStores.count) treff")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            if matchingStores.isEmpty {
                EmptyStoreSearchView(isSearching: true)
            } else {
                ForEach(matchingStores) { store in
                    NavigationLink(value: store) {
                        StoreResultRow(store: store)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        trackStoreOpen(store, entryPoint: "search")
                    })
                }
            }
        }
    }

    private func trackSearchStartedIfNeeded() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            hasTrackedCurrentSearch = false
            return
        }

        guard !hasTrackedCurrentSearch else { return }
        hasTrackedCurrentSearch = true
        environment.track(.init(
            name: "store_search_started",
            surface: "store_search",
            properties: ["entry_point": "home"]
        ))
    }

    private func trackStoreOpen(_ store: Store, entryPoint: String) {
        environment.track(.init(
            name: "store_search_result_opened",
            surface: "store_search",
            entityType: "store",
            entityID: store.id,
            properties: [
                "entry_point": entryPoint,
                "has_active_campaign": store.activePromotions.isEmpty ? "false" : "true",
                "has_best_combination": store.bestCombination == nil ? "false" : "true"
            ]
        ))
    }

}

struct StoreCategoryRoute: Hashable {
    let name: String
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
