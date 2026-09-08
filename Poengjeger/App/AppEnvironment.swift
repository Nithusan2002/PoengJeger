import Foundation
import Observation
import OSLog

enum PerformanceBenchmarks {
    static let firstUsableContentMilliseconds = 2_000.0
    static let apiResponseMilliseconds = 300.0

    static func milliseconds(from duration: Duration) -> Double {
        let components = duration.components
        return (Double(components.seconds) * 1_000)
            + (Double(components.attoseconds) / 1_000_000_000_000_000)
    }
}

@MainActor
@Observable
final class AppEnvironment {
    private static let performanceLogger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "no.poengjeger.app",
        category: "Performance"
    )

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let campaignRepository: CampaignRepository
    private let adminRepository: AdminRepository
    private let productAnalytics: ProductAnalytics
    private let errorReporter: any AppErrorReporting
    @ObservationIgnored
    private let userSessionStore: UserSessionStore
    @ObservationIgnored
    private let startupStartedAt = ContinuousClock.now
    @ObservationIgnored
    private var hasReportedStartup = false
    var userSession: UserSession {
        didSet {
            userSessionStore.save(userSession)
        }
    }
    var programs: [BonusProgram] = []
    var programGuides: [ProgramGuide] = []
    var campaigns: [Campaign] = []
    var stores: [Store] = []
    var loadState: LoadState = .idle
    var dataSource: CampaignDataSource?

    init(
        campaignRepository: CampaignRepository,
        adminRepository: AdminRepository,
        productAnalytics: ProductAnalytics,
        userSession: UserSession,
        userSessionStore: UserSessionStore = UserDefaultsUserSessionStore(),
        errorReporter: any AppErrorReporting = NoopErrorReporter()
    ) {
        self.campaignRepository = campaignRepository
        self.adminRepository = adminRepository
        self.productAnalytics = productAnalytics
        self.userSessionStore = userSessionStore
        self.errorReporter = errorReporter
        self.userSession = userSessionStore.load() ?? userSession
    }

    static func live() -> AppEnvironment {
        let repository: CampaignRepository
        let adminRepository: AdminRepository
        let productAnalytics: ProductAnalytics

        if let configuration = SupabaseConfiguration.fromBundle() {
            repository = SupabaseCampaignRepository(configuration: configuration)
            productAnalytics = SupabaseProductAnalytics(configuration: configuration)
            adminRepository = UnavailableAdminRepository(
                reason: "Live admin krever egen admin-innlogging eller et separat adminverktøy. Denne iOS-klienten bruker bare publiserbar nøkkel."
            )
        } else {
            repository = MockCampaignRepository(
                reason: "SUPABASE_HOST eller SUPABASE_PUBLISHABLE_KEY mangler i appens Info.plist."
            )
            productAnalytics = NoopProductAnalytics()
            adminRepository = UnavailableAdminRepository(
                reason: "Admin-kø er utilgjengelig før appkonfigurasjonen og admin-laget er koblet opp."
            )
        }

        return AppEnvironment(
            campaignRepository: repository,
            adminRepository: adminRepository,
            productAnalytics: productAnalytics,
            userSession: .empty,
            errorReporter: UnifiedLogErrorReporter()
        )
    }

    static func mock() -> AppEnvironment {
        AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: MockAdminRepository(),
            productAnalytics: NoopProductAnalytics(),
            userSession: .empty,
            userSessionStore: InMemoryUserSessionStore()
        )
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        track(.init(name: "app_opened", surface: "app"))
        await refresh()
    }

    func track(_ event: ProductAnalyticsEvent) {
        let productAnalytics = productAnalytics
        Task {
            await productAnalytics.track(event)
        }
    }

    func refresh() async {
        let refreshStartedAt = ContinuousClock.now
        loadState = .loading

        do {
            let repository = campaignRepository
            let bootstrapData = try await repository.fetchBootstrapData()
            programs = bootstrapData.programs
            programGuides = bootstrapData.programGuides
            campaigns = bootstrapData.campaigns
            stores = bootstrapData.stores
            dataSource = bootstrapData.dataSource
            userSession.selectedProgramIDs.formIntersection(Set(programs.map(\.id)))
            userSession.favoriteCampaignIDs.formIntersection(Set(campaigns.map(\.id)))
            userSession.favoriteStoreIDs.formIntersection(Set(stores.map(\.id)))
            loadState = .loaded
            reportPerformance(refreshStartedAt: refreshStartedAt, outcome: "success")
        } catch {
            errorReporter.capture(.bootstrapLoadFailed, error: error)
            let message = (error as? LocalizedError)?.errorDescription ?? "Kunne ikke hente kampanjedata akkurat nå."
            loadState = .failed(message)
            reportPerformance(refreshStartedAt: refreshStartedAt, outcome: "failure")
        }
    }

    private func reportPerformance(
        refreshStartedAt: ContinuousClock.Instant,
        outcome: String
    ) {
        let now = ContinuousClock.now
        let refreshMilliseconds = PerformanceBenchmarks.milliseconds(
            from: refreshStartedAt.duration(to: now)
        )
        Self.performanceLogger.notice(
            "benchmark=bootstrap duration_ms=\(refreshMilliseconds, format: .fixed(precision: 1), privacy: .public) outcome=\(outcome, privacy: .public)"
        )

        guard !hasReportedStartup else { return }
        hasReportedStartup = true

        let startupMilliseconds = PerformanceBenchmarks.milliseconds(
            from: startupStartedAt.duration(to: now)
        )
        let targetMet = startupMilliseconds <= PerformanceBenchmarks.firstUsableContentMilliseconds
        Self.performanceLogger.notice(
            "benchmark=first_usable_content duration_ms=\(startupMilliseconds, format: .fixed(precision: 1), privacy: .public) target_ms=2000 target_met=\(targetMet, privacy: .public) outcome=\(outcome, privacy: .public)"
        )
    }

    var favoriteCampaigns: [Campaign] {
        campaigns.filter { userSession.favoriteCampaignIDs.contains($0.id) }
    }

    var favoriteStores: [Store] {
        publishedStores.filter { userSession.favoriteStoreIDs.contains($0.id) }
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

    var publishedStores: [Store] {
        stores
            .filter(\.isPublished)
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func programGuide(for program: BonusProgram) -> ProgramGuide? {
        programGuides.first {
            $0.programID == program.id && $0.status == .published && $0.lastReviewedAt != nil
        }
    }

    func publishedGuides(for programs: [BonusProgram]) -> [ProgramGuide] {
        let programIDs = Set(programs.map(\.id))
        return programGuides.filter { guide in
            guide.status == .published
                && guide.lastReviewedAt != nil
                && programIDs.contains(guide.programID)
        }
    }

    func makeAdminQueueViewModel() -> AdminQueueViewModel {
        AdminQueueViewModel(repository: adminRepository, errorReporter: errorReporter)
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

private extension UserSession {
    static let empty = UserSession(selectedProgramIDs: [], favoriteCampaignIDs: [], favoriteStoreIDs: [])
}
