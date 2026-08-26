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
    func appEnvironmentLoadsPreviewAdminQueueAndSkipsDuplicateInitialLoad() async {
        let firstCandidate = makeCandidate(title: "Første")
        let repository = CountingAdminRepository(
            queue: AdminQueueData(
                candidates: [firstCandidate],
                isPreview: true,
                label: "Test-kø"
            )
        )
        let environment = AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: repository,
            userSession: UserSession(selectedProgramIDs: [], favoriteCampaignIDs: []),
            userSessionStore: InMemoryUserSessionStore()
        )

        await environment.loadAdminQueueIfNeeded()
        await environment.loadAdminQueueIfNeeded()

        let fetchCount = await repository.fetchCount
        let candidateIDs = environment.adminCandidates.map { $0.id }

        #expect(fetchCount == 1)
        #expect(environment.adminLoadState == AppEnvironment.LoadState.loaded)
        #expect(candidateIDs == [firstCandidate.id])
        #expect(environment.adminSourceLabel == "Test-kø")
        #expect(environment.adminInfoMessage == "Viser lokal preview-data for admin-flyten. Live admin krever egen admin-session.")
        #expect(environment.isAdminPreview)
    }

    @MainActor
    @Test
    func appEnvironmentReplacesUpdatedCandidateAndKeepsQueueSorted() async {
        let older = makeCandidate(detectedAt: Date(timeIntervalSince1970: 100), title: "Eldre")
        let newer = makeCandidate(detectedAt: Date(timeIntervalSince1970: 200), title: "Nyere")
        let repository = MockAdminRepository(candidates: [older, newer])
        let environment = AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: repository,
            userSession: UserSession(selectedProgramIDs: [], favoriteCampaignIDs: []),
            userSessionStore: InMemoryUserSessionStore()
        )

        await environment.refreshAdminQueue()
        await environment.setAdminCandidateStatus(
            candidateID: older.id,
            status: IngestionCandidate.Status.approved,
            note: "Relevant for MVP-program."
        )
        let titles = environment.adminCandidates.map { $0.title }
        let updatedCandidate = environment.adminCandidates.first { $0.id == older.id }

        #expect(environment.adminLoadState == AppEnvironment.LoadState.loaded)
        #expect(titles == ["Nyere", "Eldre"])
        #expect(updatedCandidate?.status == IngestionCandidate.Status.approved)
        #expect(updatedCandidate?.reviewNote == "Relevant for MVP-program.")
    }

    @MainActor
    @Test
    func appEnvironmentClearsAdminPreviewStateWhenQueueFailsToLoad() async {
        let environment = AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: FailingAdminRepository(),
            userSession: UserSession(selectedProgramIDs: [], favoriteCampaignIDs: []),
            userSessionStore: InMemoryUserSessionStore()
        )
        environment.adminCandidates = [makeCandidate()]
        environment.adminSourceLabel = "Gammel kø"
        environment.adminInfoMessage = "Gammel melding"
        environment.isAdminPreview = true

        await environment.refreshAdminQueue()

        #expect(environment.adminCandidates.isEmpty)
        #expect(environment.adminSourceLabel == nil)
        #expect(environment.adminInfoMessage == nil)
        #expect(!environment.isAdminPreview)
        #expect(environment.adminLoadState == AppEnvironment.LoadState.failed("Admin utilgjengelig"))
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

private struct FailingAdminRepository: AdminRepository {
    func fetchQueue() async throws -> AdminQueueData {
        throw AdminRepositoryError.unavailable("Admin utilgjengelig")
    }

    func setStatus(candidateID: UUID, status: IngestionCandidate.Status, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable("Admin utilgjengelig")
    }

    func promote(candidateID: UUID, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable("Admin utilgjengelig")
    }
}
