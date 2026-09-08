import Foundation
import Testing
@testable import Poengjeger

@Suite(.serialized)
struct AdminIngestionUseCaseTests {
    @Test
    func candidateCapabilitiesFollowEditorialWorkflow() {
        #expect(makeCandidate(status: .new).canReview)
        #expect(makeCandidate(status: .new).canPromote)
        #expect(makeCandidate(status: .needsReview).canReview)
        #expect(makeCandidate(status: .needsReview).canPromote)
        #expect(makeCandidate(status: .approved).canReview)
        #expect(makeCandidate(status: .approved).canPromote)
        #expect(makeCandidate(status: .rejected).canReview)
        #expect(!makeCandidate(status: .rejected).canPromote)
        #expect(!makeCandidate(status: .promoted).canReview)
        #expect(!makeCandidate(status: .promoted).canPromote)
    }

    @Test
    func mockAdminRepositoryReturnsPreviewQueueSortedByDetectedDate() async throws {
        let older = makeCandidate(detectedAt: Date(timeIntervalSince1970: 100), title: "Eldre")
        let newer = makeCandidate(detectedAt: Date(timeIntervalSince1970: 200), title: "Nyere")
        let repository = MockAdminRepository(candidates: [older, newer])

        let queue = try await repository.fetchQueue()
        let titles = queue.candidates.map { $0.title }

        #expect(queue.isPreview)
        #expect(queue.label == "Preview-kø")
        #expect(titles == ["Nyere", "Eldre"])
    }

    @Test
    func mockAdminRepositoryPreservesReviewNoteAndCreatesPromotionIDOnlyWhenPromoted() async throws {
        let candidate = makeCandidate(
            status: .needsReview,
            reviewNote: "Mangler tydelig sluttdato."
        )
        let repository = MockAdminRepository(candidates: [candidate])

        let approved = try await repository.setStatus(
            candidateID: candidate.id,
            status: .approved,
            note: nil
        )

        #expect(approved.status == .approved)
        #expect(approved.reviewNote == "Mangler tydelig sluttdato.")
        #expect(approved.promotedCampaignID == nil)

        let promoted = try await repository.promote(candidateID: candidate.id, note: nil)

        #expect(promoted.status == .promoted)
        #expect(promoted.reviewNote == "Promotert til draft i preview-flyten.")
        #expect(promoted.promotedCampaignID != nil)
    }

    @Test
    func mockAdminRepositoryThrowsLocalizedNotFoundErrorForUnknownCandidate() async {
        let repository = MockAdminRepository(candidates: [])

        do {
            _ = try await repository.setStatus(candidateID: UUID(), status: IngestionCandidate.Status.approved, note: nil)
            Issue.record("Expected not found error")
        } catch {
            if case AdminRepositoryError.notFound = error {
                // Expected path.
            } else {
                Issue.record("Expected AdminRepositoryError.notFound")
            }
            #expect((error as? LocalizedError)?.errorDescription == "Fant ikke valgt kandidat i admin-køen.")
        }
    }

    @MainActor
    @Test
    func adminQueueViewModelLoadsPreviewQueueAndSkipsDuplicateInitialLoad() async {
        let firstCandidate = makeCandidate(title: "Første")
        let repository = CountingAdminRepository(
            queue: AdminQueueData(
                candidates: [firstCandidate],
                isPreview: true,
                label: "Test-kø"
            )
        )
        let viewModel = AdminQueueViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        let fetchCount = await repository.fetchCount
        let candidateIDs = viewModel.candidates.map { $0.id }

        #expect(fetchCount == 1)
        #expect(viewModel.loadState == .loaded)
        #expect(candidateIDs == [firstCandidate.id])
        #expect(viewModel.sourceLabel == "Test-kø")
        #expect(viewModel.infoMessage == "Viser lokal preview-data for admin-flyten. Live admin krever egen admin-session.")
        #expect(viewModel.isPreview)
    }

    @MainActor
    @Test
    func adminQueueViewModelReplacesUpdatedCandidateAndKeepsQueueSorted() async {
        let older = makeCandidate(detectedAt: Date(timeIntervalSince1970: 100), title: "Eldre")
        let newer = makeCandidate(detectedAt: Date(timeIntervalSince1970: 200), title: "Nyere")
        let repository = MockAdminRepository(candidates: [older, newer])
        let viewModel = AdminQueueViewModel(repository: repository)

        await viewModel.refresh()
        viewModel.setNote("Relevant for MVP-program.", for: older.id)
        await viewModel.setStatus(.approved, for: older)
        let titles = viewModel.candidates.map { $0.title }
        let updatedCandidate = viewModel.candidates.first { $0.id == older.id }

        #expect(viewModel.loadState == .loaded)
        #expect(titles == ["Nyere", "Eldre"])
        #expect(updatedCandidate?.status == IngestionCandidate.Status.approved)
        #expect(updatedCandidate?.reviewNote == "Relevant for MVP-program.")
    }

    @MainActor
    @Test
    func adminQueueViewModelClearsPreviewStateWhenQueueFailsToLoad() async {
        let viewModel = AdminQueueViewModel(
            repository: PreviewThenFailAdminRepository(candidate: makeCandidate())
        )
        await viewModel.refresh()
        #expect(viewModel.isPreview)

        await viewModel.refresh()

        #expect(viewModel.candidates.isEmpty)
        #expect(viewModel.sourceLabel == nil)
        #expect(viewModel.infoMessage == nil)
        #expect(!viewModel.isPreview)
        #expect(viewModel.loadState == .failed("Admin utilgjengelig"))
    }

    @MainActor
    @Test
    func adminQueueViewModelFiltersCandidatesAndKeepsIndependentNotes() async {
        let approved = makeCandidate(status: .approved, title: "Godkjent")
        let rejected = makeCandidate(status: .rejected, title: "Avvist")
        let viewModel = AdminQueueViewModel(repository: MockAdminRepository())

        viewModel.selectedStatusFilter = .approved
        viewModel.setNote("Kontrollert", for: approved.id)

        let populatedViewModel = AdminQueueViewModel(
            repository: MockAdminRepository(candidates: [approved, rejected])
        )
        populatedViewModel.selectedStatusFilter = .approved
        await populatedViewModel.refresh()

        #expect(populatedViewModel.filteredCandidates.map(\.id) == [approved.id])
        #expect(viewModel.note(for: approved.id) == "Kontrollert")
        #expect(viewModel.note(for: rejected.id).isEmpty)
    }

    @MainActor
    @Test
    func adminQueueViewModelPromotesCandidateAndClearsProcessingState() async {
        let candidate = makeCandidate(status: .approved)
        let repository = MockAdminRepository(candidates: [candidate])
        let viewModel = AdminQueueViewModel(repository: repository)
        viewModel.setNote("Klar for utkast", for: candidate.id)
        await viewModel.refresh()

        await viewModel.promote(candidate)

        #expect(viewModel.candidates.first?.status == .promoted)
        #expect(viewModel.candidates.first?.reviewNote == "Klar for utkast")
        #expect(!viewModel.isProcessing(candidate.id))
    }

    private func makeCandidate(
        id: UUID = UUID(),
        status: IngestionCandidate.Status = .new,
        detectedAt: Date = Date(timeIntervalSince1970: 100),
        title: String = "Testkandidat",
        reviewNote: String? = nil,
        promotedCampaignID: UUID? = nil
    ) -> IngestionCandidate {
        IngestionCandidate(
            id: id,
            status: status,
            detectedAt: detectedAt,
            sourceURL: URL(string: "https://example.com/kampanje")!,
            title: title,
            summary: "Oppdaget kampanje som må kontrolleres redaksjonelt.",
            reviewNote: reviewNote,
            promotedCampaignID: promotedCampaignID,
            sourceName: "Eksempelkilde",
            ingestKind: "html_page",
            suggestedProgramName: "Trumf",
            suggestedCategoryName: "Netthandel"
        )
    }
}

private actor CountingAdminRepository: AdminRepository {
    private let queue: AdminQueueData
    private(set) var fetchCount = 0

    init(queue: AdminQueueData) {
        self.queue = queue
    }

    func fetchQueue() async throws -> AdminQueueData {
        fetchCount += 1
        return queue
    }

    func setStatus(candidateID: UUID, status: IngestionCandidate.Status, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.notFound
    }

    func promote(candidateID: UUID, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.notFound
    }
}

private actor PreviewThenFailAdminRepository: AdminRepository {
    private let candidate: IngestionCandidate
    private var hasFetched = false

    init(candidate: IngestionCandidate) {
        self.candidate = candidate
    }

    func fetchQueue() async throws -> AdminQueueData {
        guard !hasFetched else {
            throw AdminRepositoryError.unavailable("Admin utilgjengelig")
        }
        hasFetched = true
        return AdminQueueData(candidates: [candidate], isPreview: true, label: "Preview-kø")
    }

    func setStatus(
        candidateID: UUID,
        status: IngestionCandidate.Status,
        note: String?
    ) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable("Admin utilgjengelig")
    }

    func promote(candidateID: UUID, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable("Admin utilgjengelig")
    }
}
