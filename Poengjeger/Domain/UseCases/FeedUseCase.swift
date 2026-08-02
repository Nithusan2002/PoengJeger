import Foundation

struct FeedUseCase {
    let repository: CampaignRepository

    func makeFeed(selectedProgramIDs: Set<UUID>) -> [Campaign] {
        repository.fetchActiveCampaigns()
            .filter { $0.matchesSelectedPrograms(selectedProgramIDs) }
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
