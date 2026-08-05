import Foundation

enum FeedFilter: String, CaseIterable, Identifiable {
    case all
    case expiringSoon
    case highScore
    case lowFriction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Alle"
        case .expiringSoon:
            return "Snart"
        case .highScore:
            return "Sterke"
        case .lowFriction:
            return "Lav friksjon"
        }
    }
}

struct FeedUseCase {
    func makeFeed(
        campaigns: [Campaign],
        selectedProgramIDs: Set<UUID>,
        filter: FeedFilter = .all,
        referenceDate: Date = Date()
    ) -> [Campaign] {
        campaigns
            .filter { $0.matchesSelectedPrograms(selectedProgramIDs) }
            .filter { campaign in
                switch filter {
                case .all:
                    return true
                case .expiringSoon:
                    guard let endDate = campaign.endDate else { return false }
                    let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: referenceDate) ?? referenceDate
                    return endDate >= referenceDate && endDate <= sevenDaysFromNow
                case .highScore:
                    return (campaign.editorialScore ?? 0) >= 75
                case .lowFriction:
                    return campaign.editorialAssessment?.difficultyLevel == .low
                }
            }
            .sorted { lhs, rhs in
                switch (lhs.editorialScore, rhs.editorialScore) {
                case let (left?, right?):
                    if left != right {
                        return left > right
                    }
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    break
                }

                return lhs.lastVerifiedAt > rhs.lastVerifiedAt
            }
    }
}
