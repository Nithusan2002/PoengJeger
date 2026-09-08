import Foundation
import OSLog

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

enum AppErrorEvent: String, Sendable {
    case bootstrapLoadFailed = "bootstrap_load_failed"
    case adminQueueLoadFailed = "admin_queue_load_failed"
    case adminCandidateStatusUpdateFailed = "admin_candidate_status_update_failed"
    case adminCandidatePromotionFailed = "admin_candidate_promotion_failed"
}

protocol AppErrorReporting: Sendable {
    func capture(_ event: AppErrorEvent, error: any Error)
}

struct UnifiedLogErrorReporter: AppErrorReporting {
    private let logger = Logger(subsystem: "no.poengjeger.app", category: "errors")

    func capture(_ event: AppErrorEvent, error: any Error) {
        let errorType = String(reflecting: type(of: error))
        logger.error("Event: \(event.rawValue, privacy: .public); error_type: \(errorType, privacy: .public)")
    }
}

struct NoopErrorReporter: AppErrorReporting {
    func capture(_ event: AppErrorEvent, error: any Error) {}
}
