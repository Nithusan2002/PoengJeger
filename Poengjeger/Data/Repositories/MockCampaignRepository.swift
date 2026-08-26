import Foundation

struct MockCampaignRepository: CampaignRepository {
    private let programs: [BonusProgram]
    private let programGuides: [ProgramGuide]
    private let campaigns: [Campaign]
    private let stores: [Store]
    private let reason: String?

    init(
        programs: [BonusProgram] = SampleData.programs,
        programGuides: [ProgramGuide] = SampleData.programGuides,
        campaigns: [Campaign] = SampleData.campaigns,
        stores: [Store] = SampleData.stores,
        reason: String? = nil
    ) {
        self.programs = programs
        self.programGuides = programGuides
        self.campaigns = campaigns
        self.stores = stores
        self.reason = reason
    }

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        CampaignBootstrapData(
            programs: programs.filter(\.isActive).sorted { $0.name < $1.name },
            programGuides: programGuides.filter { $0.status == .published },
            campaigns: campaigns.filter(\.isActive),
            stores: stores.filter(\.isPublished),
            dataSource: .mock(reason: reason)
        )
    }
}

enum SampleData {
    static let euroBonus = BonusProgram(
        id: UUID(uuidString: "B6E18B31-A655-4316-95A6-BCA95F7AF701")!,
        slug: "sas-eurobonus",
        name: "SAS EuroBonus",
        issuerName: "SAS",
        countryCode: "NO",
        isActive: true
    )

    static let trumf = BonusProgram(
        id: UUID(uuidString: "1A65BD6D-BD33-4A56-B506-5AF4616AB902")!,
        slug: "trumf",
        name: "Trumf",
        issuerName: "NorgesGruppen",
        countryCode: "NO",
        isActive: true
    )

    static let spann = BonusProgram(
        id: UUID(uuidString: "696BEA0A-AE53-40AB-96F7-44E4C5A3B903")!,
        slug: "spenn",
        name: "Spenn",
        issuerName: "Spenn",
        countryCode: "NO",
        isActive: false
    )

    static let programs: [BonusProgram] = [euroBonus, spann, trumf]

    static let programGuides: [ProgramGuide] = [
        ProgramGuide(
            id: UUID(uuidString: "97E492D0-01C7-4856-9B05-96368168A701")!,
            programID: euroBonus.id,
            status: .published,
            introText: "EuroBonus fungerer best når du vet hva poengene skal brukes til. Start med målet ditt, finn ut omtrent hvor mange bonuspoeng du trenger, og bygg opptjeningen rundt kjøp du faktisk ville gjort.",
            strategy: "Lag et enkelt poengkart: flyreiser, dagligvarer, netthandel, hotell, leiebil, abonnementer og kortbruk. Poenget er ikke å handle mer, men å samle eksisterende kjøp i færre, riktige kanaler når pris og vilkår fortsatt er gode.",
            valueEstimateLabel: "Reiseverdi",
            valueEstimateDetail: "Verdien varierer med rute, dato, tilgjengelighet, avgifter og hva samme reise ville kostet kontant.",
            expirationSummary: "Sjekk poengtype",
            expirationDetail: "Bonuspoeng kan brukes til reiser og andre fordeler. Nivåpoeng teller mot medlemsnivå og følger kvalifiseringsperioden.",
            guideKicker: "PROGRAMGUIDE",
            readingTimeLabel: "4 min lesing",
            strategySectionTitle: "Slik bør du bruke det",
            decisionSectionTitle: "Før du går videre",
            earningDecisionLabel: "Tjen poeng når",
            redemptionDecisionLabel: "Bruk poeng når",
            riskDecisionLabel: "Stopp opp hvis",
            earningSectionTitle: "Slik tjener du poeng",
            earningSectionIntro: "Start med målet, og bygg opptjeningen rundt kjøp du allerede har.",
            redemptionSectionTitle: "Slik bruker du poengene smart",
            redemptionSectionIntro: "Bruk poengene der forskjellen mot kontantpris faktisk er tydelig.",
            riskSectionTitle: "Vanlige feller",
            riskSectionIntro: "Det som gjør en sterk poengmulighet svakere i praksis.",
            campaignsSectionTitle: "Kampanjer nå",
            campaignsSectionIntro: "Aktive kampanjer knyttet til SAS EuroBonus.",
            earningTips: [
                "Definer målet først: rabatt på en kort tur, bonusreise, oppgradering eller en større reise for flere personer.",
                "Skil mellom bonuspoeng og nivåpoeng før du vurderer en kampanje.",
                "Kartlegg de store kanalene først: fly og SkyTeam-partnere, SAS-partnere, Trumf, netthandelsportaler, hotell, leiebil og betalingskort.",
                "Start netthandel og partnerkjøp fra riktig portal eller lenke når sporing er en del av vilkårene.",
                "Bruk dobbelopptjening bare når den er enkel: riktig portal eller partner pluss et kort som gir EuroBonus-poeng.",
                "Sjekk kampanjer og velkomstbonuser, men regn med gebyrer, binding og omsetningskrav før du lar dem styre valget."
            ],
            redemptionTips: [
                "Bruk poeng der kontantprisen er høy og tilgjengeligheten passer datoene dine.",
                "Sammenlign poengpris med ordinær pris, skatter, gebyrer og billettfleksibilitet.",
                "Sjekk om award flight, oppgradering eller annen poengbruk passer bedre enn å betale kontant.",
                "Ikke bind deg til opptjening hvis du ikke har en realistisk plan for bruk innen rimelig tid.",
                "Sjekk alternative avganger før du konkluderer med at en kampanje gir god verdi."
            ],
            riskNotes: [
                "Tilgjengelighet på bonusreiser kan være begrenset på populære datoer og ruter.",
                "Kampanjer kan være målrettet eller ha krav som ikke er synlige i overskriften.",
                "Poengverdi er et estimat, ikke en fast kurs.",
                "Gebyrer, skatter og manglende fleksibilitet kan spise opp mye av verdien.",
                "Kortavgifter, omsetningskrav og dyrere butikker kan koste mer enn poengene er verdt for deg.",
                "Dobbel- og trippelopptjening kan feile hvis sporing, rabattkoder, korttype eller partnerregler ikke passer."
            ],
            lastReviewedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 26))
        ),
        ProgramGuide(
            id: UUID(uuidString: "97E492D0-01C7-4856-9B05-96368168A702")!,
            programID: trumf.id,
            status: .published,
            introText: "Trumf er enklere enn mange poengprogrammer fordi bonusen har tydelig kroneverdi. Den viktigste vurderingen er likevel om totalprisen fortsatt er god etter at bonusen er regnet inn.",
            strategy: "Bruk Trumf som rabatt på kjøp du uansett ville gjort. Ekstra bonus er mest interessant når prisen, butikkvalget og vilkårene fortsatt er fornuftige uten at bonusen må redde regnestykket.",
            valueEstimateLabel: "Kronebonus",
            valueEstimateDetail: "Trumf-bonus opptjenes i kroner. Verdien endrer seg først når du velger bruksmåte, for eksempel butikk, bankkonto eller overføring til EuroBonus.",
            expirationSummary: "Fleksibelt",
            expirationDetail: "Sjekk saldo, uttak og overføringsvilkår før du flytter bonus til andre programmer.",
            guideKicker: "PROGRAMGUIDE",
            readingTimeLabel: "3 min lesing",
            strategySectionTitle: "Slik bør du bruke det",
            decisionSectionTitle: "Før du går videre",
            earningDecisionLabel: "Tjen bonus når",
            redemptionDecisionLabel: "Bruk bonus når",
            riskDecisionLabel: "Stopp opp hvis",
            earningSectionTitle: "Slik tjener du Trumf",
            earningSectionIntro: "Start med handlemønsteret ditt, ikke med bonusprosenten.",
            redemptionSectionTitle: "Slik bruker du bonusen smart",
            redemptionSectionIntro: "Velg bruksmåten som gir mest verdi og minst friksjon for deg.",
            riskSectionTitle: "Vanlige feller",
            riskSectionIntro: "Detaljer som ofte avgjør om Trumf faktisk lønner seg.",
            campaignsSectionTitle: "Kampanjer nå",
            campaignsSectionIntro: "Aktive kampanjer knyttet til Trumf.",
            earningTips: [
                "Aktiver personlige eller tidsbegrensede kampanjer før kjøp når det kreves.",
                "Sjekk om bonusen gjelder hele handelen, bestemte varer, bestemte butikker eller netthandel via partner.",
                "Vurder totalpris først, bonus etterpå.",
                "Bruk handlelister og planlagte kjøp til å skille nyttig bonus fra mersalg.",
                "Kontroller om kuponger, rabatter eller betalingsmåte påvirker bonusgrunnlaget."
            ],
            redemptionTips: [
                "Bruk saldoen som kontantbonus når det gir konkret verdi for deg.",
                "Vurder overføring til EuroBonus bare når du forstår vilkår, timing og hva poengene skal brukes til.",
                "Se etter kampanjer som gir ekstra bonus på kjøp du uansett skulle gjøre.",
                "Hold oversikt over aktiveringskrav og kampanjeperioder.",
                "Sammenlign alltid bonusen med billigste realistiske alternativ."
            ],
            riskNotes: [
                "Utvalg, butikk, medlemskrav og aktivering kan variere mellom kampanjer.",
                "Bonus kan beregnes etter rabatter eller med unntak for enkelte varer.",
                "Ikke la bonusprosent alene styre kjøpet.",
                "Høy ekstra bonus kan fortsatt være dårlig verdi hvis varen er dyrere enn hos alternativer.",
                "Overføring til andre programmer kan gjøre en fleksibel kroneverdi mindre fleksibel."
            ],
            lastReviewedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 26))
        ),
        ProgramGuide(
            id: UUID(uuidString: "97E492D0-01C7-4856-9B05-96368168A703")!,
            programID: spann.id,
            status: .published,
            introText: "Spenn er mest nyttig når du allerede bruker partnerne. Start med kampanjer som passer et kjøp du faktisk skal gjøre.",
            strategy: "Bruk Spenn når partneren allerede passer planene dine. Ikke jag små poeng hvis du må kjøpe noe ekstra.",
            valueEstimateLabel: "Partnerverdi",
            valueEstimateDetail: "Verdien styres av hvor du kan opptjene og bruke poengene.",
            expirationSummary: "Følg saldo",
            expirationDetail: "Kontroller program- og partnervilkår før større opptjening eller bruk.",
            earningTips: [
                "Knytt kjøpet til riktig partnerflyt før betaling.",
                "Prioriter kampanjer på reise, hotell eller handel du allerede har behov for.",
                "Sjekk om kampanjen krever registrering, appbruk eller en bestemt lenke."
            ],
            redemptionTips: [
                "Sammenlign poengbruk med kontantpris før du bruker saldo.",
                "Bruk poeng der du enkelt ser hva du får igjen.",
                "Ikke spre poengene for mye hvis saldoen aldri blir stor nok til noe nyttig."
            ],
            riskNotes: [
                "Partnerkrav kan gjøre en enkel kampanje mindre enkel i praksis.",
                "Verdien av poengbruk kan variere mellom partnere.",
                "Kampanjer kan kreve korrekt sporing for at bonusen skal registreres."
            ],
            lastReviewedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))
        )
    ]

    static let groceryCategory = CampaignCategory(
        id: UUID(uuidString: "51EC3B45-91D1-4FA1-95C4-16120E16C111")!,
        slug: "dagligvare",
        name: "Dagligvare"
    )

    static let cardCategory = CampaignCategory(
        id: UUID(uuidString: "4466E11C-3E27-4F6B-8EA0-CDE79CC97A12")!,
        slug: "kredittkort",
        name: "Kredittkort"
    )

    static let shoppingCategory = CampaignCategory(
        id: UUID(uuidString: "1D66D16A-0D0A-4E78-9C1A-B7AB1A0C0102")!,
        slug: "shopping",
        name: "Netthandel"
    )

    static let travelCategory = CampaignCategory(
        id: UUID(uuidString: "3A850A1A-96F1-4AE1-8CD9-4EB49AA7A113")!,
        slug: "reise",
        name: "Reise"
    )

    static let euroBonusShopping = EarningMethod(
        id: UUID(uuidString: "830C77EC-1589-4B7F-9F29-3E18EB2C0201")!,
        slug: "eurobonus-shopping",
        name: "EuroBonus Shopping",
        type: .portal,
        programID: euroBonus.id,
        description: "Start handelen via EuroBonus Shopping-portalen."
    )

    static let trumfMethod = EarningMethod(
        id: UUID(uuidString: "830C77EC-1589-4B7F-9F29-3E18EB2C0202")!,
        slug: "trumf",
        name: "Trumf",
        type: .loyalty,
        programID: trumf.id,
        description: "Opptjening via Trumf-medlemskap eller partner."
    )

    static let sasMastercardPremium = EarningMethod(
        id: UUID(uuidString: "830C77EC-1589-4B7F-9F29-3E18EB2C0203")!,
        slug: "sas-mastercard-premium",
        name: "SAS Mastercard Premium",
        type: .card,
        programID: euroBonus.id,
        description: "Kortopptjening for brukere som allerede har riktig kort."
    )

    static let campaignMethod = EarningMethod(
        id: UUID(uuidString: "830C77EC-1589-4B7F-9F29-3E18EB2C0204")!,
        slug: "aktuell-kampanje",
        name: "Aktuell kampanje",
        type: .campaign,
        programID: nil,
        description: "Tidsbegrenset forbedring."
    )

    static let stores: [Store] = [
        makeStore(
            id: UUID(uuidString: "720B66DB-0478-4A6E-8E18-2D07DA1B0101")!,
            slug: "elkjop",
            name: "Elkjøp",
            category: shoppingCategory,
            keywords: ["elektronikk", "tv", "mobil", "data"],
            rates: [
                makeRate(
                    id: UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0301")!,
                    method: euroBonusShopping,
                    rateLabel: "10 poeng / 100 kr",
                    valueSummary: "Vanlig opptjening via EuroBonus Shopping.",
                    requirementSummary: "Start via EuroBonus Shopping før du går til Elkjøp.",
                    warningText: "Ikke bruk en annen rabattportal etter at handelen er startet.",
                    handoffURL: URL(string: "https://www.sas.no/eurobonus/partners/shopping/"),
                    sortOrder: 10,
                    isBaseRate: true
                ),
                makeRate(
                    id: UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0302")!,
                    method: campaignMethod,
                    rateLabel: "20 poeng / 100 kr",
                    normalRateLabel: "10 poeng / 100 kr",
                    valueSummary: "Midlertidig forbedret opptjening hos Elkjøp.",
                    requirementSummary: "Må startes via EuroBonus Shopping i kampanjeperioden.",
                    warningText: "Kontroller at Elkjøp fortsatt vises med forhøyet sats før kjøp.",
                    handoffURL: URL(string: "https://www.sas.no/eurobonus/partners/shopping/"),
                    endsAt: Calendar.current.date(byAdding: .day, value: 5, to: .now),
                    sortOrder: 20
                ),
                makeRate(
                    id: UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0303")!,
                    method: sasMastercardPremium,
                    rateLabel: "5 poeng / 100 kr",
                    valueSummary: "Kortopptjening dersom du allerede har SAS Mastercard Premium.",
                    requirementSummary: "Krever SAS Mastercard Premium og vanlig kortbruk.",
                    sortOrder: 30
                )
            ],
            combinations: [
                EarningCombination(
                    id: UUID(uuidString: "A51E990E-37AB-4D91-B141-503AFD4E0401")!,
                    status: .published,
                    title: "Beste kombinasjon",
                    totalValueLabel: "25 EuroBonus-poeng / 100 kr",
                    summary: "Start via EuroBonus Shopping mens forhøyet sats gjelder, og betal med SAS Mastercard Premium hvis du allerede har kortet.",
                    easierAlternativeLabel: "20 poeng / 100 kr uten kort",
                    warningText: "Ikke bruk annen rabattportal etter at du har startet handelen.",
                    primaryHandoffURL: URL(string: "https://www.sas.no/eurobonus/partners/shopping/"),
                    lastVerifiedAt: .now,
                    sortOrder: 10,
                    rateIDs: [
                        UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0302")!,
                        UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0303")!
                    ],
                    steps: [
                        EarningCombinationStep(id: UUID(), text: "Start hos EuroBonus Shopping.", sortOrder: 10),
                        EarningCombinationStep(id: UUID(), text: "Gå videre til Elkjøp fra portalen.", sortOrder: 20),
                        EarningCombinationStep(id: UUID(), text: "Betal med SAS Mastercard Premium hvis du allerede har kortet.", sortOrder: 30),
                        EarningCombinationStep(id: UUID(), text: "Fullfør kjøpet før kampanjen utløper.", sortOrder: 40)
                    ]
                )
            ]
        ),
        makeStore(
            id: UUID(uuidString: "720B66DB-0478-4A6E-8E18-2D07DA1B0102")!,
            slug: "komplett",
            name: "Komplett",
            category: shoppingCategory,
            keywords: ["elektronikk", "pc", "gaming"],
            rates: [
                makeRate(
                    id: UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0304")!,
                    method: euroBonusShopping,
                    rateLabel: "15 poeng / 100 kr",
                    valueSummary: "Vanlig opptjening via EuroBonus Shopping.",
                    requirementSummary: "Start via EuroBonus Shopping før du går til Komplett.",
                    warningText: "Ikke bruk annen portal eller rabattlenke underveis.",
                    handoffURL: URL(string: "https://www.sas.no/eurobonus/partners/shopping/"),
                    sortOrder: 10,
                    isBaseRate: true
                )
            ],
            combinations: [
                makeCombination(
                    id: UUID(uuidString: "A51E990E-37AB-4D91-B141-503AFD4E0402")!,
                    totalValueLabel: "15 EuroBonus-poeng / 100 kr",
                    summary: "Start via EuroBonus Shopping og fullfør hos Komplett i samme økt.",
                    warningText: "Ikke bruk en annen portal underveis.",
                    handoffURL: URL(string: "https://www.sas.no/eurobonus/partners/shopping/"),
                    rateIDs: [UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0304")!],
                    steps: ["Start hos EuroBonus Shopping.", "Gå videre til Komplett og fullfør i samme økt."]
                )
            ]
        ),
        makeStore(
            id: UUID(uuidString: "720B66DB-0478-4A6E-8E18-2D07DA1B0103")!,
            slug: "meny",
            name: "Meny",
            category: groceryCategory,
            keywords: ["dagligvare", "mat", "trumf"],
            rates: [
                makeRate(
                    id: UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0305")!,
                    method: trumfMethod,
                    rateLabel: "1 % Trumf",
                    valueSummary: "Vanlig Trumf-opptjening på dagligvarer.",
                    requirementSummary: "Bruk Trumf-medlemskap i kassen.",
                    handoffURL: URL(string: "https://www.trumf.no"),
                    sortOrder: 10,
                    isBaseRate: true
                )
            ],
            combinations: [
                makeCombination(
                    id: UUID(uuidString: "A51E990E-37AB-4D91-B141-503AFD4E0403")!,
                    totalValueLabel: "1 % Trumf",
                    summary: "Bruk Trumf-medlemskap ved betaling. Vurder totalpris før bonus.",
                    handoffURL: URL(string: "https://www.trumf.no"),
                    rateIDs: [UUID(uuidString: "940D88FD-269A-4C80-A030-4F29FC3D0305")!],
                    steps: ["Bruk Trumf-medlemskap når du handler hos Meny.", "Sjekk at bonusen er registrert etter kjøpet."]
                )
            ]
        )
    ]

    static let campaigns: [Campaign] = [
        Campaign(
            id: UUID(uuidString: "BA1E58DE-4B08-49CC-B3E9-20DB4460A101")!,
            title: "15 % Trumf-bonus på utvalgte varer",
            summary: "15 % Trumf-bonus på utvalgte dagligvarer i en kort periode.",
            details: "Du får 15 % Trumf-bonus på utvalgte varer hos Kiwi og Meny. For Trumf-medlemmer er dette enkelt: aktiver kampanjen før du handler.",
            status: .published,
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: .now),
            lastVerifiedAt: Calendar.current.date(byAdding: .hour, value: -6, to: .now) ?? .now,
            primaryProgramID: trumf.id,
            category: groceryCategory,
            editorialScore: 82,
            editorialSummary: "Høy verdi for vanlige dagligvarekjøp.",
            isFeatured: true,
            requirements: [
                CampaignRequirement(
                    id: UUID(uuidString: "5C53D4C5-F41E-480D-BE98-5C3CAFE9A201")!,
                    text: "Aktiver kampanjen i Trumf-appen før kjøp.",
                    sortOrder: 0
                )
            ],
            sources: [
                CampaignSourceReference(
                    id: UUID(uuidString: "56556B3D-65B1-418E-A6A1-AEE147C4A201")!,
                    sourceName: "Trumf",
                    url: URL(string: "https://www.trumf.no")!,
                    title: "Ukens Trumf-kampanjer",
                    checkedAt: Calendar.current.date(byAdding: .hour, value: -6, to: .now) ?? .now,
                    evidenceNote: "Kontrollert mot kampanjeside."
                )
            ],
            editorialAssessment: EditorialAssessment(
                score: 82,
                decisionLabel: .worthChecking,
                decisionSummary: "Verdt å sjekke hvis du uansett handler dagligvarer hos Kiwi eller Meny denne uken.",
                bestFor: "Deg som allerede skal handle hos Kiwi eller Meny.",
                notFor: "Deg som må bytte butikk eller kjøpe ekstra for å bruke tilbudet.",
                reasonWhyItMatters: "Bra hvis du uansett handler hos Kiwi eller Meny denne uken.",
                estimatedValueText: "Kan gi god rabatt på vanlige dagligvarer.",
                difficultyLevel: .low,
                availabilityScope: .broad,
                riskNote: "Utvalget kan variere mellom butikker."
            ),
            geoRestrictions: [GeoRestriction(id: UUID(), countryCode: "NO")],
            linkedProgramIDs: [trumf.id]
        ),
        Campaign(
            id: UUID(uuidString: "268C2389-7558-4E10-B241-3A250281A102")!,
            title: "Ekstrapoeng på SAS Mastercard-aktivering",
            summary: "Mange EuroBonus-poeng, men bare hvis kortet faktisk passer deg.",
            details: "Nye eller tidligere kortholdere kan få en engangsbonus i EuroBonus. Du må bruke kortet for et bestemt beløp innen kampanjeperioden.",
            status: .published,
            startDate: Calendar.current.date(byAdding: .day, value: -5, to: .now),
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: .now),
            lastVerifiedAt: Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now,
            primaryProgramID: euroBonus.id,
            category: cardCategory,
            editorialScore: 76,
            editorialSummary: "God verdi dersom du faktisk trenger kortet.",
            isFeatured: false,
            requirements: [
                CampaignRequirement(
                    id: UUID(uuidString: "5209E3AE-9312-4F06-B0A5-2BB4F3C6A202")!,
                    text: "Søk om kort og bruk det for minst 10 000 kroner innen 30 dager.",
                    sortOrder: 0
                )
            ],
            sources: [
                CampaignSourceReference(
                    id: UUID(uuidString: "C6748B07-A22C-459D-B085-4B6E9AD5A202")!,
                    sourceName: "SAS EuroBonus Mastercard",
                    url: URL(string: "https://saseurobonusmastercard.no")!,
                    title: "Velkomstbonus",
                    checkedAt: Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now,
                    evidenceNote: "Vilkår kontrollert på kortutsteders landingsside."
                )
            ],
            editorialAssessment: EditorialAssessment(
                score: 76,
                decisionLabel: .niche,
                decisionSummary: "Kun relevant hvis du allerede vurderer kortet og klarer brukskravet uten ekstra kjøp.",
                bestFor: "Deg som faktisk trenger kortet og tåler kredittsjekken.",
                notFor: "Deg som vil unngå nytt kort, gebyrer eller ekstra kortbruk.",
                reasonWhyItMatters: "Kan være verdifullt, men bare hvis du vil ha kortet og klarer kravet uten ekstra kjøp.",
                estimatedValueText: "Best for brukere som allerede vurderer nytt kort.",
                difficultyLevel: .medium,
                availabilityScope: .regional,
                riskNote: "Ikke relevant for brukere som vil unngå kredittsøk."
            ),
            geoRestrictions: [GeoRestriction(id: UUID(), countryCode: "NO")],
            linkedProgramIDs: [euroBonus.id]
        ),
        Campaign(
            id: UUID(uuidString: "535E4EDC-4980-492B-A2A4-34B2F2F5A103")!,
            title: "Spenn dobbel opptjening hos partnerhoteller",
            summary: "Enkel partnerkampanje for eksisterende Spenn-brukere.",
            details: "Utvalgte partnerhoteller gir dobbel opptjening i en begrenset periode. Kampanjen er mest relevant for brukere med planlagte opphold i Norge.",
            status: .published,
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now),
            endDate: Calendar.current.date(byAdding: .day, value: 14, to: .now),
            lastVerifiedAt: Calendar.current.date(byAdding: .hour, value: -10, to: .now) ?? .now,
            primaryProgramID: spann.id,
            category: CampaignCategory(
                id: UUID(uuidString: "3A850A1A-96F1-4AE1-8CD9-4EB49AA7A113")!,
                slug: "reise",
                name: "Reise"
            ),
            editorialScore: 71,
            editorialSummary: "Relevant hvis du allerede har hotellbehov.",
            isFeatured: false,
            requirements: [
                CampaignRequirement(
                    id: UUID(uuidString: "B2832D0D-F70A-46EA-B4FB-E7E8A28DA203")!,
                    text: "Bestill gjennom partnerlenken og registrer Spenn-nummeret ditt.",
                    sortOrder: 0
                )
            ],
            sources: [
                CampaignSourceReference(
                    id: UUID(uuidString: "B358CF3A-27F0-47A2-B436-15F32A9B8203")!,
                    sourceName: "Spenn",
                    url: URL(string: "https://spenn.com")!,
                    title: "Hotellpartnere",
                    checkedAt: Calendar.current.date(byAdding: .hour, value: -10, to: .now) ?? .now,
                    evidenceNote: nil
                )
            ],
            editorialAssessment: EditorialAssessment(
                score: 71,
                decisionLabel: .niche,
                decisionSummary: "Kun relevant hvis du allerede har et hotellopphold som passer partneren.",
                bestFor: "Deg som allerede skal bestille hotell hos en partner.",
                notFor: "Deg som må endre reiseplan eller betale mer for å få bonusen.",
                reasonWhyItMatters: "Nyttig hvis du allerede skal bestille hotell. Mindre relevant hvis du ikke har en reiseplan.",
                estimatedValueText: "Moderat verdi ved allerede planlagt opphold.",
                difficultyLevel: .low,
                availabilityScope: .narrow,
                riskNote: "Krever partnerbooking."
            ),
            geoRestrictions: [GeoRestriction(id: UUID(), countryCode: "NO")],
            linkedProgramIDs: [spann.id]
        )
    ]

    private static func makeStore(
        id: UUID,
        slug: String,
        name: String,
        category: CampaignCategory,
        keywords: [String],
        rates: [StoreEarningRate],
        combinations: [EarningCombination]
    ) -> Store {
        Store(
            id: id,
            slug: slug,
            name: name,
            category: category,
            status: .published,
            websiteURL: URL(string: "https://www.\(slug).no"),
            searchKeywords: keywords,
            lastVerifiedAt: .now,
            earningRates: rates,
            combinations: combinations
        )
    }

    private static func makeRate(
        id: UUID,
        method: EarningMethod,
        rateLabel: String,
        normalRateLabel: String? = nil,
        valueSummary: String? = nil,
        requirementSummary: String? = nil,
        warningText: String? = nil,
        handoffURL: URL? = nil,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        sortOrder: Int,
        isBaseRate: Bool = false
    ) -> StoreEarningRate {
        StoreEarningRate(
            id: id,
            method: method,
            status: .published,
            rateLabel: rateLabel,
            normalRateLabel: normalRateLabel,
            valueSummary: valueSummary,
            requirementSummary: requirementSummary,
            warningText: warningText,
            handoffURL: handoffURL,
            sourceURL: handoffURL,
            sourceTitle: method.name,
            checkedAt: .now,
            startsAt: startsAt,
            endsAt: endsAt,
            sortOrder: sortOrder,
            isBaseRate: isBaseRate
        )
    }

    private static func makeCombination(
        id: UUID,
        totalValueLabel: String,
        summary: String,
        easierAlternativeLabel: String? = nil,
        warningText: String? = nil,
        handoffURL: URL?,
        rateIDs: [UUID],
        steps: [String]
    ) -> EarningCombination {
        EarningCombination(
            id: id,
            status: .published,
            title: "Beste kombinasjon",
            totalValueLabel: totalValueLabel,
            summary: summary,
            easierAlternativeLabel: easierAlternativeLabel,
            warningText: warningText,
            primaryHandoffURL: handoffURL,
            lastVerifiedAt: .now,
            sortOrder: 10,
            rateIDs: rateIDs,
            steps: steps.enumerated().map { index, text in
                EarningCombinationStep(id: UUID(), text: text, sortOrder: (index + 1) * 10)
            }
        )
    }
}
