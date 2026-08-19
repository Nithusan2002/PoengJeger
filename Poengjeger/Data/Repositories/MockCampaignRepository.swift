import Foundation

struct MockCampaignRepository: CampaignRepository {
    private let programs: [BonusProgram]
    private let programGuides: [ProgramGuide]
    private let campaigns: [Campaign]

    init(
        programs: [BonusProgram] = SampleData.programs,
        programGuides: [ProgramGuide] = SampleData.programGuides,
        campaigns: [Campaign] = SampleData.campaigns
    ) {
        self.programs = programs
        self.programGuides = programGuides
        self.campaigns = campaigns
    }

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        CampaignBootstrapData(
            programs: programs.filter(\.isActive).sorted { $0.name < $1.name },
            programGuides: programGuides.filter { $0.status == .published },
            campaigns: campaigns.filter(\.isActive),
            dataSource: .mock(reason: nil)
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
            introText: "EuroBonus er nyttig når du har en konkret plan for opptjening og bruk. Guiden hjelper deg å vurdere kampanjer opp mot fleksibilitet, gebyrer og faktisk reisebehov.",
            strategy: "EuroBonus passer best når du kan samle nok poeng til reiser eller fordeler du faktisk vil bruke. Vurder kampanjer opp mot fleksibilitet, gebyrer og om reisen allerede er relevant.",
            valueEstimateLabel: "Varierer",
            valueEstimateDetail: "Verdien avhenger av reisemål, tilgjengelighet, avgifter og alternativ kontantpris.",
            expirationSummary: "Sjekk vilkår",
            expirationDetail: "Kontroller alltid gjeldende utløpsregler hos SAS før du lar saldo ligge lenge.",
            earningTips: [
                "Prioriter kampanjer der du uansett skal kjøpe reisen, varen eller tjenesten.",
                "Se etter kombinasjoner av kort, partner og tidsbegrenset kampanje, men kontroller vilkårene før du handler.",
                "Vær ekstra kritisk til tilbud som krever nytt kredittkort eller høyt kortbruk."
            ],
            redemptionTips: [
                "Bruk poeng der kontantprisen er høy og tilgjengeligheten passer dine datoer.",
                "Sammenlign poengbruk med ordinær pris, skatter, gebyrer og fleksibilitet.",
                "Ikke bind deg til opptjening hvis du ikke har en realistisk plan for bruk."
            ],
            riskNotes: [
                "Tilgjengelighet på bonusreiser kan være begrenset.",
                "Kampanjer kan være målrettet eller ha krav som ikke er synlige i overskriften.",
                "Poengverdi er et estimat, ikke en fast kurs."
            ],
            lastReviewedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))
        ),
        ProgramGuide(
            id: UUID(uuidString: "97E492D0-01C7-4856-9B05-96368168A702")!,
            programID: trumf.id,
            status: .published,
            introText: "Trumf er lett å forstå fordi bonusen kan brukes som penger. Totalprisen bør likevel styre valget.",
            strategy: "Trumf er ofte mest nyttig når bonusen kommer fra dagligvarekjøp du allerede ville gjort. Høy prosentbonus er mindre verdt hvis varen er dyrere enn alternativet.",
            valueEstimateLabel: "1 kr = 1 kr",
            valueEstimateDetail: "Trumf-bonus er konkret kroneverdi, men kampanjeverdi må vurderes mot totalpris.",
            expirationSummary: "Lett å bruke",
            expirationDetail: "Sjekk saldo og overføringsvilkår før du flytter bonus til andre programmer.",
            earningTips: [
                "Aktiver kampanjer før kjøp når det kreves.",
                "Sjekk om bonusen gjelder hele handelen eller bare utvalgte varer.",
                "Vurder totalpris først, bonus etterpå."
            ],
            redemptionTips: [
                "Bruk saldoen der den gir konkret verdi for deg, eller overfør bare når vilkårene passer.",
                "Se etter kampanjer som gir ekstra bonus på kjøp du uansett skulle gjøre.",
                "Hold oversikt over aktiveringskrav og kampanjeperioder."
            ],
            riskNotes: [
                "Utvalg, butikk og medlemskrav kan variere.",
                "Bonus kan beregnes etter rabatter eller med unntak for enkelte varer.",
                "Ikke la bonusprosent alene styre kjøpet."
            ],
            lastReviewedAt: Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 10))
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
}
