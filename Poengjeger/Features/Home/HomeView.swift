import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var viewModel = HomeViewModel()
    @State private var selectedStore: Store?

    private var matchingStoreResults: [StoreSearchResult] {
        viewModel.matchingStoreResults(
            stores: environment.publishedStores,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private let quickSearchOptions = [
        QuickSearchOption(title: "Dagligvarer", systemImage: "basket"),
        QuickSearchOption(title: "Elektronikk", systemImage: "laptopcomputer"),
        QuickSearchOption(title: "Klær", systemImage: "tshirt"),
        QuickSearchOption(title: "Reise", systemImage: "airplane")
    ]

    private let quickSearchColumns = Array(
        repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.standard),
        count: 2
    )

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

                if viewModel.isSearching {
                    searchResultsSection
                } else {
                    quickSearchSection
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.standard)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedStore) { store in
            StoreDetailView(store: store)
        }
        .onChange(of: viewModel.searchText) {
            viewModel.trackSearchStartedIfNeeded(using: environment.track)
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Poengjeger")
                    .font(DesignTokens.Typography.editorialHeadline)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)

                Spacer()

                NavigationLink {
                    FavoritesView()
                } label: {
                    Image(systemName: "star")
                        .font(DesignTokens.Typography.headlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                }
                .minimumTouchTarget()
                .accessibilityLabel("Åpne mine favoritter")
            }

            Text("Sjekk før du handler")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            searchField

            if !viewModel.isSearching && !isSearchFocused {
                Text("For eksempel Elkjøp, fly eller dagligvarer")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.medium)
            }
        }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, DesignTokens.Spacing.medium)
    }

    private var searchField: some View {
        @Bindable var viewModel = viewModel

        return HStack(spacing: DesignTokens.Spacing.controlGap) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .accessibilityHidden(true)

            TextField("Hva skal du kjøpe?", text: $viewModel.searchText)
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

            if viewModel.isSearching {
                Button {
                    viewModel.searchText = ""
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
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                .stroke(
                    isSearchFocused ? DesignTokens.Colors.brandPrimary : DesignTokens.Colors.border,
                    lineWidth: DesignTokens.Stroke.standard
                )
        }
    }

    private var quickSearchSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("Hva skal du handle?")
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Velg et hurtigsøk, eller skriv i søkefeltet.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: quickSearchColumns, spacing: DesignTokens.Spacing.standard) {
                ForEach(quickSearchOptions) { option in
                    Button {
                        selectQuickSearch(option)
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.controlGap) {
                            Image(systemName: option.systemImage)
                                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                                .accessibilityHidden(true)

                            Text(option.title)
                                .font(DesignTokens.Typography.bodySemibold)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: DesignTokens.Spacing.none)

                            Image(systemName: "chevron.right")
                                .font(DesignTokens.Typography.captionSemibold)
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.standard)
                        .padding(.vertical, DesignTokens.Spacing.controlGap)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                        }
                    }
                    .buttonStyle(.plain)
                    .minimumTouchTarget()
                    .accessibilityLabel("Søk etter \(option.title.lowercased())")
                    .accessibilityHint("Viser butikker med verifisert opptjening")
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

                Text(viewModel.searchResultTitle)
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("\(matchingStoreResults.count) treff")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
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

    private func selectQuickSearch(_ option: QuickSearchOption) {
        isSearchFocused = false
        viewModel.selectQuickSearch(title: option.title, using: environment.track)
    }

    private func openStore(_ store: Store, entryPoint: String, rank: Int) {
        viewModel.trackStoreOpen(
            store,
            entryPoint: entryPoint,
            rank: rank,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
            using: environment.track
        )
        selectedStore = store
    }
}

private struct QuickSearchOption: Identifiable {
    let title: String
    let systemImage: String

    var id: String { title }
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
            description: Text(isSearching ? "Prøv et annet butikknavn eller en bredere kategori, som elektronikk eller dagligvarer." : "Butikksøk vises her når opptjeningsdata er bekreftet.")
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
