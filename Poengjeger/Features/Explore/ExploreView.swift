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
        activeCampaigns.prefix(3).map { $0 }
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
            LazyVStack(alignment: .leading, spacing: 28) {
                header

                statusSection

                campaignSection

                categoryBrowseSection

                featuredStoresSection
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Utforsk")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text("Oppdag kampanjer, kategorier og butikker med dokumentert opptjening.")
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

                Text("Et lite redaksjonelt utvalg av kampanjer der frist, krav eller verdi gjør dem verdt å sjekke.")
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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KATEGORIER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Bla etter handlebehov")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Velg kategori først, så får du full butikkoversikt på neste skjerm.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
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

    private var featuredStoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BUTIKKER")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Høyest dokumentert opptjening")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Text("Fire eksempler på sterk dokumentert opptjening. Bruk kategoriene over for full oversikt.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if environment.loadState == .loading && featuredStores.isEmpty {
                ProgressView("Laster butikker...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if featuredStores.isEmpty {
                Text("Ingen butikker med dokumentert opptjening er publisert ennå.")
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

private struct ExploreCampaignTeaserRow: View {
    let campaign: Campaign
    let primaryProgramName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(campaign.cardAccent)
                .frame(width: 38, height: 38)
                .background(campaign.cardAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                TagRow(
                    primaryProgramName: primaryProgramName,
                    categoryName: campaign.category?.name,
                    isFeatured: false
                )

                Text(campaign.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(campaign.opportunitySignal)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(campaign.cardAccent)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Kontrollert \(campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .accessibilityHidden(true)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: iconName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.primary)
                    .frame(width: 36, height: 36)
                    .background(PoengjegerTheme.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(category.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("\(category.storeCount) butikker")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let topValueLabel = category.topValueLabel {
                    Text(shortValueLabel(topValueLabel))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
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
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
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
