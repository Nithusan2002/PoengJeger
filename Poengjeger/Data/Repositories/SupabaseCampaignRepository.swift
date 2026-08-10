import Foundation

struct SupabaseConfiguration {
    let url: URL
    let publishableKey: String

    static func fromBundle(bundle: Bundle = .main) -> SupabaseConfiguration? {
        let host = bundle.object(forInfoDictionaryKey: "SUPABASE_HOST") as? String
        let publishableKey = bundle.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String

        guard
            let host,
            let apiKey = publishableKey?.trimmingCharacters(in: .whitespacesAndNewlines),
            !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !apiKey.isEmpty,
            !host.contains("$("),
            !apiKey.contains("$("),
            let url = URL(string: "https://\(host)")
        else {
            return nil
        }

        return SupabaseConfiguration(url: url, publishableKey: apiKey)
    }
}

struct FallbackCampaignRepository: CampaignRepository {
    let primary: CampaignRepository
    let fallback: CampaignRepository

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        do {
            return try await primary.fetchBootstrapData()
        } catch {
            let fallbackData = try await fallback.fetchBootstrapData()
            return CampaignBootstrapData(
                programs: fallbackData.programs,
                programGuides: fallbackData.programGuides,
                campaigns: fallbackData.campaigns,
                dataSource: .mock(reason: error.localizedDescription)
            )
        }
    }
}

struct SupabaseCampaignRepository: CampaignRepository {
    private let configuration: SupabaseConfiguration
    private let session: URLSession

    init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func fetchBootstrapData() async throws -> CampaignBootstrapData {
        async let programs = fetchPrograms()
        async let programGuides = fetchProgramGuides()
        async let campaigns = fetchCampaigns()

        return try await CampaignBootstrapData(
            programs: programs,
            programGuides: programGuides,
            campaigns: campaigns,
            dataSource: .supabase
        )
    }

    private func fetchPrograms() async throws -> [BonusProgram] {
        let queryItems = [
            URLQueryItem(name: "select", value: "id,slug,name,issuer_name,country_code,is_active"),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "name.asc")
        ]

        let response: [BonusProgramDTO] = try await request(path: "bonus_programs", queryItems: queryItems)
        return response.map(\.domainModel)
    }

    private func fetchProgramGuides() async throws -> [ProgramGuide] {
        let queryItems = [
            URLQueryItem(name: "select", value: "id,program_id,status,intro_text,strategy,value_estimate_label,value_estimate_detail,expiration_summary,expiration_detail,earning_tips,redemption_tips,risk_notes,last_reviewed_at"),
            URLQueryItem(name: "status", value: "eq.published"),
            URLQueryItem(name: "order", value: "last_reviewed_at.desc.nullslast")
        ]

        let response: [ProgramGuideDTO] = try await request(path: "program_guides", queryItems: queryItems)
        return response.compactMap(\.domainModel)
    }

    private func fetchCampaigns() async throws -> [Campaign] {
        let select = [
            "id",
            "title",
            "summary",
            "details",
            "status",
            "start_date",
            "end_date",
            "last_verified_at",
            "primary_program_id",
            "editorial_score",
            "editorial_summary",
            "is_featured",
            "campaign_categories(id,slug,name)",
            "campaign_requirements(id,text,sort_order)",
            "campaign_source_references(id,url,title,checked_at,evidence_note,campaign_sources(name))",
            "campaign_editorial_assessments(score,reason_why_it_matters,estimated_value_text,difficulty_level,availability_scope,risk_note)",
            "campaign_geo_restrictions(id,country_code)",
            "campaign_programs(program_id)"
        ].joined(separator: ",")

        let queryItems = [
            URLQueryItem(name: "select", value: select),
            URLQueryItem(name: "status", value: "eq.published"),
            URLQueryItem(name: "order", value: "is_featured.desc,last_verified_at.desc")
        ]

        let response: [CampaignDTO] = try await request(path: "campaigns", queryItems: queryItems)
        return response.compactMap(\.domainModel).filter(\.isActive)
    }

    private func request<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> Response {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard var components = URLComponents(url: configuration.url, resolvingAgainstBaseURL: false) else {
            throw SupabaseRepositoryError.invalidConfiguration
        }

        components.path = "/rest/v1/\(path)"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SupabaseRepositoryError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseRepositoryError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let apiError = try? decoder.decode(SupabaseAPIError.self, from: data)
            throw SupabaseRepositoryError.httpError(
                statusCode: httpResponse.statusCode,
                message: apiError?.message ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseRepositoryError.decodingFailed(error)
        }
    }
}

private struct BonusProgramDTO: Decodable {
    let id: UUID
    let slug: String
    let name: String
    let issuerName: String
    let countryCode: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case name
        case issuerName = "issuer_name"
        case countryCode = "country_code"
        case isActive = "is_active"
    }

    var domainModel: BonusProgram {
        BonusProgram(
            id: id,
            slug: slug,
            name: name,
            issuerName: issuerName,
            countryCode: countryCode,
            isActive: isActive
        )
    }
}

private struct ProgramGuideDTO: Decodable {
    let id: UUID
    let programID: UUID
    let status: String
    let introText: String?
    let strategy: String
    let valueEstimateLabel: String?
    let valueEstimateDetail: String?
    let expirationSummary: String?
    let expirationDetail: String?
    let earningTips: [String]
    let redemptionTips: [String]
    let riskNotes: [String]
    let lastReviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case programID = "program_id"
        case status
        case introText = "intro_text"
        case strategy
        case valueEstimateLabel = "value_estimate_label"
        case valueEstimateDetail = "value_estimate_detail"
        case expirationSummary = "expiration_summary"
        case expirationDetail = "expiration_detail"
        case earningTips = "earning_tips"
        case redemptionTips = "redemption_tips"
        case riskNotes = "risk_notes"
        case lastReviewedAt = "last_reviewed_at"
    }

    var domainModel: ProgramGuide? {
        guard let guideStatus = ProgramGuide.Status(rawValue: status) else {
            return nil
        }

        return ProgramGuide(
            id: id,
            programID: programID,
            status: guideStatus,
            introText: introText,
            strategy: strategy,
            valueEstimateLabel: valueEstimateLabel,
            valueEstimateDetail: valueEstimateDetail,
            expirationSummary: expirationSummary,
            expirationDetail: expirationDetail,
            earningTips: earningTips,
            redemptionTips: redemptionTips,
            riskNotes: riskNotes,
            lastReviewedAt: lastReviewedAt
        )
    }
}

private struct CampaignDTO: Decodable {
    let id: UUID
    let title: String
    let summary: String
    let details: String
    let status: String
    let startDate: Date?
    let endDate: Date?
    let lastVerifiedAt: Date
    let primaryProgramID: UUID?
    let editorialScore: Double?
    let editorialSummary: String?
    let isFeatured: Bool
    let category: CampaignCategoryDTO?
    let requirements: [CampaignRequirementDTO]
    let sourceReferences: [CampaignSourceReferenceDTO]
    let editorialAssessments: [EditorialAssessmentDTO]
    let geoRestrictions: [GeoRestrictionDTO]
    let campaignPrograms: [CampaignProgramLinkDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case details
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case lastVerifiedAt = "last_verified_at"
        case primaryProgramID = "primary_program_id"
        case editorialScore = "editorial_score"
        case editorialSummary = "editorial_summary"
        case isFeatured = "is_featured"
        case category = "campaign_categories"
        case requirements = "campaign_requirements"
        case sourceReferences = "campaign_source_references"
        case editorialAssessments = "campaign_editorial_assessments"
        case geoRestrictions = "campaign_geo_restrictions"
        case campaignPrograms = "campaign_programs"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        details = try container.decode(String.self, forKey: .details)
        status = try container.decode(String.self, forKey: .status)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        lastVerifiedAt = try container.decode(Date.self, forKey: .lastVerifiedAt)
        primaryProgramID = try container.decodeIfPresent(UUID.self, forKey: .primaryProgramID)
        editorialScore = try container.decodeIfPresent(Double.self, forKey: .editorialScore)
        editorialSummary = try container.decodeIfPresent(String.self, forKey: .editorialSummary)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        category = try container.decodeIfPresent(CampaignCategoryDTO.self, forKey: .category)
        requirements = try container.decodeIfPresent([CampaignRequirementDTO].self, forKey: .requirements) ?? []
        sourceReferences = try container.decodeIfPresent([CampaignSourceReferenceDTO].self, forKey: .sourceReferences) ?? []
        editorialAssessments = try Self.decodeOneOrMany(EditorialAssessmentDTO.self, forKey: .editorialAssessments, from: container)
        geoRestrictions = try container.decodeIfPresent([GeoRestrictionDTO].self, forKey: .geoRestrictions) ?? []
        campaignPrograms = try container.decodeIfPresent([CampaignProgramLinkDTO].self, forKey: .campaignPrograms) ?? []
    }

    var domainModel: Campaign? {
        guard let campaignStatus = Campaign.Status(rawValue: status) else {
            return nil
        }

        let linkedProgramIDs = campaignPrograms.map(\.programID)
        let normalizedLinkedProgramIDs = linkedProgramIDs.isEmpty
            ? (primaryProgramID.map { [$0] } ?? [])
            : linkedProgramIDs

        return Campaign(
            id: id,
            title: title,
            summary: summary,
            details: details,
            status: campaignStatus,
            startDate: startDate,
            endDate: endDate,
            lastVerifiedAt: lastVerifiedAt,
            primaryProgramID: primaryProgramID,
            category: category?.domainModel,
            editorialScore: editorialScore.map { Int($0.rounded()) },
            editorialSummary: editorialSummary ?? editorialAssessments.first?.reasonWhyItMatters ?? "",
            isFeatured: isFeatured,
            requirements: requirements.map(\.domainModel).sorted { $0.sortOrder < $1.sortOrder },
            sources: sourceReferences.compactMap(\.domainModel),
            editorialAssessment: editorialAssessments.first?.domainModel,
            geoRestrictions: geoRestrictions.map(\.domainModel),
            linkedProgramIDs: normalizedLinkedProgramIDs
        )
    }

    private static func decodeOneOrMany<Value: Decodable>(
        _ type: Value.Type,
        forKey key: CodingKeys,
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [Value] {
        if let values = try? container.decode([Value].self, forKey: key) {
            return values
        }

        if let value = try? container.decode(Value.self, forKey: key) {
            return [value]
        }

        return []
    }
}

private struct CampaignCategoryDTO: Decodable {
    let id: UUID
    let slug: String
    let name: String

    var domainModel: CampaignCategory {
        CampaignCategory(id: id, slug: slug, name: name)
    }
}

private struct CampaignRequirementDTO: Decodable {
    let id: UUID
    let text: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case sortOrder = "sort_order"
    }

    var domainModel: CampaignRequirement {
        CampaignRequirement(id: id, text: text, sortOrder: sortOrder)
    }
}

private struct CampaignSourceReferenceDTO: Decodable {
    let id: UUID
    let url: String
    let title: String?
    let checkedAt: Date
    let evidenceNote: String?
    let source: CampaignSourceDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case title
        case checkedAt = "checked_at"
        case evidenceNote = "evidence_note"
        case source = "campaign_sources"
    }

    var domainModel: CampaignSourceReference? {
        guard let resolvedURL = URL(string: url) else { return nil }
        return CampaignSourceReference(
            id: id,
            sourceName: source?.name ?? "Kilde",
            url: resolvedURL,
            title: title ?? source?.name ?? "Kilde",
            checkedAt: checkedAt,
            evidenceNote: evidenceNote
        )
    }
}

private struct CampaignSourceDTO: Decodable {
    let name: String
}

private struct EditorialAssessmentDTO: Decodable {
    let score: Double?
    let reasonWhyItMatters: String
    let estimatedValueText: String?
    let difficultyLevel: String?
    let availabilityScope: String?
    let riskNote: String?

    enum CodingKeys: String, CodingKey {
        case score
        case reasonWhyItMatters = "reason_why_it_matters"
        case estimatedValueText = "estimated_value_text"
        case difficultyLevel = "difficulty_level"
        case availabilityScope = "availability_scope"
        case riskNote = "risk_note"
    }

    var domainModel: EditorialAssessment {
        EditorialAssessment(
            score: score.map { Int($0.rounded()) },
            reasonWhyItMatters: reasonWhyItMatters,
            estimatedValueText: estimatedValueText,
            difficultyLevel: difficultyLevel.flatMap(DifficultyLevel.init(rawValue:)),
            availabilityScope: availabilityScope.flatMap(AvailabilityScope.init(rawValue:)),
            riskNote: riskNote
        )
    }
}

private struct GeoRestrictionDTO: Decodable {
    let id: UUID
    let countryCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case countryCode = "country_code"
    }

    var domainModel: GeoRestriction {
        GeoRestriction(id: id, countryCode: countryCode)
    }
}

private struct CampaignProgramLinkDTO: Decodable {
    let programID: UUID

    enum CodingKeys: String, CodingKey {
        case programID = "program_id"
    }
}

private struct SupabaseAPIError: Decodable {
    let message: String
}

enum SupabaseRepositoryError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Supabase-konfigurasjonen er ugyldig."
        case .invalidResponse:
            return "Ugyldig svar fra Supabase."
        case let .httpError(statusCode, message):
            return "Supabase svarte med \(statusCode): \(message)"
        case let .decodingFailed(error):
            return "Kunne ikke tolke Supabase-data: \(error.localizedDescription)"
        }
    }
}
