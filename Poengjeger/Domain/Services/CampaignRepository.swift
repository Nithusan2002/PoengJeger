import Foundation

struct CampaignBootstrapData: Sendable {
    let programs: [BonusProgram]
    let programGuides: [ProgramGuide]
    let campaigns: [Campaign]
    let stores: [Store]
    let dataSource: CampaignDataSource
}

enum CampaignDataSource: Equatable, Sendable {
    case supabase
    case mock(reason: String?)

    var label: String {
        switch self {
        case .supabase:
            return "Supabase"
        case let .mock(reason):
            if let reason, !reason.isEmpty {
                return "Mock-data (\(reason))"
            }
            return "Mock-data"
        }
    }

    var isFallback: Bool {
        if case .mock = self {
            return true
        }
        return false
    }
}

protocol CampaignRepository: Sendable {
    func fetchBootstrapData() async throws -> CampaignBootstrapData
}

struct ProductAnalyticsEvent: Sendable {
    let name: String
    let surface: String?
    let entityType: String?
    let entityID: UUID?
    let properties: [String: String]

    init(
        name: String,
        surface: String? = nil,
        entityType: String? = nil,
        entityID: UUID? = nil,
        properties: [String: String] = [:]
    ) {
        self.name = name
        self.surface = surface
        self.entityType = entityType
        self.entityID = entityID
        self.properties = properties
    }
}

protocol ProductAnalytics: Sendable {
    func track(_ event: ProductAnalyticsEvent) async
}
