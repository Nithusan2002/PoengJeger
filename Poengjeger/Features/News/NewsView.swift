import SwiftUI

struct NewsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programsByID: [UUID: BonusProgram] {
        Dictionary(uniqueKeysWithValues: environment.programs.map { ($0.id, $0) })
    }

    private var newsItems: [NewsItem] {
        let campaigns = ScannableFeedUseCase()
            .makeFeed(
                campaigns: environment.firstPhaseCampaigns,
                selectedProgramIDs: environment.selectedFirstPhaseProgramIDs,
                showsAllPrograms: environment.selectedFirstPhaseProgramIDs.isEmpty,
                selectedCategoryID: nil,
                searchText: "",
                sort: .newest
            )

        return campaigns
            .map { NewsItem(campaign: $0, primaryProgramName: primaryProgramName(for: $0)) }
            .sorted(by: NewsItem.newsPriority)
    }

    private var topStory: NewsItem? {
        newsItems.first
    }

    private var deadlineItems: [NewsItem] {
        sectionItems(matching: { $0.type == .deadline }, limit: 3)
    }

    private var thisWeekItems: [NewsItem] {
        sectionItems(matching: { $0.type != .deadline && $0.isRecent }, limit: 3)
    }

    private var worthKnowingItems: [NewsItem] {
        sectionItems(matching: { $0.type != .deadline && !$0.isRecent }, limit: 4)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                header

                statusSection

                if environment.loadState == .loading && newsItems.isEmpty {
                    ProgressView("Laster Poengnytt...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if newsItems.isEmpty {
                    emptyState
                } else {
                    digestContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Poengnytt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign, entryPoint: "news")
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Poengnytt")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Korte, vurderte oppdateringer om det som er nytt, haster eller er verdt å vite akkurat nå.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusSection: some View {
        if case let .failed(message) = environment.loadState, newsItems.isEmpty {
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

    @ViewBuilder
    private var digestContent: some View {
        if let topStory {
            NavigationLink(value: topStory.campaign) {
                NewsLeadStory(item: topStory)
            }
            .buttonStyle(.plain)
        }

        NewsSection(
            eyebrow: "FRISTER",
            title: "Kan forsvinne snart",
            emptyText: "Ingen kontrollerte frister haster akkurat nå.",
            items: deadlineItems
        )

        NewsSection(
            eyebrow: "DENNE UKEN",
            title: "Nytt siden sist",
            emptyText: "Ingen nye publiserte muligheter denne uken.",
            items: thisWeekItems
        )

        NewsSection(
            eyebrow: "VURDERT",
            title: "Verdt å vite",
            emptyText: "Ingen ekstra tips klare ennå.",
            items: worthKnowingItems
        )
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Ingen Poengnytt ennå",
            systemImage: "newspaper",
            description: Text("Når aktuelle kampanjer eller frister er bekreftet, vises de her.")
        )
        .padding(.vertical, 40)
    }

    private func sectionItems(matching predicate: (NewsItem) -> Bool, limit: Int) -> [NewsItem] {
        newsItems
            .filter { $0.id != topStory?.id && predicate($0) }
            .prefix(limit)
            .map { $0 }
    }

    private func primaryProgramName(for campaign: Campaign) -> String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return programsByID[primaryProgramID]?.name
    }
}

private struct NewsItem: Identifiable {
    let campaign: Campaign
    let primaryProgramName: String?

    var id: UUID { campaign.id }

    var type: NewsItemType {
        if campaign.isFeedUrgent {
            return .deadline
        }

        if campaign.isFeedHighValue {
            return .opportunity
        }

        return .campaign
    }

    var title: String {
        campaign.title
    }

    var summary: String {
        campaign.feedReason
    }

    var date: Date {
        campaign.startDate ?? campaign.lastVerifiedAt
    }

    var dateLabel: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    var expiryLabel: String {
        FeedDateHelper.expiryLabel(campaign.endDate).text
    }

    var isRecent: Bool {
        guard let days = daysSince(date) else { return false }
        return days >= 0 && days <= 7
    }

    var editorialAngle: String {
        switch type {
        case .campaign:
            return "Ny kampanje"
        case .deadline:
            return "Siste sjanse"
        case .opportunity:
            return "Poengmulighet"
        }
    }

    static func newsPriority(_ first: NewsItem, _ second: NewsItem) -> Bool {
        if first.type.priority != second.type.priority {
            return first.type.priority > second.type.priority
        }

        if first.campaign.isFeedUrgent != second.campaign.isFeedUrgent {
            return first.campaign.isFeedUrgent
        }

        if first.date != second.date {
            return first.date > second.date
        }

        return (first.campaign.editorialScore ?? 0) > (second.campaign.editorialScore ?? 0)
    }

    private func daysSince(_ date: Date) -> Int? {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: Date())
        ).day
    }
}

private enum NewsItemType {
    case campaign
    case deadline
    case opportunity

    var title: String {
        switch self {
        case .campaign:
            return "Ny kampanje"
        case .deadline:
            return "Frist"
        case .opportunity:
            return "Tips"
        }
    }

    var iconName: String {
        switch self {
        case .campaign:
            return "tag"
        case .deadline:
            return "clock.badge.exclamationmark"
        case .opportunity:
            return "sparkles"
        }
    }

    var priority: Int {
        switch self {
        case .deadline:
            return 90
        case .opportunity:
            return 70
        case .campaign:
            return 50
        }
    }
}

private struct NewsLeadStory: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: item.type.iconName)
                    .font(.subheadline.weight(.bold))
                    .accessibilityHidden(true)

                Text(item.editorialAngle.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(item.dateLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(item.campaign.cardAccent)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    NewsPill(text: item.expiryLabel, tint: item.campaign.cardAccent)

                    if let primaryProgramName = item.primaryProgramName {
                        NewsPill(text: primaryProgramName, tint: PoengjegerTheme.primary)
                    }
                }

                Label("Se detaljene", systemImage: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PoengjegerTheme.primary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.campaign.cardAccent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.campaign.cardAccent.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct NewsSection: View {
    let eyebrow: String
    let title: String
    let emptyText: String
    let items: [NewsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewsSectionHeader(eyebrow: eyebrow, title: title)

            if items.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        NavigationLink(value: item.campaign) {
                            NewsBriefRow(item: item)
                        }
                        .buttonStyle(.plain)

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(PoengjegerTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PoengjegerTheme.border, lineWidth: 1)
                }
            }
        }
    }
}

private struct NewsSectionHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(2.0)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewsBriefRow: View {
    let item: NewsItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.type.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.campaign.cardAccent)
                .frame(width: 36, height: 36)
                .background(item.campaign.cardAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.type.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.campaign.cardAccent)
                        .lineLimit(1)

                    Text(item.expiryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 8)
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct NewsPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        NewsView()
            .environment(AppEnvironment.mock())
    }
}
