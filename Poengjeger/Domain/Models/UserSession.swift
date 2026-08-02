import Foundation

struct UserSession {
    var selectedProgramIDs: Set<UUID>
    var favoriteCampaignIDs: Set<UUID>
    var notificationsEnabled: Bool = false
}
