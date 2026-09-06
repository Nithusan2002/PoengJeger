import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    @State private var hasTrackedCurrentSearch = false
    @State private var selectedStore: Store?

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var matchingStoreResults: [StoreSearchResult] {
        StoreSearchUseCase().searchResults(
            stores: environment.publishedStores,
            query: searchText,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var quickSuggestions: [Store] {
        environment.featuredStores
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionLarge) {
                header

                searchSection

                if environment.dataSource?.isFallback == true {
                    Text(environment.dataSource?.label ?? "Mock-data")
                        .font(DesignTokens.Typography.captionSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.controlGap)
                        .padding(.vertical, DesignTokens.Spacing.small)
                        .background(DesignTokens.Colors.brandPrimarySoft)
                        .clipShape(Capsule())
                }

                if isSearching {
                    searchResultsSection
                } else {
                    quickSuggestionsSection
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.standard)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Hjem")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FavoritesView()
                } label: {
                    Text("Mine favoritter")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                }
                .accessibilityLabel("Åpne mine favoritter")
            }
        }
        .navigationDestination(item: $selectedStore) { store in
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
            Text("Poengjeger")
                .font(DesignTokens.Typography.editorialHeadline)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)

            Text("Sjekk før du handler")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Søk butikk, kategori eller produkt.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignTokens.Spacing.negativeTight)
    }

    private var searchSection: some View {
        searchField
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, DesignTokens.Spacing.controlGap)
            .padding(.bottom, DesignTokens.Spacing.standard)
    }

    private var searchField: some View {
        HStack(spacing: DesignTokens.Spacing.controlGap) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .accessibilityHidden(true)

            TextField("Søk butikk, kategori eller produkt", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .minimumTouchTarget()
                .accessibilityLabel("Søk etter butikk, kategori eller produkt")
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
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .minimumTouchTarget()
                .accessibilityLabel("Tøm søk")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.screen)
        .padding(.vertical, DesignTokens.Spacing.compact)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 12, y: 5)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
    }

    private var quickSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("SNARVEIER")
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("Butikker med opptjening")
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Start med en verifisert butikk, eller søk etter det du skal kjøpe.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if environment.loadState == .loading && environment.publishedStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignTokens.Spacing.emptyState)
            } else if quickSuggestions.isEmpty {
                EmptyStoreSearchView(isSearching: false)
            } else {
                ForEach(Array(quickSuggestions.enumerated()), id: \.element.id) { index, store in
                    Button {
                        openStore(store, entryPoint: "suggestion", rank: index + 1)
                    } label: {
                        StoreResultRow(store: store, selectedProgramIDs: environment.selectedFirstPhaseProgramIDs)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("SØKERESULTAT")
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("\(matchingStoreResults.count) treff")
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            if matchingStoreResults.isEmpty {
                EmptyStoreSearchView(isSearching: true)
            } else {
                ForEach(Array(matchingStoreResults.enumerated()), id: \.element.id) { index, result in
                    Button {
                        openStore(result.store, entryPoint: "search", rank: index + 1)
                    } label: {
                        StoreResultRow(
                            store: result.store,
                            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
                            intentExplanation: result.intentExplanation
                        )
                    }
                    .buttonStyle(.plain)
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

    private func openStore(_ store: Store, entryPoint: String, rank: Int) {
        trackStoreOpen(store, entryPoint: entryPoint, rank: rank)
        selectedStore = store
    }

    private func trackStoreOpen(_ store: Store, entryPoint: String, rank: Int) {
        let bestCombination = store.bestCombination(for: environment.selectedFirstPhaseProgramIDs)
        var properties = [
            "entry_point": entryPoint,
            "rank": "\(rank)",
            "has_active_campaign": store.activePromotions.isEmpty ? "false" : "true",
            "has_best_combination": bestCombination == nil ? "false" : "true"
        ]

        if let categoryID = store.category?.id {
            properties["category_id"] = categoryID.uuidString
        }

        environment.track(.init(
            name: "store_search_result_opened",
            surface: "store_search",
            entityType: "store",
            entityID: store.id,
            properties: properties
        ))
    }

}

struct StoreCategoryRoute: Hashable {
    let name: String
}

struct StoreResultRow: View {
    let store: Store
    var selectedProgramIDs: Set<UUID> = []
    var intentExplanation: String?

    private var bestCombination: EarningCombination? {
        store.bestCombination(for: selectedProgramIDs)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            StoreInitialMark(name: store.name)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                Text(store.name)
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)

                Text(store.category?.name ?? "Butikk")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                if let bestCombination {
                    Text(bestCombination.totalValueLabel)
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                if let intentExplanation {
                    Text(intentExplanation)
                        .font(DesignTokens.Typography.captionSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

struct StoreInitialMark: View {
    let name: String

    private var initials: String {
        let words = name
            .split { !$0.isLetter && !$0.isNumber }
            .prefix(2)
            .compactMap(\.first)

        let resolvedInitials = String(words).uppercased()
        return resolvedInitials.isEmpty ? "?" : resolvedInitials
    }

    private var palette: (foreground: Color, background: Color, border: Color) {
        let palettes: [(Color, Color, Color)] = [
            (
                DesignTokens.Colors.brandPrimary,
                DesignTokens.Colors.brandPrimarySoft,
                DesignTokens.Colors.brandPrimaryBorder
            ),
            (
                DesignTokens.Colors.euroBonus,
                DesignTokens.Colors.euroBonusSoft,
                DesignTokens.Colors.euroBonus.opacity(DesignTokens.Opacity.medium)
            ),
            (
                DesignTokens.Colors.trumf,
                DesignTokens.Colors.trumfSoft,
                DesignTokens.Colors.trumf.opacity(DesignTokens.Opacity.muted)
            ),
            (
                DesignTokens.Colors.opportunity,
                DesignTokens.Colors.opportunitySoft,
                DesignTokens.Colors.opportunity.opacity(DesignTokens.Opacity.mutedStrong)
            )
        ]

        let stableHash = name.unicodeScalars.reduce(0) { partialResult, scalar in
            (partialResult &* 31 &+ Int(scalar.value)) & Int.max
        }
        let index = stableHash % palettes.count
        let selected = palettes[index]
        return (selected.0, selected.1, selected.2)
    }

    var body: some View {
        Text(initials)
            .font(DesignTokens.Typography.heroMetric)
            .foregroundStyle(palette.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: 42, height: 42)
            .background(palette.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                    .stroke(palette.border, lineWidth: DesignTokens.Stroke.standard)
            }
            .accessibilityHidden(true)
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
            Text(title)
                .font(DesignTokens.Typography.editorialTitle3)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(subtitle)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
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
            description: Text(isSearching ? "Prøv en annen butikk eller kategori." : "Butikksøk vises her når opptjeningsdata er bekreftet.")
        )
        .padding(.vertical, DesignTokens.Spacing.section)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppEnvironment.mock())
    }
}
