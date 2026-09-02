import Foundation

struct ProgramGuide: Identifiable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case draft
        case published
        case archived
    }

    let id: UUID
    let programID: UUID
    let status: Status
    let title: String?
    let introText: String?
    let bodyMarkdown: String?
    let strategy: String
    let valueEstimateLabel: String?
    let valueEstimateDetail: String?
    let expirationSummary: String?
    let expirationDetail: String?
    let guideKicker: String?
    let readingTimeLabel: String?
    let strategySectionTitle: String?
    let decisionSectionTitle: String?
    let earningDecisionLabel: String?
    let redemptionDecisionLabel: String?
    let riskDecisionLabel: String?
    let earningSectionTitle: String?
    let earningSectionIntro: String?
    let redemptionSectionTitle: String?
    let redemptionSectionIntro: String?
    let riskSectionTitle: String?
    let riskSectionIntro: String?
    let campaignsSectionTitle: String?
    let campaignsSectionIntro: String?
    let earningTips: [String]
    let redemptionTips: [String]
    let riskNotes: [String]
    let lastReviewedAt: Date?

    init(
        id: UUID,
        programID: UUID,
        status: Status,
        title: String? = nil,
        introText: String?,
        bodyMarkdown: String? = nil,
        strategy: String,
        valueEstimateLabel: String?,
        valueEstimateDetail: String?,
        expirationSummary: String?,
        expirationDetail: String?,
        guideKicker: String? = nil,
        readingTimeLabel: String? = nil,
        strategySectionTitle: String? = nil,
        decisionSectionTitle: String? = nil,
        earningDecisionLabel: String? = nil,
        redemptionDecisionLabel: String? = nil,
        riskDecisionLabel: String? = nil,
        earningSectionTitle: String? = nil,
        earningSectionIntro: String? = nil,
        redemptionSectionTitle: String? = nil,
        redemptionSectionIntro: String? = nil,
        riskSectionTitle: String? = nil,
        riskSectionIntro: String? = nil,
        campaignsSectionTitle: String? = nil,
        campaignsSectionIntro: String? = nil,
        earningTips: [String],
        redemptionTips: [String],
        riskNotes: [String],
        lastReviewedAt: Date?
    ) {
        self.id = id
        self.programID = programID
        self.status = status
        self.title = title
        self.introText = introText
        self.bodyMarkdown = bodyMarkdown
        self.strategy = strategy
        self.valueEstimateLabel = valueEstimateLabel
        self.valueEstimateDetail = valueEstimateDetail
        self.expirationSummary = expirationSummary
        self.expirationDetail = expirationDetail
        self.guideKicker = guideKicker
        self.readingTimeLabel = readingTimeLabel
        self.strategySectionTitle = strategySectionTitle
        self.decisionSectionTitle = decisionSectionTitle
        self.earningDecisionLabel = earningDecisionLabel
        self.redemptionDecisionLabel = redemptionDecisionLabel
        self.riskDecisionLabel = riskDecisionLabel
        self.earningSectionTitle = earningSectionTitle
        self.earningSectionIntro = earningSectionIntro
        self.redemptionSectionTitle = redemptionSectionTitle
        self.redemptionSectionIntro = redemptionSectionIntro
        self.riskSectionTitle = riskSectionTitle
        self.riskSectionIntro = riskSectionIntro
        self.campaignsSectionTitle = campaignsSectionTitle
        self.campaignsSectionIntro = campaignsSectionIntro
        self.earningTips = earningTips
        self.redemptionTips = redemptionTips
        self.riskNotes = riskNotes
        self.lastReviewedAt = lastReviewedAt
    }
}
