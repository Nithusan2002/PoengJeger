import SwiftUI

struct FeedControlHeader: View {
    let campaignCount: Int
    let priorityStats: FeedPriorityStats
    let showsAllPrograms: Bool
    let isSearchVisible: Bool
    @Binding var searchText: String
    @Binding var selectedSort: FeedSort
    @Binding var selectedCategoryID: UUID?
    let categories: [CampaignCategory]
    let hasSelectedPrograms: Bool
    let onToggleSearch: () -> Void
    let onOpenProgramFilter: () -> Void
    let onToggleShowsAllPrograms: () -> Void
    let isSearchFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kampanjer")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)

                    Text(summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button(action: onToggleSearch) {
                    Image(systemName: isSearchVisible ? "xmark" : "magnifyingglass")
                        .font(.headline.weight(.semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityLabel(isSearchVisible ? "Lukk søk" : "Søk")

                Button(action: onOpenProgramFilter) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline.weight(.semibold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityLabel("Velg programmer")
            }

            if isSearchVisible {
                TextField("Søk i kampanjer", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .focused(isSearchFocused)
                    .accessibilityLabel("Søk i kampanjer")
            }

            HStack(spacing: 8) {
                sortFilterControl
                categoryFilterControl
                programScopeControl
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var summaryText: String {
        if campaignCount == 0 {
            return showsAllPrograms ? "Ingen aktive kampanjer" : "Ingen aktive kampanjer for dine valg"
        }

        var parts = ["\(campaignCount) aktive"]
        if priorityStats.urgentCount > 0 {
            parts.append("\(priorityStats.urgentCount) haster")
        }
        if priorityStats.highValueCount > 0 {
            parts.append("\(priorityStats.highValueCount) høy verdi")
        }
        parts.append(showsAllPrograms ? "alle programmer" : "dine programmer")
        return parts.joined(separator: " · ")
    }

    private var sortFilterControl: some View {
        Menu {
            ForEach(FeedSort.allCases) { sort in
                Button {
                    selectedSort = sort
                } label: {
                    if selectedSort == sort {
                        Label(sort.title, systemImage: "checkmark")
                    } else {
                        Text(sort.title)
                    }
                }
            }
        } label: {
            FilterChip(
                title: selectedSort.shortTitle,
                systemImage: "arrow.up.arrow.down",
                isSelected: true
            )
        }
        .accessibilityLabel("Sorter kampanjer")
    }

    private var categoryFilterControl: some View {
        Menu {
            Button {
                selectedCategoryID = nil
            } label: {
                if selectedCategoryID == nil {
                    Label("Alle kategorier", systemImage: "checkmark")
                } else {
                    Text("Alle kategorier")
                }
            }

            ForEach(categories) { category in
                Button {
                    selectedCategoryID = category.id
                } label: {
                    if selectedCategoryID == category.id {
                        Label(category.name, systemImage: "checkmark")
                    } else {
                        Text(category.name)
                    }
                }
            }
        } label: {
            FilterChip(
                title: selectedCategoryName,
                systemImage: "tag",
                isSelected: selectedCategoryID != nil
            )
        }
        .accessibilityLabel("Velg kategori")
    }

    @ViewBuilder
    private var programScopeControl: some View {
        if hasSelectedPrograms {
            Button {
                onToggleShowsAllPrograms()
            } label: {
                FilterChip(
                    title: showsAllPrograms ? "Alle" : "Mine valg",
                    systemImage: showsAllPrograms ? "person.2" : "person.crop.circle",
                    isSelected: showsAllPrograms
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showsAllPrograms ? "Viser alle programmer" : "Viser dine programmer")
        }
    }

    private var selectedCategoryName: String {
        guard let selectedCategoryID,
              let category = categories.first(where: { $0.id == selectedCategoryID })
        else {
            return "Kategori"
        }

        return category.name
    }

}
