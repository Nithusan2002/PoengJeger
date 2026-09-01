import Foundation
import Testing
@testable import Poengjeger

@Suite(.serialized)
struct StoreEarningUseCaseTests {
    @Test
    func storeEarningSectionsFilterAndSortOnlyCurrentlyActivePromotions() {
        let activePromotion = makeEarningRate(
            rateLabel: "10 % Trumf",
            startsAt: Date(timeIntervalSinceNow: -86_400),
            endsAt: Date(timeIntervalSinceNow: 86_400),
            sortOrder: 3
        )
        let earlierActivePromotion = makeEarningRate(
            rateLabel: "5 % Trumf",
            startsAt: Date(timeIntervalSinceNow: -86_400),
            endsAt: nil,
            sortOrder: 2
        )
        let baseRate = makeEarningRate(
            rateLabel: "1 % grunnopptjening",
            sortOrder: 1,
            isBaseRate: true
        )
        let draftPromotion = makeEarningRate(
            status: .draft,
            rateLabel: "Skjult utkast",
            startsAt: Date(timeIntervalSinceNow: -86_400),
            endsAt: Date(timeIntervalSinceNow: 86_400),
            sortOrder: 4
        )
        let futurePromotion = makeEarningRate(
            rateLabel: "Starter senere",
            startsAt: Date(timeIntervalSinceNow: 86_400),
            endsAt: Date(timeIntervalSinceNow: 172_800),
            sortOrder: 5
        )
        let expiredPromotion = makeEarningRate(
            rateLabel: "Utløpt",
            startsAt: Date(timeIntervalSinceNow: -172_800),
            endsAt: Date(timeIntervalSinceNow: -86_400),
            sortOrder: 6
        )
        let store = makeStore(
            earningRates: [expiredPromotion, activePromotion, baseRate, futurePromotion, draftPromotion, earlierActivePromotion]
        )

        #expect(store.baseRates.map(\.rateLabel) == ["1 % grunnopptjening"])
        #expect(store.activePromotions.map(\.rateLabel) == ["5 % Trumf", "10 % Trumf"])
    }

    @Test
    func storeBestCombinationUsesFirstPublishedCombinationBySortOrder() {
        let laterPublished = makeCombination(title: "Senere publisert", sortOrder: 3)
        let archived = makeCombination(status: .archived, title: "Arkivert", sortOrder: 1)
        let earlierPublished = makeCombination(title: "Beste publisert", sortOrder: 2)
        let draft = makeCombination(status: .draft, title: "Utkast", sortOrder: 0)

        let store = makeStore(combinations: [laterPublished, archived, earlierPublished, draft])

        #expect(store.bestCombination?.title == "Beste publisert")
    }

    @Test
    func storeBestCombinationIgnoresCombinationsWithExpiredRates() {
        let expiredRateID = UUID()
        let activeRateID = UUID()
        let expiredRate = makeEarningRate(
            id: expiredRateID,
            rateLabel: "Utløpt kampanje",
            startsAt: Date(timeIntervalSinceNow: -172_800),
            endsAt: Date(timeIntervalSinceNow: -86_400),
            sortOrder: 1
        )
        let activeRate = makeEarningRate(
            id: activeRateID,
            rateLabel: "Aktiv opptjening",
            startsAt: Date(timeIntervalSinceNow: -86_400),
            endsAt: Date(timeIntervalSinceNow: 86_400),
            sortOrder: 2
        )
        let expiredCombination = makeCombination(
            title: "Utløpt anbefaling",
            sortOrder: 1,
            rateIDs: [expiredRateID]
        )
        let activeCombination = makeCombination(
            title: "Aktiv anbefaling",
            sortOrder: 2,
            rateIDs: [activeRateID]
        )
        let store = makeStore(
            earningRates: [expiredRate, activeRate],
            combinations: [expiredCombination, activeCombination]
        )

        #expect(store.bestCombination?.title == "Aktiv anbefaling")
    }

    @Test
    func storeBestCombinationIgnoresCombinationsWithMissingRates() {
        let missingRateCombination = makeCombination(
            title: "Mangler sats",
            sortOrder: 1,
            rateIDs: [UUID()]
        )
        let store = makeStore(earningRates: [], combinations: [missingRateCombination])

        #expect(store.bestCombination == nil)
    }

    @Test
    func storeBestCombinationPrefersSelectedProgramBeforeGeneralSortOrder() {
        let trumfRateID = UUID()
        let euroBonusRateID = UUID()
        let trumfRate = makeEarningRate(
            id: trumfRateID,
            rateLabel: "2 % Trumf",
            programID: SampleData.trumf.id
        )
        let euroBonusRate = makeEarningRate(
            id: euroBonusRateID,
            rateLabel: "20 EuroBonus-poeng per 100 kr",
            programID: SampleData.euroBonus.id
        )
        let euroBonusCombination = makeCombination(
            title: "EuroBonus først",
            totalValueLabel: "20 EuroBonus-poeng per 100 kr",
            sortOrder: 1,
            rateIDs: [euroBonusRateID]
        )
        let trumfCombination = makeCombination(
            title: "Trumf først",
            totalValueLabel: "2 % Trumf",
            sortOrder: 2,
            rateIDs: [trumfRateID]
        )
        let store = makeStore(
            earningRates: [euroBonusRate, trumfRate],
            combinations: [euroBonusCombination, trumfCombination]
        )

        #expect(store.bestCombination?.title == "EuroBonus først")
        #expect(store.bestCombination(for: [SampleData.trumf.id])?.title == "Trumf først")
        #expect(store.bestCombination(for: [SampleData.euroBonus.id])?.title == "EuroBonus først")
    }

    @Test
    func storeSearchAndDiscoveryHideUnpublishedStores() {
        let published = makeStore(name: "Synlig butikk", searchKeywords: ["telefon"])
        let draft = makeStore(name: "Skjult butikk", status: .draft, searchKeywords: ["telefon"])

        #expect(StoreSearchUseCase().search(stores: [draft, published], query: "telefon").map(\.name) == ["Synlig butikk"])
        #expect(StoreDiscoveryUseCase().rankedStores(from: [draft, published]).map(\.name) == ["Synlig butikk"])
    }

    @Test
    func storeSearchRanksSelectedProgramEarningBeforeHigherOtherProgramValue() {
        let trumfRateID = UUID()
        let euroBonusRateID = UUID()
        let trumfStore = makeStore(
            name: "A Trumf-butikk",
            searchKeywords: ["elektronikk"],
            earningRates: [
                makeEarningRate(id: trumfRateID, rateLabel: "2 % Trumf", programID: SampleData.trumf.id)
            ],
            combinations: [
                makeCombination(totalValueLabel: "2 % Trumf", rateIDs: [trumfRateID])
            ]
        )
        let euroBonusStore = makeStore(
            name: "B EuroBonus-butikk",
            searchKeywords: ["elektronikk"],
            earningRates: [
                makeEarningRate(id: euroBonusRateID, rateLabel: "20 EuroBonus-poeng per 100 kr", programID: SampleData.euroBonus.id)
            ],
            combinations: [
                makeCombination(totalValueLabel: "20 EuroBonus-poeng per 100 kr", rateIDs: [euroBonusRateID])
            ]
        )

        let stores = StoreSearchUseCase().search(
            stores: [euroBonusStore, trumfStore],
            query: "elektronikk",
            selectedProgramIDs: [SampleData.trumf.id]
        )

        #expect(stores.map(\.name) == ["A Trumf-butikk", "B EuroBonus-butikk"])
    }

    @Test
    func storeDiscoveryParsesNorwegianDecimalValuesWhenRankingStores() {
        let lowerValue = makeStore(
            name: "Lavere verdi",
            combinations: [makeCombination(totalValueLabel: "2,5 % Trumf", sortOrder: 1)]
        )
        let higherValue = makeStore(
            name: "Høyere verdi",
            combinations: [makeCombination(totalValueLabel: "10 % Trumf", sortOrder: 1)]
        )

        let stores = StoreDiscoveryUseCase().rankedStores(from: [lowerValue, higherValue])

        #expect(stores.map(\.name) == ["Høyere verdi", "Lavere verdi"])
        #expect(StoreDiscoveryUseCase.rankingValue(for: lowerValue) == 2.5)
    }

    @Test
    func homeShortcutStoresPreferTimelyAndEverydayStoresBeforePureValue() {
        let activeTravelStore = makeStore(
            name: "Aktiv reise",
            category: SampleData.travelCategory,
            earningRates: [
                makeEarningRate(
                    rateLabel: "4 % Trumf",
                    startsAt: Date(timeIntervalSinceNow: -86_400),
                    endsAt: Date(timeIntervalSinceNow: 86_400)
                )
            ],
            combinations: []
        )
        let groceryStore = makeStore(
            name: "Dagligvare",
            category: SampleData.groceryCategory,
            earningRates: [],
            combinations: [makeCombination(totalValueLabel: "1 % Trumf")]
        )
        let shoppingStore = makeStore(
            name: "Netthandel",
            category: SampleData.shoppingCategory,
            earningRates: [],
            combinations: [makeCombination(totalValueLabel: "10 % Trumf")]
        )
        let highValueCardStore = makeStore(
            name: "Korttilbud",
            category: SampleData.cardCategory,
            earningRates: [],
            combinations: [makeCombination(totalValueLabel: "50 % Trumf")]
        )

        let stores = StoreDiscoveryUseCase().homeShortcutStores(
            from: [highValueCardStore, shoppingStore, groceryStore, activeTravelStore]
        )

        #expect(stores.map(\.name) == ["Aktiv reise", "Dagligvare", "Netthandel", "Korttilbud"])
    }

    @Test
    func supabaseRepositoryMapsStoresEarningRatesAndCombinations() async throws {
        let categoryID = UUID()
        let storeID = UUID()
        let baseRateID = UUID()
        let promotionRateID = UUID()
        let combinationID = UUID()
        let firstStepID = UUID()
        let secondStepID = UUID()
        let methodID = UUID()
        let programID = SampleData.trumf.id

        StoreEarningURLProtocol.requestHandler = { request in
            let path = request.url?.path ?? ""
            let json: String

            if path.hasSuffix("/bonus_programs") {
                json = "[]"
            } else if path.hasSuffix("/program_guides") {
                json = "[]"
            } else if path.hasSuffix("/campaigns") {
                json = "[]"
            } else if path.hasSuffix("/stores") {
                json = """
                [
                  {
                    "id": "\(storeID.uuidString)",
                    "slug": "elkjop",
                    "name": "Elkjøp",
                    "status": "published",
                    "website_url": "https://www.elkjop.no",
                    "search_keywords": ["elektronikk", "telefon"],
                    "last_verified_at": "2026-08-24T10:00:00Z",
                    "campaign_categories": {
                      "id": "\(categoryID.uuidString)",
                      "slug": "elektronikk",
                      "name": "Elektronikk"
                    },
                    "store_earning_rates": [
                      {
                        "id": "\(promotionRateID.uuidString)",
                        "status": "published",
                        "rate_label": "10 % Trumf",
                        "normal_rate_label": "2 % Trumf",
                        "value_summary": "Ekstra verdi",
                        "requirement_summary": "Start i Trumf-portalen",
                        "warning_text": "Kan ha unntak",
                        "handoff_url": "https://www.trumf.no/partner/elkjop",
                        "source_url": "https://www.trumf.no/kampanje/elkjop",
                        "source_title": "Trumf-kampanje",
                        "checked_at": "2026-08-24T11:00:00Z",
                        "starts_at": "2026-08-20T00:00:00Z",
                        "ends_at": "2026-12-31T00:00:00Z",
                        "sort_order": 2,
                        "is_base_rate": false,
                        "earning_methods": {
                          "id": "\(methodID.uuidString)",
                          "slug": "trumf-netthandel",
                          "name": "Trumf netthandel",
                          "method_type": "portal",
                          "program_id": "\(programID.uuidString)",
                          "description": "Gå via Trumf"
                        }
                      },
                      {
                        "id": "\(baseRateID.uuidString)",
                        "status": "published",
                        "rate_label": "2 % Trumf",
                        "normal_rate_label": null,
                        "value_summary": null,
                        "requirement_summary": null,
                        "warning_text": null,
                        "handoff_url": null,
                        "source_url": null,
                        "source_title": null,
                        "checked_at": null,
                        "starts_at": null,
                        "ends_at": null,
                        "sort_order": 1,
                        "is_base_rate": true,
                        "earning_methods": {
                          "id": "\(methodID.uuidString)",
                          "slug": "trumf-netthandel",
                          "name": "Trumf netthandel",
                          "method_type": "portal",
                          "program_id": "\(programID.uuidString)",
                          "description": "Gå via Trumf"
                        }
                      }
                    ],
                    "earning_combinations": [
                      {
                        "id": "\(combinationID.uuidString)",
                        "status": "published",
                        "title": "Trumf først, kort etterpå",
                        "total_value_label": "10 % Trumf",
                        "summary": "Bruk portalen før kjøp",
                        "easier_alternative_label": "Bruk bare grunnopptjening",
                        "warning_text": "Sjekk vilkår",
                        "primary_handoff_url": "https://www.trumf.no/partner/elkjop",
                        "last_verified_at": "2026-08-24T12:00:00Z",
                        "sort_order": 1,
                        "earning_combination_rates": [
                          { "store_earning_rate_id": "\(promotionRateID.uuidString)", "sort_order": 2 },
                          { "store_earning_rate_id": "\(baseRateID.uuidString)", "sort_order": 1 }
                        ],
                        "earning_combination_steps": [
                          { "id": "\(secondStepID.uuidString)", "text": "Betal med riktig kort", "sort_order": 2 },
                          { "id": "\(firstStepID.uuidString)", "text": "Start i Trumf-portalen", "sort_order": 1 }
                        ]
                      }
                    ]
                  },
                  {
                    "id": "\(UUID().uuidString)",
                    "slug": "ignoreres",
                    "name": "Ignoreres",
                    "status": "unknown",
                    "website_url": null,
                    "search_keywords": [],
                    "last_verified_at": null,
                    "campaign_categories": null,
                    "store_earning_rates": [],
                    "earning_combinations": []
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
        defer { StoreEarningURLProtocol.requestHandler = nil }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StoreEarningURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let repository = SupabaseCampaignRepository(
            configuration: SupabaseConfiguration(
                url: URL(string: "https://example.supabase.co")!,
                publishableKey: "test-key"
            ),
            session: session
        )

        let data = try await repository.fetchBootstrapData()
        let store = try #require(data.stores.first)
        let promotionRate = try #require(store.earningRates.first { $0.id == promotionRateID })
        let baseRate = try #require(store.earningRates.first { $0.id == baseRateID })
        let combination = try #require(store.combinations.first)

        #expect(data.stores.map(\.id) == [storeID])
        #expect(store.name == "Elkjøp")
        #expect(store.category?.slug == "elektronikk")
        #expect(store.websiteURL?.absoluteString == "https://www.elkjop.no")
        #expect(store.searchKeywords == ["elektronikk", "telefon"])
        #expect(store.lastVerifiedAt?.timeIntervalSince1970 != nil)
        #expect(baseRate.isBaseRate)
        #expect(baseRate.rateLabel == "2 % Trumf")
        #expect(promotionRate.method.id == methodID)
        #expect(promotionRate.method.type == .portal)
        #expect(promotionRate.method.programID == programID)
        #expect(promotionRate.normalRateLabel == "2 % Trumf")
        #expect(promotionRate.handoffURL?.absoluteString == "https://www.trumf.no/partner/elkjop")
        #expect(promotionRate.sourceTitle == "Trumf-kampanje")
        #expect(store.bestCombination?.id == combinationID)
        #expect(combination.rateIDs == [baseRateID, promotionRateID])
        #expect(combination.steps.map(\.id) == [firstStepID, secondStepID])
        #expect(combination.primaryHandoffURL?.absoluteString == "https://www.trumf.no/partner/elkjop")
    }

    private func makeStore(
        name: String = "Testbutikk",
        status: Store.Status = .published,
        category: CampaignCategory = SampleData.shoppingCategory,
        searchKeywords: [String] = [],
        earningRates: [StoreEarningRate]? = nil,
        combinations: [EarningCombination]? = nil
    ) -> Store {
        Store(
            id: UUID(),
            slug: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            category: category,
            status: status,
            websiteURL: nil,
            searchKeywords: searchKeywords,
            lastVerifiedAt: nil,
            earningRates: earningRates ?? [makeEarningRate()],
            combinations: combinations ?? [makeCombination()]
        )
    }

    private func makeEarningRate(
        id: UUID = UUID(),
        status: StoreEarningRate.Status = .published,
        rateLabel: String = "1 % Trumf",
        programID: UUID? = SampleData.trumf.id,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        sortOrder: Int = 1,
        isBaseRate: Bool = false
    ) -> StoreEarningRate {
        StoreEarningRate(
            id: id,
            method: EarningMethod(
                id: UUID(),
                slug: "trumf-netthandel",
                name: "Trumf netthandel",
                type: .portal,
                programID: programID,
                description: nil
            ),
            status: status,
            rateLabel: rateLabel,
            normalRateLabel: nil,
            valueSummary: nil,
            requirementSummary: nil,
            warningText: nil,
            handoffURL: nil,
            sourceURL: nil,
            sourceTitle: nil,
            checkedAt: nil,
            startsAt: startsAt,
            endsAt: endsAt,
            sortOrder: sortOrder,
            isBaseRate: isBaseRate
        )
    }

    private func makeCombination(
        status: EarningCombination.Status = .published,
        title: String = "Beste kombinasjon",
        totalValueLabel: String = "5 % Trumf",
        sortOrder: Int = 1,
        rateIDs: [UUID] = []
    ) -> EarningCombination {
        EarningCombination(
            id: UUID(),
            status: status,
            title: title,
            totalValueLabel: totalValueLabel,
            summary: "Kort forklaring",
            easierAlternativeLabel: nil,
            warningText: nil,
            primaryHandoffURL: nil,
            lastVerifiedAt: nil,
            sortOrder: sortOrder,
            rateIDs: rateIDs,
            steps: []
        )
    }
}

private final class StoreEarningURLProtocol: URLProtocol {
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
