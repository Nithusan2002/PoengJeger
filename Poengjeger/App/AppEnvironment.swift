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

    static func bootstrap() -> AppEnvironment {
        let repository: CampaignRepository

        if let configuration = SupabaseConfiguration.fromBundle() {
            repository = FallbackCampaignRepository(
                primary: SupabaseCampaignRepository(configuration: configuration),
                fallback: MockCampaignRepository()
            )
        } else {
            repository = MockCampaignRepository()
        }

        return AppEnvironment(
            campaignRepository: repository,
            userSession: UserSession(
                selectedProgramIDs: [],
                favoriteCampaignIDs: []
            )
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
            campaigns = bootstrapData.campaigns
            dataSource = bootstrapData.dataSource
            userSession.selectedProgramIDs.formIntersection(Set(programs.map(\.id)))
            loadState = .loaded
        } catch {
            loadState = .failed("Kunne ikke hente kampanjedata akkurat nå.")
        }
    }

    var favoriteCampaigns: [Campaign] {
        campaigns.filter { userSession.favoriteCampaignIDs.contains($0.id) }
    }
}
