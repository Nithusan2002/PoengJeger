import Observation

@Observable
final class AppEnvironment {
    let campaignRepository: CampaignRepository
    var userSession: UserSession

    init(campaignRepository: CampaignRepository, userSession: UserSession) {
        self.campaignRepository = campaignRepository
        self.userSession = userSession
    }

    static func bootstrap() -> AppEnvironment {
        let repository = MockCampaignRepository()
        let programs = repository.fetchPrograms()
        let userSession = UserSession(
            selectedProgramIDs: Set(programs.prefix(2).map(\.id)),
            favoriteCampaignIDs: []
        )

        return AppEnvironment(campaignRepository: repository, userSession: userSession)
    }
}
