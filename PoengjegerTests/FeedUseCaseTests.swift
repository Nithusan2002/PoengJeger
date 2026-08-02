import Testing
@testable import Poengjeger

struct FeedUseCaseTests {
    @Test
    func feedOnlyIncludesCampaignsForSelectedPrograms() {
        let repository = MockCampaignRepository()
        let selectedProgramIDs = [SampleData.trumf.id]
        let campaigns = FeedUseCase(repository: repository).makeFeed(selectedProgramIDs: Set(selectedProgramIDs))

        #expect(campaigns.count == 1)
        #expect(campaigns.first?.primaryProgramID == SampleData.trumf.id)
    }

    @Test
    func feedSortsByEditorialScoreDescending() {
        let repository = MockCampaignRepository()
        let selectedProgramIDs = Set(SampleData.programs.map(\.id))
        let campaigns = FeedUseCase(repository: repository).makeFeed(selectedProgramIDs: selectedProgramIDs)

        #expect(campaigns.map(\.editorialScore) == [82, 76, 71])
    }
}
