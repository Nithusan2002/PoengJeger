import Testing
@testable import Poengjeger

struct FeedUseCaseTests {
    @Test
    func feedOnlyIncludesCampaignsForSelectedPrograms() {
        let selectedProgramIDs = [SampleData.trumf.id]
        let campaigns = FeedUseCase().makeFeed(
            campaigns: SampleData.campaigns,
            selectedProgramIDs: Set(selectedProgramIDs)
        )

        #expect(campaigns.count == 1)
        #expect(campaigns.first?.primaryProgramID == SampleData.trumf.id)
    }

    @Test
    func feedSortsByEditorialScoreDescending() {
        let selectedProgramIDs = Set(SampleData.programs.map(\.id))
        let campaigns = FeedUseCase().makeFeed(
            campaigns: SampleData.campaigns,
            selectedProgramIDs: selectedProgramIDs
        )

        #expect(campaigns.map(\.editorialScore) == [82, 76, 71])
    }
}
