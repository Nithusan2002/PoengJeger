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
            LazyVStack(alignment: .leading, spacing: 18) {
                header

                searchField

                if environment.dataSource?.isFallback == true {
                    Text(environment.dataSource?.label ?? "Mock-data")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PoengjegerTheme.accentSoft)
                        .clipShape(Capsule())
                }

                storeSection

                popularCampaignsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
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
            Text("SJEKK FØR DU HANDLER")
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.accent)

            Text("Finn beste opptjening før kjøpet")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Søk butikk eller kategori, se kombinasjonen og gå riktig vei videre.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }

    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: searchText.isEmpty ? "Populære butikker nå" : "Søkeresultat",
                subtitle: searchText.isEmpty ? "Start her når du faktisk skal handle." : "\(matchingStores.count) treff"
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

    private var popularCampaignsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(
                title: "Aktuelt akkurat nå",
                subtitle: "Kampanjer som fortsatt kan være verdt å sjekke."
            )

            ForEach(environment.firstPhaseCampaigns.prefix(3)) { campaign in
                NavigationLink(value: campaign) {
                    CompactCampaignRow(campaign: campaign)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StoreResultRow: View {
    let store: Store

    var body: some View {
        HStack(spacing: 12) {
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
                        .foregroundStyle(PoengjegerTheme.accent)
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
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
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
                .font(.headline.weight(.semibold))
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
