import Foundation

struct MockCampaignRepository: CampaignRepository {
    private let programs: [BonusProgram]
    private let campaigns: [Campaign]

    init(
        programs: [BonusProgram] = SampleData.programs,
        campaigns: [Campaign] = SampleData.campaigns
    ) {
        self.programs = programs
        self.campaigns = campaigns
    }

    func fetchPrograms() -> [BonusProgram] {
        programs.filter(\.isActive).sorted { $0.name < $1.name }
    }

    func fetchActiveCampaigns() -> [Campaign] {
        campaigns.filter(\.isActive)
    }

    func fetchFavorites(for favoriteIDs: Set<UUID>) -> [Campaign] {
        campaigns.filter { favoriteIDs.contains($0.id) }
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
        isActive: true
    )

    static let programs: [BonusProgram] = [euroBonus, spann, trumf]

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
            summary: "Tidsbegrenset dagligvarekampanje med lav terskel for bruk.",
            details: "Kampanjen gir 15 % Trumf-bonus på utvalgte varer hos Kiwi og Meny. Tilbudet er bredt tilgjengelig og enkelt å benytte for eksisterende medlemmer.",
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
                reasonWhyItMatters: "Gir konkret verdi uten nytt kundeforhold eller kompliserte vilkår.",
                estimatedValueText: "Høy verdi for husholdninger som allerede handler i NorgesGruppen.",
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
            summary: "Kortkampanje med høy poengverdi, men litt høyere terskel.",
            details: "Nye eller reaktiverte kortholdere kan få en engangsbonus i EuroBonus ved å oppnå minimumsforbruk i kampanjeperioden.",
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
                reasonWhyItMatters: "Høy poengverdi, men krever aktivt valg og minimumsforbruk.",
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
                reasonWhyItMatters: "Lav friksjon for eksisterende reiser, men smalere relevans enn dagligvare og kort.",
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
