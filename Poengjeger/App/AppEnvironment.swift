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
    var userSession: UserSession
    var programs: [BonusProgram] = []
    var campaigns: [Campaign] = []
    var loadState: LoadState = .idle
    var dataSource: CampaignDataSource?

    init(campaignRepository: CampaignRepository, userSession: UserSession) {
        self.campaignRepository = campaignRepository
        self.userSession = userSession
    }

    static func live() -> AppEnvironment {
        let repository: CampaignRepository

        if let configuration = SupabaseConfiguration.fromBundle() {
            repository = SupabaseCampaignRepository(configuration: configuration)
        } else {
            repository = MissingSupabaseConfigurationRepository()
        }

        return AppEnvironment(campaignRepository: repository, userSession: .empty)
    }

    static func mock() -> AppEnvironment {
        AppEnvironment(campaignRepository: MockCampaignRepository(), userSession: .empty)
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
}

private struct MissingSupabaseConfigurationRepository: CampaignRepository {
    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        throw MissingSupabaseConfigurationError()
    }
}

private struct MissingSupabaseConfigurationError: LocalizedError {
    var errorDescription: String? {
        "SUPABASE_URL eller SUPABASE_ANON_KEY mangler i appkonfigurasjonen."
    }
}

private extension UserSession {
    static let empty = UserSession(selectedProgramIDs: [], favoriteCampaignIDs: [])
}
