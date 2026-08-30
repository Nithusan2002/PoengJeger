import SwiftUI

struct ExploreView: View {
    @Environment(AppEnvironment.self) private var environment

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

    private var featuredCampaigns: [Campaign] {
        activeCampaigns.prefix(6).map { $0 }
    }

    private var programsByID: [UUID: BonusProgram] {
        Dictionary(uniqueKeysWithValues: environment.programs.map { ($0.id, $0) })
    }

    private var categories: [String] {
        Array(Set(environment.publishedStores.compactMap { $0.category?.name }))
            .sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header

                statusSection

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
        VStack(alignment: .leading, spacing: 10) {
            Text("Utforsk")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text("Oppdag aktive kampanjer og bla etter handlebehov.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(Capsule())
        }
    }

    private var campaignSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AKTIVE KAMPANJER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Verdt å se nå")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Publiserte kampanjer fra EuroBonus og Trumf, sortert etter frist og redaksjonell verdi.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if environment.loadState == .loading && featuredCampaigns.isEmpty {
                ProgressView("Laster kampanjer...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if featuredCampaigns.isEmpty {
                Text("Ingen aktive kampanjer er publisert ennå.")
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
                ForEach(featuredCampaigns) { campaign in
                    NavigationLink(value: campaign) {
                        CampaignCardView(
                            campaign: campaign,
                            primaryProgramName: primaryProgramName(for: campaign),
                            isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryBrowseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KATEGORIER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Bla etter handlebehov")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            if categories.isEmpty {
                Text("Ingen kategorier er publisert ennå.")
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
                ForEach(categories, id: \.self) { category in
                    ExploreCategoryGroup(
                        categoryName: category,
                        stores: rankedStores(in: category).prefix(3).map { $0 }
                    )
                }
            }
        }
    }

    private func rankedStores(in category: String) -> [Store] {
        StoreDiscoveryUseCase()
            .rankedStores(from: environment.publishedStores)
            .filter { $0.category?.name == category }
    }

    private func primaryProgramName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return programsByID[primaryProgramID]?.name
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

            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let categoryName = store.category?.name {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(valueLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(hasVerifiedEarning ? PoengjegerTheme.primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 68)
        .accessibilityElement(children: .combine)
    }

    private var hasVerifiedEarning: Bool {
        store.bestCombination != nil || !store.sortedEarningRates.isEmpty
    }

    private var valueLabel: String {
        store.bestCombination?.totalValueLabel ?? "Ikke verifisert ennå"
    }
}

#Preview {
    NavigationStack {
        ExploreView()
            .environment(AppEnvironment.mock())
    }
}
