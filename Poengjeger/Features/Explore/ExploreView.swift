import SwiftUI

struct ExploreView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedScope: ExploreScope = .campaigns

    private var activeCampaigns: [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.firstPhaseCampaigns,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
            showsAllPrograms: environment.selectedFirstPhaseProgramIDs.isEmpty,
            selectedCategoryID: nil,
            searchText: "",
            sort: .expiringFirst
        )
    }

    private var rankedStores: [Store] {
        StoreDiscoveryUseCase()
            .rankedStores(from: environment.publishedStores, selectedProgramIDs: environment.selectedFirstPhaseProgramIDs)
            .filter { $0.bestCombination(for: environment.selectedFirstPhaseProgramIDs) != nil || !$0.sortedEarningRates.isEmpty }
    }

    private var featuredStores: [Store] {
        rankedStores.prefix(4).map { $0 }
    }

    private var programsByID: [UUID: BonusProgram] {
        Dictionary(uniqueKeysWithValues: environment.programs.map { ($0.id, $0) })
    }

    private var categories: [ExploreCategorySummary] {
        Dictionary(grouping: rankedStores) { store in
            store.category?.name ?? "Andre butikker"
        }
        .map { categoryName, stores in
            ExploreCategorySummary(
                name: categoryName,
                storeCount: stores.count,
                topValueLabel: stores.first?.bestCombination(for: environment.selectedFirstPhaseProgramIDs)?.totalValueLabel
            )
        }
        .sorted { first, second in
            if first.priority != second.priority {
                return first.priority > second.priority
            }

            return first.name.localizedCompare(second.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
                header

                statusSection

                scopePicker

                selectedScopeSection
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.comfortable)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign, entryPoint: "explore")
        }
        .navigationDestination(for: StoreCategoryRoute.self) { route in
            CategoryStoresView(categoryName: route.name)
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
            Text("Utforsk")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Finn aktuelle muligheter før du handler.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusSection: some View {
        if case let .failed(message) = environment.loadState, activeCampaigns.isEmpty && categories.isEmpty {
            FeedStatusBanner(text: message)
        } else if environment.dataSource?.isFallback == true {
            Text(environment.dataSource?.label ?? "Mock-data")
                .font(DesignTokens.Typography.captionSemibold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .padding(.horizontal, DesignTokens.Spacing.controlGap)
                .padding(.vertical, DesignTokens.Spacing.small)
                .background(DesignTokens.Colors.brandPrimarySoft)
                .clipShape(Capsule())
        }
    }

    private var scopePicker: some View {
        Picker("Utforsk innhold", selection: $selectedScope) {
            ForEach(ExploreScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .minimumTouchTarget()
        .accessibilityLabel("Velg innhold i Utforsk")
    }

    @ViewBuilder
    private var selectedScopeSection: some View {
        switch selectedScope {
        case .campaigns:
            campaignSection
        case .categories:
            categoryBrowseSection
        case .stores:
            featuredStoresSection
        }
    }

    private var campaignSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            SectionHeader(
                eyebrow: "KAMPANJER",
                title: "Aktive muligheter",
                subtitle: nil
            )

            if environment.loadState == .loading && activeCampaigns.isEmpty {
                ProgressView("Laster kampanjer...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignTokens.Spacing.emptyState)
            } else if activeCampaigns.isEmpty {
                Text("Ingen aktive kampanjer er publisert ennå.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(DesignTokens.Spacing.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                    }
            } else {
                ForEach(activeCampaigns) { campaign in
                    NavigationLink(value: campaign) {
                        ExploreCampaignTeaserRow(
                            campaign: campaign,
                            primaryProgramName: primaryProgramName(for: campaign)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryBrowseSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            SectionHeader(
                eyebrow: "KATEGORIER",
                title: "Bla etter handlebehov",
                subtitle: nil
            )

            if categories.isEmpty {
                Text("Ingen kategorier er publisert ennå.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(DesignTokens.Spacing.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                    }
            } else {
                LazyVGrid(
                    columns: categoryColumns,
                    spacing: DesignTokens.Spacing.standard
                ) {
                    ForEach(categories) { category in
                        NavigationLink(value: StoreCategoryRoute(name: category.name)) {
                            ExploreCategoryTile(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var categoryColumns: [GridItem] {
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.standard),
            count: columnCount
        )
    }

    private var featuredStoresSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            SectionHeader(
                eyebrow: "BUTIKKER",
                title: "Høyest dokumentert opptjening",
                subtitle: nil
            )

            if environment.loadState == .loading && rankedStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DesignTokens.Spacing.emptyState)
            } else if rankedStores.isEmpty {
                Text("Ingen butikker med dokumentert opptjening er publisert ennå.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(DesignTokens.Spacing.card)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                    }
            } else {
                ForEach(featuredStores) { store in
                    NavigationLink(value: store) {
                        ExploreStoreMiniRow(store: store, selectedProgramIDs: environment.selectedFirstPhaseProgramIDs)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func primaryProgramName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return programsByID[primaryProgramID]?.name
    }
}

private struct SectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text(eyebrow)
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(title)
                .font(DesignTokens.Typography.editorialTitle2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private enum ExploreScope: String, CaseIterable, Identifiable {
    case campaigns
    case categories
    case stores

    var id: String { rawValue }

    var title: String {
        switch self {
        case .campaigns:
            return "Kampanjer"
        case .categories:
            return "Kategorier"
        case .stores:
            return "Butikker"
        }
    }
}

private struct ExploreCampaignTeaserRow: View {
    let campaign: Campaign
    let primaryProgramName: String?

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
            Image(systemName: iconName)
                .font(DesignTokens.Typography.headlineSemibold)
                .foregroundStyle(campaign.cardAccent)
                .frame(width: 38, height: 38)
                .background(campaign.cardAccent.opacity(DesignTokens.Opacity.soft))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                TagRow(
                    primaryProgramName: primaryProgramName,
                    categoryName: campaign.category?.name,
                    isFeatured: false
                )

                Text(campaign.title)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(campaign.opportunitySignal)
                    .font(DesignTokens.Typography.subheadlineBold)
                    .foregroundStyle(campaign.cardAccent)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Kontrollert \(campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer(minLength: DesignTokens.Spacing.small)

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.captionBold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.top, DesignTokens.Spacing.medium)
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        if campaign.isExpiringSoon {
            return "clock.badge.exclamationmark"
        }

        if campaign.isHighScore {
            return "sparkles"
        }

        return "tag"
    }
}

private struct ExploreCategorySummary: Identifiable {
    let name: String
    let storeCount: Int
    let topValueLabel: String?

    var id: String { name }

    var priority: Int {
        switch name.localizedLowercase {
        case let value where value.contains("daglig"):
            return 80
        case let value where value.contains("barn") || value.contains("familie"):
            return 70
        case let value where value.contains("hus") || value.contains("hjem"):
            return 65
        case let value where value.contains("klær") || value.contains("sko"):
            return 60
        case let value where value.contains("elektronikk"):
            return 55
        case let value where value.contains("reise") || value.contains("hotell"):
            return 50
        default:
            return 10
        }
    }
}

private struct ExploreCategoryTile: View {
    let category: ExploreCategorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            HStack(alignment: .top) {
                Image(systemName: iconName)
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(DesignTokens.Colors.brandPrimarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                    .accessibilityHidden(true)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.captionBold)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                Text(category.name)
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("\(category.storeCount) butikker")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                if let topValueLabel = category.topValueLabel {
                    Text(shortValueLabel(topValueLabel))
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch category.name.localizedLowercase {
        case let value where value.contains("elektronikk"):
            return "desktopcomputer"
        case let value where value.contains("klær") || value.contains("sko"):
            return "tshirt"
        case let value where value.contains("sport") || value.contains("fritid"):
            return "figure.run"
        case let value where value.contains("helse") || value.contains("skjønnhet"):
            return "cross.case"
        case let value where value.contains("barn") || value.contains("familie"):
            return "figure.2.and.child.holdinghands"
        case let value where value.contains("hus") || value.contains("hjem"):
            return "house"
        case let value where value.contains("bil") || value.contains("motor"):
            return "car"
        case let value where value.contains("bøker") || value.contains("medier"):
            return "book"
        case let value where value.contains("dyr") || value.contains("kjæledyr"):
            return "pawprint"
        case let value where value.contains("programvare"):
            return "app.badge"
        case let value where value.contains("daglig"):
            return "basket"
        case let value where value.contains("reise") || value.contains("hotell"):
            return "bed.double"
        default:
            return "square.grid.2x2"
        }
    }

    private func shortValueLabel(_ label: String) -> String {
        label
            .replacingOccurrences(of: "EuroBonus-poeng", with: "EB-poeng")
            .replacingOccurrences(of: "Trumf-bonus", with: "Trumf")
    }
}

private struct ExploreStoreMiniRow: View {
    let store: Store
    var selectedProgramIDs: Set<UUID> = []

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            StoreInitialMark(name: store.name)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(store.name)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)

                if let categoryName = store.category?.name {
                    Text(categoryName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Text(valueLabel)
                .font(DesignTokens.Typography.subheadlineBold)
                .foregroundStyle(
                    hasVerifiedEarning
                        ? DesignTokens.Colors.brandPrimary
                        : DesignTokens.Colors.textSecondary
                )
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.standard)
        .frame(minHeight: 68)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }

    private var hasVerifiedEarning: Bool {
        store.bestCombination(for: selectedProgramIDs) != nil || !store.sortedEarningRates.isEmpty
    }

    private var valueLabel: String {
        store.bestCombination(for: selectedProgramIDs)?.totalValueLabel ?? "Ikke verifisert ennå"
    }
}

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppEnvironment.mock())
    }
}
