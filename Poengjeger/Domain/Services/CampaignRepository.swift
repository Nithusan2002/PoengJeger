import Foundation

struct CampaignBootstrapData: Sendable {
    let programs: [BonusProgram]
    let campaigns: [Campaign]
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
