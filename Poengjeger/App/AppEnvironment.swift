import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let campaignRepository: CampaignRepository
    let adminRepository: AdminRepository
    @ObservationIgnored
    private let userSessionStore: UserSessionStore
    var userSession: UserSession {
        didSet {
            userSessionStore.save(userSession)
        }
    }
    var programs: [BonusProgram] = []
    var programGuides: [ProgramGuide] = []
    var campaigns: [Campaign] = []
    var loadState: LoadState = .idle
    var dataSource: CampaignDataSource?
    var adminCandidates: [IngestionCandidate] = []
    var adminLoadState: LoadState = .idle
    var adminSourceLabel: String?
    var adminInfoMessage: String?
    var isAdminPreview = false

    init(
        campaignRepository: CampaignRepository,
        adminRepository: AdminRepository,
        userSession: UserSession,
        userSessionStore: UserSessionStore = UserDefaultsUserSessionStore()
    ) {
        self.campaignRepository = campaignRepository
        self.adminRepository = adminRepository
        self.userSessionStore = userSessionStore
        self.userSession = userSessionStore.load() ?? userSession
    }

    static func live() -> AppEnvironment {
        let repository: CampaignRepository
        let adminRepository: AdminRepository

        if let configuration = SupabaseConfiguration.fromBundle() {
            repository = SupabaseCampaignRepository(configuration: configuration)
            adminRepository = UnavailableAdminRepository(
                reason: "Live admin krever egen admin-innlogging eller et separat adminverktøy. Denne iOS-klienten bruker bare publiserbar nøkkel."
            )
        } else {
            repository = MissingSupabaseConfigurationRepository()
            adminRepository = UnavailableAdminRepository(
                reason: "Admin-kø er utilgjengelig før appkonfigurasjonen og admin-laget er koblet opp."
            )
        }

        return AppEnvironment(
            campaignRepository: repository,
            adminRepository: adminRepository,
            userSession: .empty
        )
    }

    static func mock() -> AppEnvironment {
        AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: MockAdminRepository(),
            userSession: .empty,
            userSessionStore: InMemoryUserSessionStore()
        )
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await refresh()
    }

    func refresh() async {
        loadState = .loading

        do {
            let repository = campaignRepository
            let bootstrapData = try await repository.fetchBootstrapData()
            programs = bootstrapData.programs
            programGuides = bootstrapData.programGuides
            campaigns = bootstrapData.campaigns
            dataSource = bootstrapData.dataSource
            userSession.selectedProgramIDs.formIntersection(Set(programs.map(\.id)))
            loadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Kunne ikke hente kampanjedata akkurat nå."
            loadState = .failed(message)
        }
    }

    var favoriteCampaigns: [Campaign] {
        campaigns.filter { userSession.favoriteCampaignIDs.contains($0.id) }
    }

    var firstPhasePrograms: [BonusProgram] {
        programs
            .filter { $0.isActive && $0.isFirstPhaseProgram }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var selectedFirstPhaseProgramIDs: Set<UUID> {
        let firstPhaseProgramIDs = Set(firstPhasePrograms.map(\.id))
        return userSession.selectedProgramIDs.intersection(firstPhaseProgramIDs)
    }

    var firstPhaseCampaigns: [Campaign] {
        let firstPhaseProgramIDs = Set(firstPhasePrograms.map(\.id))
        guard !firstPhaseProgramIDs.isEmpty else { return [] }
        return campaigns.filter { campaign in
            campaign.linkedProgramIDs.contains { firstPhaseProgramIDs.contains($0) }
        }
    }

    func programGuide(for program: BonusProgram) -> ProgramGuide? {
        programGuides.first { $0.programID == program.id && $0.status == .published }
    }

    func loadAdminQueueIfNeeded() async {
        guard adminLoadState == .idle else { return }
        await refreshAdminQueue()
    }

    func refreshAdminQueue() async {
        adminLoadState = .loading

        do {
            let queue = try await adminRepository.fetchQueue()
            adminCandidates = queue.candidates
            adminSourceLabel = queue.label
            adminInfoMessage = queue.isPreview ? "Viser lokal preview-data for admin-flyten. Live admin krever egen admin-session." : nil
            isAdminPreview = queue.isPreview
            adminLoadState = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Kunne ikke laste admin-kø akkurat nå."
            adminCandidates = []
            adminSourceLabel = nil
            adminInfoMessage = nil
            isAdminPreview = false
            adminLoadState = .failed(message)
        }
    }

    func setAdminCandidateStatus(candidateID: UUID, status: IngestionCandidate.Status, note: String?) async {
        do {
            let updated = try await adminRepository.setStatus(
                candidateID: candidateID,
                status: status,
                note: note
            )
            replaceAdminCandidate(updated)
        } catch {
            adminLoadState = .failed((error as? LocalizedError)?.errorDescription ?? "Kunne ikke oppdatere kandidatstatus.")
        }
    }

    func promoteAdminCandidate(candidateID: UUID, note: String?) async {
        do {
            let updated = try await adminRepository.promote(candidateID: candidateID, note: note)
            replaceAdminCandidate(updated)
        } catch {
            adminLoadState = .failed((error as? LocalizedError)?.errorDescription ?? "Kunne ikke promotere kandidat til draft.")
        }
    }

    private func replaceAdminCandidate(_ candidate: IngestionCandidate) {
        if let index = adminCandidates.firstIndex(where: { $0.id == candidate.id }) {
            adminCandidates[index] = candidate
        } else {
            adminCandidates.insert(candidate, at: 0)
        }

        adminCandidates.sort { $0.detectedAt > $1.detectedAt }
        adminLoadState = .loaded
    }
}

private struct MissingSupabaseConfigurationRepository: CampaignRepository {
    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        throw MissingSupabaseConfigurationError()
    }
}

private struct UnavailableAdminRepository: AdminRepository {
    let reason: String

    func fetchQueue() async throws -> AdminQueueData {
        throw AdminRepositoryError.unavailable(reason)
    }

    func setStatus(candidateID: UUID, status: IngestionCandidate.Status, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable(reason)
    }

    func promote(candidateID: UUID, note: String?) async throws -> IngestionCandidate {
        throw AdminRepositoryError.unavailable(reason)
    }
}

private struct MissingSupabaseConfigurationError: LocalizedError {
    var errorDescription: String? {
        "SUPABASE_HOST eller SUPABASE_PUBLISHABLE_KEY mangler i appkonfigurasjonen."
    }
}

private extension UserSession {
    static let empty = UserSession(selectedProgramIDs: [], favoriteCampaignIDs: [])
}
