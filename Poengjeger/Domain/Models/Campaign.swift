import Foundation

struct Campaign: Identifiable, Hashable {
    enum Status: String, Codable, Hashable {
        case draft
        case review
        case published
        case expired
        case archived
    }

    let id: UUID
    let title: String
    let summary: String
    let details: String
    let status: Status
    let startDate: Date?
    let endDate: Date?
    let lastVerifiedAt: Date
    let primaryProgramID: UUID?
    let category: CampaignCategory?
    let editorialScore: Int?
    let editorialSummary: String
    let isFeatured: Bool
    let requirements: [CampaignRequirement]
    let sources: [CampaignSourceReference]
    let editorialAssessment: EditorialAssessment?
    let geoRestrictions: [GeoRestriction]
    let linkedProgramIDs: [UUID]

    var isActive: Bool {
        guard status == .published else { return false }

        let now = Date()
        if let startDate, startDate > now {
            return false
        }
        if let endDate, endDate < now {
            return false
        }
        return true
    }

    var displaySummary: String {
        editorialSummary.isEmpty ? summary : editorialSummary
    }

    var editorialTierLabel: String {
        guard let editorialScore else {
            return "Uten vurdering"
        }

        switch editorialScore {
        case 80...:
            return "Sterk mulighet"
        case 65...:
            return "Relevant"
        default:
            return "Nisjetilbud"
        }
    }

    var sortedRequirements: [CampaignRequirement] {
        requirements.sorted { $0.sortOrder < $1.sortOrder }
    }

    func matchesSelectedPrograms(_ selectedProgramIDs: Set<UUID>) -> Bool {
        !selectedProgramIDs.isDisjoint(with: linkedProgramIDs)
    }
}

struct CampaignCategory: Identifiable, Hashable {
    let id: UUID
    let slug: String
    let name: String
}

struct CampaignRequirement: Identifiable, Hashable {
    let id: UUID
    let text: String
    let sortOrder: Int
}

struct CampaignSourceReference: Identifiable, Hashable {
    let id: UUID
    let sourceName: String
    let url: URL
    let title: String
    let checkedAt: Date
    let evidenceNote: String?
}

struct EditorialAssessment: Hashable {
    let score: Int?
    let reasonWhyItMatters: String
    let estimatedValueText: String?
    let difficultyLevel: DifficultyLevel?
    let availabilityScope: AvailabilityScope?
    let riskNote: String?
}

enum DifficultyLevel: String, Hashable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:
            return "Lav"
        case .medium:
            return "Middels"
        case .high:
            return "Høy"
        }
    }
}

enum AvailabilityScope: String, Hashable {
    case narrow
    case regional
    case broad

    var displayName: String {
        switch self {
        case .narrow:
            return "Smal"
        case .regional:
            return "Regional"
        case .broad:
            return "Bred"
        }
    }
}

struct GeoRestriction: Identifiable, Hashable {
    let id: UUID
    let countryCode: String
}
