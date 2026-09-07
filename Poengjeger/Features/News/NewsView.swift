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
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
                header

                statusSection

                if environment.loadState == .loading && newsItems.isEmpty {
                    ProgressView("Laster Poengnytt...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, DesignTokens.Spacing.spacious)
                } else if newsItems.isEmpty {
                    emptyState
                } else {
                    digestContent
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.comfortable)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Campaign.self) { campaign in
            CampaignDetailView(campaign: campaign, entryPoint: "news")
        }
        .refreshable {
            await environment.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Poengnytt")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Nye muligheter og frister som er verdt å få med seg.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
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
                .font(DesignTokens.Typography.captionSemibold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .padding(.horizontal, DesignTokens.Spacing.controlGap)
                .padding(.vertical, DesignTokens.Spacing.small)
                .background(DesignTokens.Colors.brandPrimarySoft)
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
            items: deadlineItems
        )

        NewsSection(
            eyebrow: "DENNE UKEN",
            title: "Nytt siden sist",
            items: thisWeekItems
        )

        NewsSection(
            eyebrow: "VURDERT",
            title: "Verdt å vite",
            items: worthKnowingItems
        )
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Ingen Poengnytt ennå",
            systemImage: "newspaper",
            description: Text("Når aktuelle kampanjer eller frister er bekreftet, vises de her.")
        )
        .padding(.vertical, DesignTokens.Spacing.spacious)
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
            return "Aktuell kampanje"
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
            return "Aktuell"
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: item.type.iconName)
                    .font(DesignTokens.Typography.subheadlineBold)
                    .accessibilityHidden(true)

                Text(item.editorialAngle.uppercased())
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(1.8)
                    .lineLimit(1)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Text(item.dateLabel)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
            }
            .foregroundStyle(item.campaign.cardAccent)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                Text(item.title)
                    .font(DesignTokens.Typography.editorialTitle2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.summary)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
                HStack(spacing: DesignTokens.Spacing.controlGap) {
                    NewsPill(text: item.expiryLabel, tint: item.campaign.cardAccent)

                    if let primaryProgramName = item.primaryProgramName {
                        NewsPill(text: primaryProgramName, tint: DesignTokens.Colors.brandPrimary)
                    }
                }

                Label("Se detaljene", systemImage: "chevron.right")
                    .font(DesignTokens.Typography.captionBold)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.campaign.cardAccent.opacity(DesignTokens.Opacity.subtle))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(item.campaign.cardAccent.opacity(DesignTokens.Opacity.medium), lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct NewsSection: View {
    let eyebrow: String
    let title: String
    let items: [NewsItem]

    @ViewBuilder
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.controlGap) {
                NewsSectionHeader(eyebrow: eyebrow, title: title)

                LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.none) {
                    ForEach(items) { item in
                        NavigationLink(value: item.campaign) {
                            NewsBriefRow(item: item)
                        }
                        .buttonStyle(.plain)

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, DesignTokens.Spacing.iconLeadingInset)
                        }
                    }
                }
                .background(DesignTokens.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                        .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                }
            }
        }
    }
}

private struct NewsSectionHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
            Text(eyebrow)
                .font(DesignTokens.Typography.captionBold)
                .tracking(2.0)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(title)
                .font(DesignTokens.Typography.editorialTitle3)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewsBriefRow: View {
    let item: NewsItem

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
            Image(systemName: item.type.iconName)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(item.campaign.cardAccent)
                .frame(width: 36, height: 36)
                .background(item.campaign.cardAccent.opacity(DesignTokens.Opacity.soft))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    Text(item.type.title)
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(item.campaign.cardAccent)
                        .lineLimit(1)

                    Text(item.expiryLabel)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)

                    Spacer(minLength: DesignTokens.Spacing.medium)
                }

                Text(item.title)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.summary)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.captionBold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.top, DesignTokens.Spacing.controlGap)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.standardPlus)
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
            .font(DesignTokens.Typography.captionBold)
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, DesignTokens.Spacing.mediumPlus)
            .padding(.vertical, DesignTokens.Spacing.compact)
            .background(tint.opacity(DesignTokens.Opacity.soft))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        NewsView()
            .environment(AppEnvironment.mock())
    }
}
