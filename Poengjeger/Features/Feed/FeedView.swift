import SwiftUI

struct FeedView: View {
    @Environment(AppEnvironment.self) private var environment
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchVisible = false
    @State private var searchText = ""
    @State private var selectedSort: FeedSort = .expiringFirst
    @State private var selectedCategoryID: UUID?
    @State private var showsAllPrograms = false
    @State private var isProgramSheetPresented = false

    private var campaigns: [Campaign] {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.campaigns,
            selectedProgramIDs: environment.userSession.selectedProgramIDs,
            showsAllPrograms: showsAllPrograms,
            selectedCategoryID: selectedCategoryID,
            searchText: searchText,
            sort: selectedSort
        )
    }

    private var activeCampaignCount: Int {
        ScannableFeedUseCase().makeFeed(
            campaigns: environment.campaigns,
            selectedProgramIDs: environment.userSession.selectedProgramIDs,
            showsAllPrograms: showsAllPrograms,
            selectedCategoryID: nil,
            searchText: "",
            sort: selectedSort
        )
        .count
    }

    private var categories: [CampaignCategory] {
        Dictionary(
            grouping: environment.campaigns.compactMap(\.category),
            by: \.id
        )
        .compactMap(\.value.first)
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var programsByID: [UUID: BonusProgram] {
        Dictionary(uniqueKeysWithValues: environment.programs.map { ($0.id, $0) })
    }

    private var hasSelectedPrograms: Bool {
        !environment.userSession.selectedProgramIDs.isEmpty
    }

    var body: some View {
        @Bindable var environment = environment

        List {
            if let dataSource = environment.dataSource, dataSource.isFallback {
                FeedStatusBanner(text: dataSource.label)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
            }

            if isLoadingInitialData {
                ForEach(0..<6, id: \.self) { _ in
                    FeedPlaceholderRow()
                        .redacted(reason: .placeholder)
                }
            } else {
                ForEach(campaigns) { campaign in
                    NavigationLink(value: campaign) {
                        FeedCampaignRow(
                            campaign: campaign,
                            programs: programs(for: campaign)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
                    .listRowBackground(PoengjegerTheme.background)
                    .accessibilityLabel(accessibilityLabel(for: campaign))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PoengjegerTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: 76)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            FeedControlHeader(
                campaignCount: activeCampaignCount,
                showsAllPrograms: showsAllPrograms || !hasSelectedPrograms,
                isSearchVisible: isSearchVisible,
                searchText: $searchText,
                selectedSort: $selectedSort,
                selectedCategoryID: $selectedCategoryID,
                categories: categories,
                hasSelectedPrograms: hasSelectedPrograms,
                onToggleSearch: toggleSearch,
                onOpenProgramFilter: { isProgramSheetPresented = true },
                onToggleShowsAllPrograms: { showsAllPrograms.toggle() },
                isSearchFocused: $isSearchFocused
            )
        }
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign)
        }
        .refreshable {
            await environment.refresh()
        }
        .overlay {
            if case let .failed(message) = environment.loadState, campaigns.isEmpty {
                ContentUnavailableView(
                    "Kunne ikke hente kampanjer",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
            } else if !isLoadingInitialData && campaigns.isEmpty {
                ContentUnavailableView(
                    "Ingen kampanjer matcher filteret ditt akkurat nå.",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
        }
        .sheet(isPresented: $isProgramSheetPresented) {
            ProgramFilterSheet(
                programs: environment.programs,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )
        }
    }

    private var isLoadingInitialData: Bool {
        if case .loading = environment.loadState {
            return environment.campaigns.isEmpty
        }

        return false
    }

    private func toggleSearch() {
        isSearchVisible.toggle()

        if isSearchVisible {
            isSearchFocused = true
        } else {
            searchText = ""
            isSearchFocused = false
        }
    }

    private func programs(for campaign: Campaign) -> [BonusProgram] {
        campaign.linkedProgramIDs.compactMap { programsByID[$0] }
    }

    private func accessibilityLabel(for campaign: Campaign) -> String {
        let expiry = FeedDateHelper.expiryLabel(campaign.endDate).text
        let programNames = programs(for: campaign).map(\.name).joined(separator: ", ")
        return "\(campaign.feedHeadline). \(campaign.feedReason). \(expiry). \(programNames)."
    }
}

private struct FeedControlHeader: View {
    let campaignCount: Int
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kampanjer")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)

                    Text("\(campaignCount) aktive · \(showsAllPrograms ? "alle programmer" : "dine programmer")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                            title: selectedSort.title,
                            systemImage: "arrow.up.arrow.down",
                            isSelected: true
                        )
                    }
                    .accessibilityLabel("Sorter kampanjer")

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

                    if hasSelectedPrograms {
                        Button {
                            onToggleShowsAllPrograms()
                        } label: {
                            FilterChip(
                                title: showsAllPrograms ? "Alle programmer" : "Mine programmer",
                                systemImage: showsAllPrograms ? "person.2" : "person.crop.circle",
                                isSelected: showsAllPrograms
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showsAllPrograms ? "Viser alle programmer" : "Viser dine programmer")
                    }
                }
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

    private var selectedCategoryName: String {
        guard let selectedCategoryID,
              let category = categories.first(where: { $0.id == selectedCategoryID })
        else {
            return "Kategori"
        }

        return category.name
    }

}

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
            .background(isSelected ? PoengjegerTheme.accentSoft : PoengjegerTheme.surface)
            .foregroundStyle(isSelected ? PoengjegerTheme.accent : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct FeedCampaignRow: View {
    let campaign: Campaign
    let programs: [BonusProgram]

    private var expiry: ExpiryDisplay {
        FeedDateHelper.expiryLabel(campaign.endDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(campaign.feedHeadline)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                Text(expiry.text.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(expiry.urgent ? PoengjegerTheme.warning : .secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .accessibilityLabel(expiry.text)
            }

            if campaign.feedHeadline != campaign.title {
                Text(campaign.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(campaign.feedReason)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if campaign.editorialScore != nil || !programs.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        metadata
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var metadata: some View {
        if campaign.editorialScore != nil {
            FeedEditorialTierPill(label: campaign.editorialTierLabel)
        }

        ForEach(programs) { program in
            ProgramTag(program: program)
        }
    }
}

private struct FeedEditorialTierPill: View {
    let label: String

    var body: some View {
        Text(label.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(PoengjegerTheme.accent)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PoengjegerTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Vurdering \(label)")
    }
}

private struct ProgramTag: View {
    let program: BonusProgram

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(program.feedColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)

            Text(program.shortDisplayName.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(program.feedColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FeedPlaceholderRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("15 % bonus")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Spacer()
                Text("3 DAGER IGJEN")
                    .font(.caption2.weight(.bold))
            }

            Text("Kampanjetittel med kort forklaring")
                .font(.subheadline)

            HStack {
                ProgramTag(program: SampleData.trumf)
                ProgramTag(program: SampleData.euroBonus)
            }
        }
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
        .listRowBackground(PoengjegerTheme.background)
    }
}

private struct ProgramFilterSheet: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Velg alle") {
                        selectedProgramIDs = Set(programs.map(\.id))
                    }

                    Button("Tøm valg", role: .destructive) {
                        selectedProgramIDs.removeAll()
                    }
                    .disabled(selectedProgramIDs.isEmpty)
                }

                Section("Programmer") {
                    ForEach(programs) { program in
                        Button {
                            toggle(program.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedProgramIDs.contains(program.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedProgramIDs.contains(program.id) ? PoengjegerTheme.accent : .secondary)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(program.name)
                                        .foregroundStyle(.primary)
                                    Text(program.issuerName)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .accessibilityLabel(program.name)
                        .accessibilityValue(selectedProgramIDs.contains(program.id) ? "Valgt" : "Ikke valgt")
                    }
                }
            }
            .navigationTitle("Dine programmer")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ programID: UUID) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}

private extension Campaign {
    var feedHeadline: String {
        if let value = editorialAssessment?.estimatedValueText?.feedValueLabel {
            return value
        }

        return title
    }

    var feedReason: String {
        if let reason = editorialAssessment?.reasonWhyItMatters, !reason.isEmpty {
            return reason
        }

        return displaySummary
    }
}

private extension String {
    var feedValueLabel: String? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let patterns = [
            #"\d[\d\s]*(?:kr|kroner)(?:\s+i\s+[A-Za-zÆØÅæøå-]+-bonus)?"#,
            #"\d[\d\s]*(?:EuroBonus-poeng|CashPoints|poeng)"#,
            #"\d+\s*%\s+[A-Za-zÆØÅæøå-]+-bonus"#,
            #"\d+\s*%\s+bonus"#,
            #"\d+\s+dager\s+gratis"#
        ]

        for pattern in patterns {
            if let match = normalized.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(normalized[match]).normalizedFeedValueLabel
            }
        }

        let firstSentence = normalized.split(separator: ".").first.map(String.init) ?? normalized
        if firstSentence.count <= 34 {
            return firstSentence
        }

        return nil
    }

    private var normalizedFeedValueLabel: String {
        replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
    }
}

private extension BonusProgram {
    var shortDisplayName: String {
        switch slug {
        case "sas-eurobonus":
            return "SAS"
        case "norwegian-reward":
            return "Norwegian"
        default:
            return name
        }
    }

    var feedColor: Color {
        switch slug {
        case "sas-eurobonus":
            return Color(red: 0.08, green: 0.28, blue: 0.62)
        case "trumf":
            return Color(red: 0.10, green: 0.48, blue: 0.28)
        case "spenn":
            return Color(red: 0.62, green: 0.30, blue: 0.76)
        default:
            return PoengjegerTheme.accent
        }
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .environment(AppEnvironment.mock())
    }
}
