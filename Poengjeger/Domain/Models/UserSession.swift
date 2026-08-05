import Foundation

struct UserSession: Codable, Equatable {
    var selectedProgramIDs: Set<UUID>
    var favoriteCampaignIDs: Set<UUID>
    var notificationsEnabled: Bool = false
}
