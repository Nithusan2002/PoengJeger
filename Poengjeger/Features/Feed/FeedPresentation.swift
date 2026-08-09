import Foundation

enum FeedSort: String, CaseIterable, Identifiable {
    case expiringFirst
    case newest
    case alphabetic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expiringFirst:
            return "Utløper først"
        case .newest:
            return "Nyeste"
        case .alphabetic:
            return "A-Å"
        }
    }
}

struct ExpiryDisplay: Equatable {
    let text: String
    let urgent: Bool
}

enum FeedDateHelper {
    static func daysUntil(_ date: Date?, referenceDate: Date = Date()) -> Int? {
        guard let date else { return nil }
        let startOfReferenceDate = Calendar.current.startOfDay(for: referenceDate)
        let startOfDate = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: startOfReferenceDate, to: startOfDate).day
    }

    static func expiryLabel(_ date: Date?, referenceDate: Date = Date()) -> ExpiryDisplay {
        guard let days = daysUntil(date, referenceDate: referenceDate) else {
            return ExpiryDisplay(text: "Løpende", urgent: false)
        }

        switch days {
        case ..<0:
            return ExpiryDisplay(text: "Utløpt", urgent: true)
        case 0:
            return ExpiryDisplay(text: "Siste dag", urgent: true)
        case 1:
            return ExpiryDisplay(text: "1 dag igjen", urgent: true)
        case 2...3:
            return ExpiryDisplay(text: "\(days) dager igjen", urgent: true)
        default:
            return ExpiryDisplay(text: "\(days) dager igjen", urgent: false)
        }
    }
}

struct ScannableFeedUseCase {
    func makeFeed(
        campaigns: [Campaign],
        selectedProgramIDs: Set<UUID>,
        showsAllPrograms: Bool,
        selectedCategoryID: UUID?,
        searchText: String,
        sort: FeedSort,
        referenceDate: Date = Date()
    ) -> [Campaign] {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return campaigns
            .filter { campaign in
                guard campaign.status == .published else { return false }
                if let startDate = campaign.startDate, startDate > referenceDate {
                    return false
                }
                if let days = FeedDateHelper.daysUntil(campaign.endDate, referenceDate: referenceDate), days < 0 {
                    return false
                }
                return true
            }
            .filter { campaign in
                showsAllPrograms || selectedProgramIDs.isEmpty || campaign.matchesSelectedPrograms(selectedProgramIDs)
            }
            .filter { campaign in
                selectedCategoryID == nil || campaign.category?.id == selectedCategoryID
            }
            .filter { campaign in
                guard !normalizedSearchText.isEmpty else { return true }
                let searchableText = "\(campaign.title) \(campaign.summary) \(campaign.editorialSummary)".lowercased()
                return searchableText.contains(normalizedSearchText)
            }
            .sorted { lhs, rhs in
                switch sort {
                case .expiringFirst:
                    return compareByExpiry(lhs, rhs, referenceDate: referenceDate)
                case .newest:
                    return (lhs.startDate ?? .distantPast) > (rhs.startDate ?? .distantPast)
                case .alphabetic:
                    return lhs.title.compare(rhs.title, locale: Locale(identifier: "nb")) == .orderedAscending
                }
            }
    }

    private func compareByExpiry(_ lhs: Campaign, _ rhs: Campaign, referenceDate: Date) -> Bool {
        switch (
            FeedDateHelper.daysUntil(lhs.endDate, referenceDate: referenceDate),
            FeedDateHelper.daysUntil(rhs.endDate, referenceDate: referenceDate)
        ) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
            return (lhs.editorialScore ?? 0) > (rhs.editorialScore ?? 0)
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return (lhs.editorialScore ?? 0) > (rhs.editorialScore ?? 0)
        }
    }
}
