import Foundation

struct IngestionCandidate: Identifiable, Hashable {
    enum Status: String, CaseIterable, Hashable {
        case new
        case needsReview = "needs_review"
        case approved
        case rejected
        case promoted

        var title: String {
            switch self {
            case .new:
                return "Ny"
            case .needsReview:
                return "Trenger review"
            case .approved:
                return "Godkjent"
            case .rejected:
                return "Avvist"
            case .promoted:
                return "Promotert"
            }
        }
    }

    let id: UUID
    let status: Status
    let detectedAt: Date
    let sourceURL: URL
    let title: String
    let summary: String
    let reviewNote: String?
    let promotedCampaignID: UUID?
    let sourceName: String
    let ingestKind: String
    let suggestedProgramName: String?
    let suggestedCategoryName: String?

    var canReview: Bool {
        status != .promoted
    }

    var canPromote: Bool {
        status == .new || status == .needsReview || status == .approved
    }
}
