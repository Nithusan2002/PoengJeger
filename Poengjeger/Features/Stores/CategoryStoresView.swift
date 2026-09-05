import SwiftUI

struct CategoryStoresView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedStore: Store?
    let categoryName: String

    private var stores: [Store] {
        StoreDiscoveryUseCase().rankedStores(
            from: environment.publishedStores.filter { $0.category?.name == categoryName },
            selectedProgramIDs: selectedProgramIDs
        )
    }

    private var selectedProgramIDs: Set<UUID> {
        environment.selectedFirstPhaseProgramIDs
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header

                rankingNote

                if stores.isEmpty {
                    ContentUnavailableView(
                        "Ingen butikker ennå",
                        systemImage: iconName(for: categoryName),
                        description: Text("Butikker vises her når opptjeningsdata i kategorien er bekreftet.")
                    )
                    .padding(.vertical, 24)
                } else {
                    ForEach(Array(stores.enumerated()), id: \.element.id) { index, store in
                        Button {
                            openStore(store, rank: index + 1)
                        } label: {
                            CategoryStoreRow(store: store, selectedProgramIDs: selectedProgramIDs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(item: $selectedStore) { store in
            StoreDetailView(store: store)
        }
    }

    private func openStore(_ store: Store, rank: Int) {
        trackStoreOpen(store, rank: rank)
        selectedStore = store
    }

    private func trackStoreOpen(_ store: Store, rank: Int) {
        let bestCombination = store.bestCombination(for: selectedProgramIDs)
        var properties = [
            "entry_point": "category",
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(categoryName)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(categorySubtitle(for: categoryName))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rankingNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(PoengjegerTheme.primaryBorder)
                .frame(width: 3)
                .clipShape(Capsule())

            Text("Butikkene er rangert etter dokumentert bonusopptjening, ikke pris. Poengjeger er ikke en prisjaktjeneste.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

private struct CategoryStoreRow: View {
    let store: Store
    var selectedProgramIDs: Set<UUID> = []

    private var bestCombination: EarningCombination? {
        store.bestCombination(for: selectedProgramIDs)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StoreInitialMark(name: store.name)

            VStack(alignment: .leading, spacing: 5) {
                Text(store.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(store.category?.name ?? "Butikk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let bestCombination {
                    Text(bestCombination.totalValueLabel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                if let lastVerifiedAt = store.lastVerifiedAt {
                    Label(
                        "Sist kontrollert \(DateFormatter.localizedString(from: lastVerifiedAt, dateStyle: .medium, timeStyle: .none))",
                        systemImage: "checkmark"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 15)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
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

private func categorySubtitle(for category: String) -> String {
    switch category.localizedLowercase {
    case let value where value.contains("elektronikk"):
        return "TV, lyd, data og hvitevarer"
    case let value where value.contains("klær") || value.contains("sko"):
        return "Mote, sko og tilbehør"
    case let value where value.contains("sport") || value.contains("fritid"):
        return "Trening, tur og utstyr"
    case let value where value.contains("helse") || value.contains("skjønnhet"):
        return "Apotek, velvære og hudpleie"
    case let value where value.contains("barn") || value.contains("familie"):
        return "Baby, barn og familiehandel"
    case let value where value.contains("hus") || value.contains("hjem"):
        return "Interiør, kjøkken, hage og verktøy"
    case let value where value.contains("bil") || value.contains("motor"):
        return "Bildeler, dekk og bilutstyr"
    case let value where value.contains("bøker") || value.contains("medier"):
        return "Bøker, magasiner og medier"
    case let value where value.contains("dyr") || value.contains("kjæledyr"):
        return "Dyreutstyr og kjæledyr"
    case let value where value.contains("programvare"):
        return "Apper, sikkerhet og programvare"
    case let value where value.contains("hotell"):
        return "Overnatting i inn- og utland"
    case let value where value.contains("reise"):
        return "Fly, tog og pakkereiser"
    case let value where value.contains("daglig"):
        return "Mat og hverdagsvarer"
    case let value where value.contains("nett") || value.contains("shopping"):
        return "Mote, skjønnhet og livsstil"
    default:
        return "Butikker med dokumentert opptjening"
    }
}

private func iconName(for category: String) -> String {
    switch category.localizedLowercase {
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
    case let value where value.contains("nett") || value.contains("shopping"):
        return "bag"
    default:
        return "square.grid.2x2"
    }
}

#Preview {
    NavigationStack {
        CategoryStoresView(categoryName: "Elektronikk")
            .environment(AppEnvironment.mock())
            .navigationDestination(for: Store.self) { store in
                StoreDetailView(store: store)
            }
    }
}
