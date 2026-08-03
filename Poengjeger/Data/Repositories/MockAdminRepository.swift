import Foundation

actor MockAdminRepository: AdminRepository {
    private var candidates: [IngestionCandidate]

    init(candidates: [IngestionCandidate] = AdminSampleData.candidates) {
        self.candidates = candidates.sorted { $0.detectedAt > $1.detectedAt }
    }

    func fetchQueue() async throws -> AdminQueueData {
        AdminQueueData(
            candidates: candidates.sorted { $0.detectedAt > $1.detectedAt },
            isPreview: true,
            label: "Preview-kø"
        )
    }

    func setStatus(
        candidateID: UUID,
        status: IngestionCandidate.Status,
        note: String?
    ) async throws -> IngestionCandidate {
        guard let index = candidates.firstIndex(where: { $0.id == candidateID }) else {
            throw AdminRepositoryError.notFound
        }

        let current = candidates[index]
        let updated = IngestionCandidate(
            id: current.id,
            status: status,
            detectedAt: current.detectedAt,
            sourceURL: current.sourceURL,
            title: current.title,
            summary: current.summary,
            reviewNote: note ?? current.reviewNote,
            promotedCampaignID: status == .promoted ? (current.promotedCampaignID ?? UUID()) : current.promotedCampaignID,
            sourceName: current.sourceName,
            ingestKind: current.ingestKind,
            suggestedProgramName: current.suggestedProgramName,
            suggestedCategoryName: current.suggestedCategoryName
        )

        candidates[index] = updated
        return updated
    }

    func promote(candidateID: UUID, note: String?) async throws -> IngestionCandidate {
        try await setStatus(
            candidateID: candidateID,
            status: .promoted,
            note: note ?? "Promotert til draft i preview-flyten."
        )
    }
}

enum AdminSampleData {
    static let candidates: [IngestionCandidate] = [
        IngestionCandidate(
            id: UUID(uuidString: "5B10B50E-4B4E-41BC-B05E-EBDE5E0F0501")!,
            status: .new,
            detectedAt: Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now,
            sourceURL: URL(string: "https://www.sas.no/eurobonus/tilbud/ekstrapoeng-flypremium-august-2026")!,
            title: "Fly Premium: ekstra tilgjengelighet i august 2026",
            summary: "Mulig ny SAS-kampanje med ekstra tilgjengelighet for Fly Premium-kunder.",
            reviewNote: nil,
            promotedCampaignID: nil,
            sourceName: "SAS",
            ingestKind: "html_page",
            suggestedProgramName: "SAS EuroBonus",
            suggestedCategoryName: "Netthandel"
        ),
        IngestionCandidate(
            id: UUID(uuidString: "7C21C60F-5C5F-42CD-C16F-FCEF6F1F0602")!,
            status: .needsReview,
            detectedAt: Calendar.current.date(byAdding: .hour, value: -6, to: .now) ?? .now,
            sourceURL: URL(string: "https://www.trumf.no/kampanje/partnerbonus-august")!,
            title: "Partnerbonus hos ny nettbutikk via Trumf",
            summary: "Mulig partnerkampanje som trenger kontroll av geografi og vilkår.",
            reviewNote: "Mangler tydelig sluttdato og bør kontrolleres mot vilkårssiden.",
            promotedCampaignID: nil,
            sourceName: "Trumf",
            ingestKind: "html_page",
            suggestedProgramName: "Trumf",
            suggestedCategoryName: "Netthandel"
        ),
        IngestionCandidate(
            id: UUID(uuidString: "8D32D710-6D60-43DE-D27F-0D0F70200703")!,
            status: .approved,
            detectedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            sourceURL: URL(string: "https://www.norwegian.com/no/reward/partnere/hotell/")!,
            title: "Hotellpartner med begrenset CashPoints-boost",
            summary: "Ser relevant ut for Norwegian Reward, klar for draft-promotering.",
            reviewNote: "Kildegrunnlaget ser greit ut, men redaksjonell vurdering mangler.",
            promotedCampaignID: nil,
            sourceName: "Norwegian Reward",
            ingestKind: "html_page",
            suggestedProgramName: "Norwegian Reward",
            suggestedCategoryName: "Hotell"
        )
    ]
}

enum AdminRepositoryError: LocalizedError {
    case unavailable(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case let .unavailable(message):
            return message
        case .notFound:
            return "Fant ikke valgt kandidat i admin-køen."
        }
    }
}
