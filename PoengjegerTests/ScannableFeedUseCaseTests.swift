import Foundation
import Testing
@testable import Poengjeger

struct ScannableFeedUseCaseTests {
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

    @Test
    func expiryLabelUsesNorwegianDeadlineText() {
        let referenceDate = Date(timeIntervalSince1970: 10_000)

        #expect(FeedDateHelper.expiryLabel(nil, referenceDate: referenceDate) == ExpiryDisplay(text: "Løpende", urgent: false))
        #expect(FeedDateHelper.expiryLabel(Date(timeIntervalSince1970: 10_000 - 86_400), referenceDate: referenceDate) == ExpiryDisplay(text: "Utløpt", urgent: true))
        #expect(FeedDateHelper.expiryLabel(referenceDate, referenceDate: referenceDate) == ExpiryDisplay(text: "Siste dag", urgent: true))
        #expect(FeedDateHelper.expiryLabel(Date(timeIntervalSince1970: 10_000 + 86_400), referenceDate: referenceDate) == ExpiryDisplay(text: "1 dag igjen", urgent: true))
        #expect(FeedDateHelper.expiryLabel(Date(timeIntervalSince1970: 10_000 + 86_400 * 3), referenceDate: referenceDate) == ExpiryDisplay(text: "3 dager igjen", urgent: true))
        #expect(FeedDateHelper.expiryLabel(Date(timeIntervalSince1970: 10_000 + 86_400 * 4), referenceDate: referenceDate) == ExpiryDisplay(text: "4 dager igjen", urgent: false))
    }

    @Test
    func scannableFeedHidesInactiveUnpublishedAndUnselectedCampaigns() {
        let referenceDate = Date(timeIntervalSince1970: 10_000)
        let activeSelected = makeCampaign(
            title: "Aktiv valgt",
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400),
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let expiredSelected = makeCampaign(
            title: "Utløpt valgt",
            endDate: Date(timeIntervalSince1970: 10_000 - 86_400),
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let futureSelected = makeCampaign(
            title: "Fremtidig valgt",
            startDate: Date(timeIntervalSince1970: 10_000 + 86_400),
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400 * 2),
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let activeOther = makeCampaign(
            title: "Aktiv annen",
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400),
            linkedProgramIDs: [SampleData.euroBonus.id]
        )
        let draftSelected = makeCampaign(
            title: "Draft valgt",
            status: .draft,
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400),
            linkedProgramIDs: [SampleData.trumf.id]
        )

        let campaigns = ScannableFeedUseCase().makeFeed(
            campaigns: [activeOther, draftSelected, futureSelected, expiredSelected, activeSelected],
            selectedProgramIDs: [SampleData.trumf.id],
            showsAllPrograms: false,
            selectedCategoryID: nil,
            searchText: "",
            sort: .expiringFirst,
            referenceDate: referenceDate
        )

        #expect(campaigns.map(\.title) == ["Aktiv valgt"])
    }

    @Test
    func scannableFeedCanSearchFilterByCategoryAndShowAllPrograms() {
        let selectedCategory = SampleData.groceryCategory
        let matchingCampaign = makeCampaign(
            title: "Trumf kaffe",
            summary: "Bonus på kaffe",
            category: selectedCategory,
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let wrongCategory = makeCampaign(
            title: "Trumf kaffe kredittkort",
            summary: "Bonus på kaffe",
            category: SampleData.cardCategory,
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let otherProgram = makeCampaign(
            title: "EuroBonus kaffe",
            summary: "Bonus på kaffe",
            category: selectedCategory,
            linkedProgramIDs: [SampleData.euroBonus.id]
        )

        let campaigns = ScannableFeedUseCase().makeFeed(
            campaigns: [wrongCategory, otherProgram, matchingCampaign],
            selectedProgramIDs: [SampleData.trumf.id],
            showsAllPrograms: true,
            selectedCategoryID: selectedCategory.id,
            searchText: "kaffe",
            sort: .alphabetic,
            referenceDate: Date(timeIntervalSince1970: 10_000)
        )

        #expect(campaigns.map(\.title) == ["EuroBonus kaffe", "Trumf kaffe"])
    }

    @Test
    func scannableFeedFiltersByEditorialSearchTextAndCategory() {
        let selectedCategory = SampleData.groceryCategory
        let matchingCampaign = makeCampaign(
            title: "Dagligvarebonus",
            summary: "Vanlig sammendrag",
            editorialSummary: "Ekstra trumf paa helgehandel",
            category: selectedCategory,
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let noSearchMatch = makeCampaign(
            title: "Dagligvarebonus uten treff",
            summary: "Vanlig sammendrag",
            editorialSummary: "Ordinart tilbud",
            category: selectedCategory,
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let wrongCategory = makeCampaign(
            title: "Helgehandel med kort",
            summary: "Ekstra trumf",
            editorialSummary: "Ekstra trumf paa helgehandel",
            category: SampleData.cardCategory,
            linkedProgramIDs: [SampleData.trumf.id]
        )

        let campaigns = ScannableFeedUseCase().makeFeed(
            campaigns: [wrongCategory, noSearchMatch, matchingCampaign],
            selectedProgramIDs: [SampleData.trumf.id],
            showsAllPrograms: false,
            selectedCategoryID: selectedCategory.id,
            searchText: "helgehandel",
            sort: .alphabetic,
            referenceDate: Date(timeIntervalSince1970: 10_000)
        )

        #expect(campaigns.map(\.title) == ["Dagligvarebonus"])
    }

    @Test
    func scannableFeedSortsByExpiryNewestAndTitle() {
        let referenceDate = Date(timeIntervalSince1970: 10_000)
        let earliest = makeCampaign(
            title: "B-kampanje",
            startDate: Date(timeIntervalSince1970: 1),
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400)
        )
        let later = makeCampaign(
            title: "A-kampanje",
            startDate: Date(timeIntervalSince1970: 3),
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400 * 3)
        )
        let ongoing = makeCampaign(
            title: "C-kampanje",
            startDate: Date(timeIntervalSince1970: 2),
            endDate: nil
        )
        let campaigns = [ongoing, later, earliest]
        let useCase = ScannableFeedUseCase()

        #expect(
            useCase.makeFeed(
                campaigns: campaigns,
                selectedProgramIDs: [SampleData.trumf.id],
                showsAllPrograms: false,
                selectedCategoryID: nil,
                searchText: "",
                sort: .expiringFirst,
                referenceDate: referenceDate
            ).map(\.title) == ["B-kampanje", "A-kampanje", "C-kampanje"]
        )
        #expect(
            useCase.makeFeed(
                campaigns: campaigns,
                selectedProgramIDs: [SampleData.trumf.id],
                showsAllPrograms: false,
                selectedCategoryID: nil,
                searchText: "",
                sort: .newest,
                referenceDate: referenceDate
            ).map(\.title) == ["A-kampanje", "C-kampanje", "B-kampanje"]
        )
        #expect(
            useCase.makeFeed(
                campaigns: campaigns,
                selectedProgramIDs: [SampleData.trumf.id],
                showsAllPrograms: false,
                selectedCategoryID: nil,
                searchText: "",
                sort: .alphabetic,
                referenceDate: referenceDate
            ).map(\.title) == ["A-kampanje", "B-kampanje", "C-kampanje"]
        )
    }

    @Test
    func scannableFeedUsesEditorialScoreAsExpiryTieBreaker() {
        let referenceDate = Date(timeIntervalSince1970: 10_000)
        let lowerScore = makeCampaign(
            title: "Lavere score",
            editorialScore: 40,
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400)
        )
        let higherScore = makeCampaign(
            title: "Hoyere score",
            editorialScore: 80,
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400)
        )
        let unscored = makeCampaign(
            title: "Uten score",
            editorialScore: nil,
            endDate: Date(timeIntervalSince1970: 10_000 + 86_400)
        )

        let campaigns = ScannableFeedUseCase().makeFeed(
            campaigns: [lowerScore, unscored, higherScore],
            selectedProgramIDs: [SampleData.trumf.id],
            showsAllPrograms: false,
            selectedCategoryID: nil,
            searchText: "",
            sort: .expiringFirst,
            referenceDate: referenceDate
        )

        #expect(campaigns.map(\.title) == ["Hoyere score", "Lavere score", "Uten score"])
    }

    private func makeCampaign(
        title: String = "Testkampanje",
        summary: String = "Sammendrag",
        editorialScore: Int? = 50,
        editorialSummary: String = "",
        status: Campaign.Status = .published,
        startDate: Date? = nil,
        endDate: Date? = nil,
        lastVerifiedAt: Date = Date(timeIntervalSince1970: 100),
        category: CampaignCategory? = nil,
        requirements: [CampaignRequirement] = [],
        difficultyLevel: DifficultyLevel? = nil,
        linkedProgramIDs: [UUID] = [SampleData.trumf.id]
    ) -> Campaign {
        Campaign(
            id: UUID(),
            title: title,
            summary: summary,
            details: "Detaljer",
            status: status,
            startDate: startDate,
            endDate: endDate,
            lastVerifiedAt: lastVerifiedAt,
            primaryProgramID: linkedProgramIDs.first,
            category: category,
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
