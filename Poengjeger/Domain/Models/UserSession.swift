import Foundation

struct UserSession: Codable, Equatable, Sendable {
    var selectedProgramIDs: Set<UUID>
    var favoriteCampaignIDs: Set<UUID>
    var favoriteStoreIDs: Set<UUID>
    var notificationsEnabled: Bool = false

    init(
        selectedProgramIDs: Set<UUID>,
        favoriteCampaignIDs: Set<UUID>,
        favoriteStoreIDs: Set<UUID> = [],
        notificationsEnabled: Bool = false
    ) {
        self.selectedProgramIDs = selectedProgramIDs
        self.favoriteCampaignIDs = favoriteCampaignIDs
        self.favoriteStoreIDs = favoriteStoreIDs
        self.notificationsEnabled = notificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedProgramIDs = try container.decode(Set<UUID>.self, forKey: .selectedProgramIDs)
        favoriteCampaignIDs = try container.decode(Set<UUID>.self, forKey: .favoriteCampaignIDs)
        favoriteStoreIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .favoriteStoreIDs) ?? []
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
    }
}
