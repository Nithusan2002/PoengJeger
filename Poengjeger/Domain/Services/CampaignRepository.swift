import Foundation

protocol CampaignRepository {
    func fetchPrograms() -> [BonusProgram]
    func fetchActiveCampaigns() -> [Campaign]
    func fetchFavorites(for favoriteIDs: Set<UUID>) -> [Campaign]
}
