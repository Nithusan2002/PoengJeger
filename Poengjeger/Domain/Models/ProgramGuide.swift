import Foundation

struct ProgramGuide: Identifiable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case draft
        case published
        case archived
    }

    let id: UUID
    let programID: UUID
    let status: Status
    let introText: String?
    let strategy: String
    let valueEstimateLabel: String?
    let valueEstimateDetail: String?
    let expirationSummary: String?
    let expirationDetail: String?
    let earningTips: [String]
    let redemptionTips: [String]
    let riskNotes: [String]
    let lastReviewedAt: Date?
}
