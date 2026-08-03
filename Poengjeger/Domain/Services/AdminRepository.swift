import Foundation

struct AdminQueueData {
    let candidates: [IngestionCandidate]
    let isPreview: Bool
    let label: String
}

protocol AdminRepository: Sendable {
    func fetchQueue() async throws -> AdminQueueData
    func setStatus(
        candidateID: UUID,
        status: IngestionCandidate.Status,
        note: String?
    ) async throws -> IngestionCandidate
    func promote(
        candidateID: UUID,
        note: String?
    ) async throws -> IngestionCandidate
}
