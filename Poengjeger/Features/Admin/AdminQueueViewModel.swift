import Foundation
import Observation

@MainActor
@Observable
final class AdminQueueViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let repository: any AdminRepository
    private let errorReporter: any AppErrorReporting

    var selectedStatusFilter: IngestionCandidate.Status?
    var noteDrafts: [UUID: String] = [:]
    private(set) var candidates: [IngestionCandidate] = []
    private(set) var loadState: LoadState = .idle
    private(set) var sourceLabel: String?
    private(set) var infoMessage: String?
    private(set) var isPreview = false
    private(set) var processingCandidateIDs: Set<UUID> = []

    init(
        repository: any AdminRepository,
        errorReporter: any AppErrorReporting = NoopErrorReporter()
    ) {
        self.repository = repository
        self.errorReporter = errorReporter
    }

    var filteredCandidates: [IngestionCandidate] {
        guard let selectedStatusFilter else { return candidates }
        return candidates.filter { $0.status == selectedStatusFilter }
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading

        do {
            let queue = try await repository.fetchQueue()
            candidates = queue.candidates
            sourceLabel = queue.label
            infoMessage = queue.isPreview
                ? "Viser lokal preview-data for admin-flyten. Live admin krever egen admin-session."
                : nil
            isPreview = queue.isPreview
            loadState = .loaded
        } catch {
            errorReporter.capture(.adminQueueLoadFailed, error: error)
            candidates = []
            sourceLabel = nil
            infoMessage = nil
            isPreview = false
            loadState = .failed(
                errorMessage(from: error, fallback: "Kunne ikke laste admin-kø akkurat nå.")
            )
        }
    }

    func note(for candidateID: UUID) -> String {
        noteDrafts[candidateID, default: ""]
    }

    func setNote(_ note: String, for candidateID: UUID) {
        noteDrafts[candidateID] = note
    }

    func isProcessing(_ candidateID: UUID) -> Bool {
        processingCandidateIDs.contains(candidateID)
    }

    func setStatus(
        _ status: IngestionCandidate.Status,
        for candidate: IngestionCandidate
    ) async {
        guard beginProcessing(candidate.id) else { return }
        defer { finishProcessing(candidate.id) }

        do {
            let updated = try await repository.setStatus(
                candidateID: candidate.id,
                status: status,
                note: noteDrafts[candidate.id]
            )
            replaceCandidate(updated)
        } catch {
            errorReporter.capture(.adminCandidateStatusUpdateFailed, error: error)
            loadState = .failed(
                errorMessage(from: error, fallback: "Kunne ikke oppdatere kandidatstatus.")
            )
        }
    }

    func promote(_ candidate: IngestionCandidate) async {
        guard beginProcessing(candidate.id) else { return }
        defer { finishProcessing(candidate.id) }

        do {
            let updated = try await repository.promote(
                candidateID: candidate.id,
                note: noteDrafts[candidate.id]
            )
            replaceCandidate(updated)
        } catch {
            errorReporter.capture(.adminCandidatePromotionFailed, error: error)
            loadState = .failed(
                errorMessage(from: error, fallback: "Kunne ikke promotere kandidat til draft.")
            )
        }
    }

    private func beginProcessing(_ candidateID: UUID) -> Bool {
        processingCandidateIDs.insert(candidateID).inserted
    }

    private func finishProcessing(_ candidateID: UUID) {
        processingCandidateIDs.remove(candidateID)
    }

    private func replaceCandidate(_ candidate: IngestionCandidate) {
        if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
            candidates[index] = candidate
        } else {
            candidates.insert(candidate, at: 0)
        }

        candidates.sort { $0.detectedAt > $1.detectedAt }
        loadState = .loaded
    }

    private func errorMessage(from error: Error, fallback: String) -> String {
        (error as? LocalizedError)?.errorDescription ?? fallback
    }
}
