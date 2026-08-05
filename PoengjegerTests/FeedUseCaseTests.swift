import Foundation
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

    @Test
    func feedSortsCampaignsWithoutScoreAfterScoredCampaignsByVerificationDate() {
        let programID = SampleData.trumf.id
        let recentUnscoredCampaign = makeCampaign(
            title: "Ny uten score",
            editorialScore: nil,
            lastVerifiedAt: Date(timeIntervalSince1970: 300),
            linkedProgramIDs: [programID]
        )
        let olderScoredCampaign = makeCampaign(
            title: "Eldre med score",
            editorialScore: 10,
            lastVerifiedAt: Date(timeIntervalSince1970: 100),
            linkedProgramIDs: [programID]
        )
        let olderUnscoredCampaign = makeCampaign(
            title: "Eldre uten score",
            editorialScore: nil,
            lastVerifiedAt: Date(timeIntervalSince1970: 200),
            linkedProgramIDs: [programID]
        )

        let campaigns = FeedUseCase().makeFeed(
            campaigns: [recentUnscoredCampaign, olderUnscoredCampaign, olderScoredCampaign],
            selectedProgramIDs: [programID]
        )

        #expect(campaigns.map(\.title) == ["Eldre med score", "Ny uten score", "Eldre uten score"])
    }

    @Test
    func feedCanFilterCampaignsExpiringSoon() {
        let programID = SampleData.trumf.id
        let referenceDate = Date(timeIntervalSince1970: 1_000)
        let expiringSoon = makeCampaign(
            title: "Utløper snart",
            endDate: Date(timeIntervalSince1970: 1_000 + 86_400 * 3),
            linkedProgramIDs: [programID]
        )
        let expiringLater = makeCampaign(
            title: "Utløper senere",
            endDate: Date(timeIntervalSince1970: 1_000 + 86_400 * 10),
            linkedProgramIDs: [programID]
        )
        let withoutEndDate = makeCampaign(
            title: "Uten frist",
            endDate: nil,
            linkedProgramIDs: [programID]
        )

        let campaigns = FeedUseCase().makeFeed(
            campaigns: [expiringLater, withoutEndDate, expiringSoon],
            selectedProgramIDs: [programID],
            filter: .expiringSoon,
            referenceDate: referenceDate
        )

        #expect(campaigns.map(\.title) == ["Utløper snart"])
    }

    @Test
    func feedCanFilterHighScoreCampaigns() {
        let programID = SampleData.trumf.id
        let highScore = makeCampaign(
            title: "Høy score",
            editorialScore: 75,
            linkedProgramIDs: [programID]
        )
        let lowerScore = makeCampaign(
            title: "Lavere score",
            editorialScore: 74,
            linkedProgramIDs: [programID]
        )

        let campaigns = FeedUseCase().makeFeed(
            campaigns: [lowerScore, highScore],
            selectedProgramIDs: [programID],
            filter: .highScore
        )

        #expect(campaigns.map(\.title) == ["Høy score"])
    }

    @Test
    func feedCanFilterLowFrictionCampaigns() {
        let programID = SampleData.trumf.id
        let lowFriction = makeCampaign(
            title: "Lav friksjon",
            difficultyLevel: .low,
            linkedProgramIDs: [programID]
        )
        let mediumFriction = makeCampaign(
            title: "Middels friksjon",
            difficultyLevel: .medium,
            linkedProgramIDs: [programID]
        )

        let campaigns = FeedUseCase().makeFeed(
            campaigns: [mediumFriction, lowFriction],
            selectedProgramIDs: [programID],
            filter: .lowFriction
        )

        #expect(campaigns.map(\.title) == ["Lav friksjon"])
    }

    @Test
    func displaySummaryPrefersEditorialSummaryWhenPresent() {
        let campaign = makeCampaign(
            summary: "Kildesammendrag",
            editorialSummary: "Redaksjonelt sammendrag"
        )

        #expect(campaign.displaySummary == "Redaksjonelt sammendrag")
    }

    @Test
    func editorialTierLabelUsesUserFacingBuckets() {
        #expect(makeCampaign(editorialScore: 80).editorialTierLabel == "Sterk mulighet")
        #expect(makeCampaign(editorialScore: 65).editorialTierLabel == "Relevant")
        #expect(makeCampaign(editorialScore: 64).editorialTierLabel == "Nisjetilbud")
        #expect(makeCampaign(editorialScore: nil).editorialTierLabel == "Uten vurdering")
    }

    @Test
    func sortedRequirementsUsesSortOrder() {
        let campaign = makeCampaign(
            requirements: [
                CampaignRequirement(id: UUID(), text: "Sist", sortOrder: 2),
                CampaignRequirement(id: UUID(), text: "Først", sortOrder: 1)
            ]
        )

        #expect(campaign.sortedRequirements.map(\.text) == ["Først", "Sist"])
    }

    @Test
    func userSessionRoundTripsThroughCodableStorage() throws {
        let session = UserSession(
            selectedProgramIDs: [SampleData.trumf.id],
            favoriteCampaignIDs: [SampleData.campaigns[0].id],
            notificationsEnabled: false
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(UserSession.self, from: data)

        #expect(decoded == session)
    }

    private func makeCampaign(
        title: String = "Testkampanje",
        summary: String = "Sammendrag",
        editorialScore: Int? = 50,
        editorialSummary: String = "",
        endDate: Date? = nil,
        lastVerifiedAt: Date = Date(timeIntervalSince1970: 100),
        requirements: [CampaignRequirement] = [],
        difficultyLevel: DifficultyLevel? = nil,
        linkedProgramIDs: [UUID] = [SampleData.trumf.id]
    ) -> Campaign {
        Campaign(
            id: UUID(),
            title: title,
            summary: summary,
            details: "Detaljer",
            status: .published,
            startDate: nil,
            endDate: endDate,
            lastVerifiedAt: lastVerifiedAt,
            primaryProgramID: linkedProgramIDs.first,
            category: nil,
            editorialScore: editorialScore,
            editorialSummary: editorialSummary,
            isFeatured: false,
            requirements: requirements,
            sources: [],
            editorialAssessment: difficultyLevel.map {
                EditorialAssessment(
                    score: editorialScore,
                    reasonWhyItMatters: "Testvurdering",
                    estimatedValueText: nil,
                    difficultyLevel: $0,
                    availabilityScope: nil,
                    riskNote: nil
                )
            },
            geoRestrictions: [],
            linkedProgramIDs: linkedProgramIDs
        )
    }
}
