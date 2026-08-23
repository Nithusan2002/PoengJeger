import Foundation
import Testing
@testable import Poengjeger

@Suite(.serialized)
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
        #expect(makeCampaign(editorialScore: 80).editorialTierLabel == "God deal")
        #expect(makeCampaign(editorialScore: 65).editorialTierLabel == "Verdt å sjekke")
        #expect(makeCampaign(editorialScore: 64).editorialTierLabel == "For spesielt interesserte")
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

    @MainActor
    @Test
    func appEnvironmentRefreshLoadsBootstrapDataAndPrunesUnavailableSelections() async {
        let staleProgramID = UUID()
        let availableCampaign = makeCampaign(linkedProgramIDs: [SampleData.trumf.id])
        let repository = StaticCampaignRepository(
            data: CampaignBootstrapData(
                programs: [SampleData.trumf],
                programGuides: SampleData.programGuides.filter { $0.programID == SampleData.trumf.id },
                campaigns: [availableCampaign],
                stores: SampleData.stores,
                dataSource: .supabase
            )
        )
        let environment = AppEnvironment(
            campaignRepository: repository,
            adminRepository: MockAdminRepository(),
            userSession: UserSession(
                selectedProgramIDs: [SampleData.trumf.id, staleProgramID],
                favoriteCampaignIDs: [availableCampaign.id]
            ),
            userSessionStore: InMemoryUserSessionStore()
        )

        await environment.refresh()

        #expect(environment.loadState == .loaded)
        #expect(environment.programs.map(\.id) == [SampleData.trumf.id])
        #expect(environment.programGuides.map(\.programID) == [SampleData.trumf.id])
        #expect(environment.campaigns.map(\.id) == [availableCampaign.id])
        #expect(environment.publishedStores.map(\.id) == SampleData.stores.map(\.id))
        #expect(environment.dataSource == .supabase)
        #expect(environment.userSession.selectedProgramIDs == [SampleData.trumf.id])
        #expect(environment.favoriteCampaigns.map(\.id) == [availableCampaign.id])
    }

    @MainActor
    @Test
    func appEnvironmentUsesPersistedSessionAndSavesSessionChanges() {
        let persistedSession = UserSession(
            selectedProgramIDs: [SampleData.euroBonus.id],
            favoriteCampaignIDs: [],
            notificationsEnabled: false
        )
        let store = InMemoryUserSessionStore(session: persistedSession)
        let environment = AppEnvironment(
            campaignRepository: MockCampaignRepository(),
            adminRepository: MockAdminRepository(),
            userSession: UserSession(selectedProgramIDs: [SampleData.trumf.id], favoriteCampaignIDs: []),
            userSessionStore: store
        )

        #expect(environment.userSession == persistedSession)

        let updatedSession = UserSession(
            selectedProgramIDs: [SampleData.trumf.id],
            favoriteCampaignIDs: [SampleData.campaigns[0].id],
            notificationsEnabled: true
        )
        environment.userSession = updatedSession

        #expect(store.load() == updatedSession)
    }

    @MainActor
    @Test
    func appEnvironmentLimitsFirstPhaseCampaignsToActiveEuroBonusAndTrumfPrograms() {
        let environment = AppEnvironment.mock()
        environment.programs = SampleData.programs
        environment.campaigns = SampleData.campaigns

        #expect(environment.firstPhasePrograms.map(\.slug) == ["sas-eurobonus", "trumf"])
        #expect(Set(environment.firstPhaseCampaigns.compactMap(\.primaryProgramID)) == [SampleData.euroBonus.id, SampleData.trumf.id])
        #expect(!environment.firstPhaseCampaigns.contains { $0.primaryProgramID == SampleData.spann.id })
    }

    @Test
    func fallbackCampaignRepositoryReturnsFallbackDataWithErrorReason() async throws {
        let fallbackCampaign = makeCampaign(title: "Fallback")
        let repository = FallbackCampaignRepository(
            primary: FailingCampaignRepository(error: TestRepositoryError.offline),
            fallback: StaticCampaignRepository(
                data: CampaignBootstrapData(
                    programs: [SampleData.trumf],
                    programGuides: [],
                    campaigns: [fallbackCampaign],
                    stores: [SampleData.stores[0]],
                    dataSource: .mock(reason: nil)
                )
            )
        )

        let data = try await repository.fetchBootstrapData()

        #expect(data.programs.map(\.id) == [SampleData.trumf.id])
        #expect(data.campaigns.map(\.title) == ["Fallback"])
        #expect(data.stores.map(\.name) == ["Elkjøp"])
        #expect(data.dataSource.isFallback)
        #expect(data.dataSource.label == "Mock-data (Nettverk utilgjengelig)")
    }

    @Test
    func storeSearchMatchesNameCategoryAndKeywords() {
        let stores = SampleData.stores

        #expect(StoreSearchUseCase().search(stores: stores, query: "elkjøp").map(\.name) == ["Elkjøp"])
        #expect(StoreSearchUseCase().search(stores: stores, query: "dagligvare").map(\.name) == ["Meny"])
        #expect(StoreSearchUseCase().search(stores: stores, query: "gaming").map(\.name) == ["Komplett"])
    }

    @Test
    func supabaseRepositoryDecodesFractionalSecondTimestamps() async throws {
        let programID = UUID()
        let campaignID = UUID()
        let sourceReferenceID = UUID()

        SupabaseURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            let json: String

            if path.hasSuffix("/bonus_programs") {
                json = """
                [
                  {
                    "id": "\(programID.uuidString)",
                    "slug": "trumf",
                    "name": "Trumf",
                    "issuer_name": "NorgesGruppen",
                    "country_code": "NO",
                    "is_active": true
                  }
                ]
                """
            } else if path.hasSuffix("/program_guides") {
                json = "[]"
            } else if path.hasSuffix("/campaigns") {
                json = """
                [
                  {
                    "id": "\(campaignID.uuidString)",
                    "title": "Testkampanje",
                    "summary": "Kort sammendrag",
                    "details": "Detaljer",
                    "status": "published",
                    "start_date": null,
                    "end_date": null,
                    "last_verified_at": "2026-08-16T08:00:00.123Z",
                    "primary_program_id": "\(programID.uuidString)",
                    "editorial_score": 80,
                    "editorial_summary": "Redaksjonelt sammendrag",
                    "is_featured": false,
                    "campaign_categories": null,
                    "campaign_requirements": [],
                    "campaign_source_references": [
                      {
                        "id": "\(sourceReferenceID.uuidString)",
                        "url": "https://example.com/kampanje",
                        "title": "Kilde",
                        "checked_at": "2026-08-16T08:00:01.456Z",
                        "evidence_note": "Kontrollert",
                        "campaign_sources": { "name": "Eksempelkilde" }
                      }
                    ],
                    "campaign_editorial_assessments": [],
                    "campaign_geo_restrictions": [],
                    "campaign_programs": [
                      { "program_id": "\(programID.uuidString)" }
                    ]
                  }
                ]
                """
            } else {
                json = "[]"
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(json.utf8))
        }
        defer { SupabaseURLProtocol.requestHandler = nil }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SupabaseURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let repository = SupabaseCampaignRepository(
            configuration: SupabaseConfiguration(
                url: URL(string: "https://example.supabase.co")!,
                publishableKey: "test-key"
            ),
            session: session
        )

        let data = try await repository.fetchBootstrapData()

        #expect(data.campaigns.map(\.id) == [campaignID])
        #expect(data.campaigns.first?.sources.first?.checkedAt.timeIntervalSince1970 != nil)
    }

    @Test
    func supabaseRepositorySendsAuthHeadersAndMapsCampaignFallbacks() async throws {
        let programID = UUID()
        let campaignID = UUID()
        let categoryID = UUID()
        let sourceReferenceID = UUID()
        let requirementID = UUID()
        let geoRestrictionID = UUID()
        let headerLock = NSLock()
        var capturedHeadersByPath: [String: [String: String]] = [:]

        SupabaseURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            headerLock.lock()
            capturedHeadersByPath[path] = request.allHTTPHeaderFields ?? [:]
            headerLock.unlock()
            let json: String

            if path.hasSuffix("/bonus_programs") {
                json = """
                [
                  {
                    "id": "\(programID.uuidString)",
                    "slug": "trumf",
                    "name": "Trumf",
                    "issuer_name": "NorgesGruppen",
                    "country_code": "NO",
                    "is_active": true
                  }
                ]
                """
            } else if path.hasSuffix("/program_guides") {
                json = """
                [
                  {
                    "id": "\(UUID().uuidString)",
                    "program_id": "\(programID.uuidString)",
                    "status": "published",
                    "intro_text": "Intro",
                    "strategy": "Strategi",
                    "value_estimate_label": "1 kr",
                    "value_estimate_detail": "Detalj",
                    "expiration_summary": "Løpende",
                    "expiration_detail": "Detalj",
                    "earning_tips": ["Aktiver først"],
                    "redemption_tips": ["Bruk smart"],
                    "risk_notes": ["Sjekk vilkår"],
                    "last_reviewed_at": "2026-08-16T08:00:00Z"
                  },
                  {
                    "id": "\(UUID().uuidString)",
                    "program_id": "\(programID.uuidString)",
                    "status": "unknown",
                    "intro_text": null,
                    "strategy": "Ignoreres",
                    "value_estimate_label": null,
                    "value_estimate_detail": null,
                    "expiration_summary": null,
                    "expiration_detail": null,
                    "earning_tips": [],
                    "redemption_tips": [],
                    "risk_notes": [],
                    "last_reviewed_at": null
                  }
                ]
                """
            } else if path.hasSuffix("/campaigns") {
                json = """
                [
                  {
                    "id": "\(campaignID.uuidString)",
                    "title": "Kampanje med fallback",
                    "summary": "Kort sammendrag",
                    "details": "Detaljer",
                    "status": "published",
                    "start_date": null,
                    "end_date": null,
                    "last_verified_at": "2026-08-16T08:00:00Z",
                    "primary_program_id": "\(programID.uuidString)",
                    "editorial_score": 79.6,
                    "editorial_summary": null,
                    "is_featured": true,
                    "campaign_categories": {
                      "id": "\(categoryID.uuidString)",
                      "slug": "dagligvare",
                      "name": "Dagligvare"
                    },
                    "campaign_requirements": [
                      {
                        "id": "\(requirementID.uuidString)",
                        "text": "Andre krav",
                        "sort_order": 2
                      },
                      {
                        "id": "\(UUID().uuidString)",
                        "text": "Forste krav",
                        "sort_order": 1
                      }
                    ],
                    "campaign_source_references": [
                      {
                        "id": "\(sourceReferenceID.uuidString)",
                        "url": "https://example.com/kampanje",
                        "title": null,
                        "checked_at": "2026-08-16T08:00:01Z",
                        "evidence_note": "Kontrollert",
                        "campaign_sources": { "name": "Eksempelkilde" }
                      },
                      {
                        "id": "\(UUID().uuidString)",
                        "url": "https://[ugyldig",
                        "title": "Ugyldig",
                        "checked_at": "2026-08-16T08:00:01Z",
                        "evidence_note": null,
                        "campaign_sources": { "name": "Feilkilde" }
                      }
                    ],
                    "campaign_editorial_assessments": {
                      "score": 79.6,
                      "decision_label": "worth_checking",
                      "decision_summary": "Verdt å sjekke for helgehandel.",
                      "best_for": "Deg som uansett skal handle.",
                      "not_for": "Deg som må kjøpe ekstra.",
                      "reason_why_it_matters": "Redaksjonell vurdering",
                      "estimated_value_text": "Høy verdi",
                      "difficulty_level": "medium",
                      "availability_scope": "broad",
                      "risk_note": "Kan ha butikkunntak"
                    },
                    "campaign_geo_restrictions": [
                      {
                        "id": "\(geoRestrictionID.uuidString)",
                        "country_code": "NO"
                      }
                    ],
                    "campaign_programs": []
                  }
                ]
                """
            } else {
                json = "[]"
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(json.utf8))
        }
        defer { SupabaseURLProtocol.requestHandler = nil }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SupabaseURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let repository = SupabaseCampaignRepository(
            configuration: SupabaseConfiguration(
                url: URL(string: "https://example.supabase.co")!,
                publishableKey: "test-key"
            ),
            session: session
        )

        let data = try await repository.fetchBootstrapData()
        let campaign = try #require(data.campaigns.first)

        #expect(capturedHeadersByPath.values.allSatisfy { headers in
            headers["apikey"] == "test-key"
                && headers["Authorization"] == "Bearer test-key"
                && headers["Accept"] == "application/json"
        })
        #expect(data.programGuides.count == 1)
        #expect(campaign.linkedProgramIDs == [programID])
        #expect(campaign.editorialScore == 80)
        #expect(campaign.editorialSummary == "Redaksjonell vurdering")
        #expect(campaign.requirements.map(\.text) == ["Forste krav", "Andre krav"])
        #expect(campaign.sources.map(\.id) == [sourceReferenceID])
        #expect(campaign.sources.first?.title == "Eksempelkilde")
        #expect(campaign.editorialAssessment?.decisionLabel == .worthChecking)
        #expect(campaign.editorialAssessment?.decisionSummary == "Verdt å sjekke for helgehandel.")
        #expect(campaign.editorialAssessment?.bestFor == "Deg som uansett skal handle.")
        #expect(campaign.editorialAssessment?.notFor == "Deg som må kjøpe ekstra.")
        #expect(campaign.editorialAssessment?.difficultyLevel == .medium)
        #expect(campaign.editorialAssessment?.availabilityScope == .broad)
        #expect(campaign.geoRestrictions.map(\.id) == [geoRestrictionID])
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
    func scannableFeedSearchesDecisionFields() {
        let matchingCampaign = makeCampaign(
            title: "Trumf netthandel",
            summary: "Vanlig sammendrag",
            decisionSummary: "Verdt for planlagt elektronikkjop",
            linkedProgramIDs: [SampleData.trumf.id]
        )
        let noMatch = makeCampaign(
            title: "Trumf dagligvare",
            summary: "Vanlig sammendrag",
            decisionSummary: "Relevant for helgehandel",
            linkedProgramIDs: [SampleData.trumf.id]
        )

        let campaigns = ScannableFeedUseCase().makeFeed(
            campaigns: [noMatch, matchingCampaign],
            selectedProgramIDs: [SampleData.trumf.id],
            showsAllPrograms: false,
            selectedCategoryID: nil,
            searchText: "elektronikkjop",
            sort: .alphabetic,
            referenceDate: Date(timeIntervalSince1970: 10_000)
        )

        #expect(campaigns.map(\.title) == ["Trumf netthandel"])
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
        decisionSummary: String? = nil,
        bestFor: String? = nil,
        notFor: String? = nil,
        difficultyLevel: DifficultyLevel? = nil,
        linkedProgramIDs: [UUID] = [SampleData.trumf.id]
    ) -> Campaign {
        let hasAssessment = decisionSummary != nil || bestFor != nil || notFor != nil || difficultyLevel != nil

        return Campaign(
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
            editorialAssessment: hasAssessment
                ? EditorialAssessment(
                    score: editorialScore,
                    decisionLabel: decisionSummary == nil ? nil : .worthChecking,
                    decisionSummary: decisionSummary,
                    bestFor: bestFor,
                    notFor: notFor,
                    reasonWhyItMatters: "Testvurdering",
                    estimatedValueText: nil,
                    difficultyLevel: difficultyLevel,
                    availabilityScope: nil,
                    riskNote: nil
                )
                : nil,
            geoRestrictions: [],
            linkedProgramIDs: linkedProgramIDs
        )
    }
}

private final class SupabaseURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            guard let requestHandler = Self.requestHandler else {
                throw URLError(.badServerResponse)
            }

            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private struct StaticCampaignRepository: CampaignRepository {
    let data: CampaignBootstrapData

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        data
    }
}

private struct FailingCampaignRepository: CampaignRepository {
    let error: Error

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        throw error
    }
}

private enum TestRepositoryError: LocalizedError {
    case offline

    var errorDescription: String? {
        switch self {
        case .offline:
            return "Nettverk utilgjengelig"
        }
    }
}
