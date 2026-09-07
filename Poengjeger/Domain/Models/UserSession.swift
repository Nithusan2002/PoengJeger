import Foundation

enum AppearancePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Lys"
        case .dark: return "Mørk"
        }
    }
}

struct UserSession: Codable, Equatable, Sendable {
    var selectedProgramIDs: Set<UUID>
    var favoriteCampaignIDs: Set<UUID>
    var favoriteStoreIDs: Set<UUID>
    var notificationsEnabled: Bool = false
    var appearancePreference: AppearancePreference = .system

    var prefersDarkMode: Bool {
        get { appearancePreference == .dark }
        set { appearancePreference = newValue ? .dark : .system }
    }

    init(
        selectedProgramIDs: Set<UUID>,
        favoriteCampaignIDs: Set<UUID>,
        favoriteStoreIDs: Set<UUID> = [],
        notificationsEnabled: Bool = false,
        prefersDarkMode: Bool = false
    ) {
        self.selectedProgramIDs = selectedProgramIDs
        self.favoriteCampaignIDs = favoriteCampaignIDs
        self.favoriteStoreIDs = favoriteStoreIDs
        self.notificationsEnabled = notificationsEnabled
        appearancePreference = prefersDarkMode ? .dark : .system
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedProgramIDs = try container.decode(Set<UUID>.self, forKey: .selectedProgramIDs)
        favoriteCampaignIDs = try container.decode(Set<UUID>.self, forKey: .favoriteCampaignIDs)
        favoriteStoreIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .favoriteStoreIDs) ?? []
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        if let savedPreference = try container.decodeIfPresent(AppearancePreference.self, forKey: .appearancePreference) {
            appearancePreference = savedPreference
        } else {
            let legacyDarkMode = try container.decodeIfPresent(Bool.self, forKey: .prefersDarkMode) ?? false
            appearancePreference = legacyDarkMode ? .dark : .system
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedProgramIDs, forKey: .selectedProgramIDs)
        try container.encode(favoriteCampaignIDs, forKey: .favoriteCampaignIDs)
        try container.encode(favoriteStoreIDs, forKey: .favoriteStoreIDs)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(appearancePreference, forKey: .appearancePreference)
    }

    private enum CodingKeys: String, CodingKey {
        case selectedProgramIDs
        case favoriteCampaignIDs
        case favoriteStoreIDs
        case notificationsEnabled
        case prefersDarkMode
        case appearancePreference
    }
}
