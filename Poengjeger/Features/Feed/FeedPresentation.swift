import SwiftUI

enum FeedSort: String, CaseIterable, Identifiable {
    case expiringFirst
    case newest
    case alphabetic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expiringFirst:
            return "Utløper først"
        case .newest:
            return "Nyeste"
        case .alphabetic:
            return "A-Å"
        }
    }
}

struct ExpiryDisplay: Equatable {
    let text: String
    let urgent: Bool
}

enum FeedDateHelper {
    static func daysUntil(_ date: Date?, referenceDate: Date = Date()) -> Int? {
        guard let date else { return nil }
        let startOfReferenceDate = Calendar.current.startOfDay(for: referenceDate)
        let startOfDate = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: startOfReferenceDate, to: startOfDate).day
    }

    static func expiryLabel(_ date: Date?, referenceDate: Date = Date()) -> ExpiryDisplay {
        guard let days = daysUntil(date, referenceDate: referenceDate) else {
            return ExpiryDisplay(text: "Løpende", urgent: false)
        }

        switch days {
        case ..<0:
            return ExpiryDisplay(text: "Utløpt", urgent: true)
        case 0:
            return ExpiryDisplay(text: "Siste dag", urgent: true)
        case 1:
            return ExpiryDisplay(text: "1 dag igjen", urgent: true)
        case 2...3:
            return ExpiryDisplay(text: "\(days) dager igjen", urgent: true)
        default:
            return ExpiryDisplay(text: "\(days) dager igjen", urgent: false)
        }
    }
}

struct ScannableFeedUseCase {
    func makeFeed(
        campaigns: [Campaign],
        selectedProgramIDs: Set<UUID>,
        showsAllPrograms: Bool,
        selectedCategoryID: UUID?,
        searchText: String,
        sort: FeedSort,
        referenceDate: Date = Date()
    ) -> [Campaign] {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return campaigns
            .filter { campaign in
                guard campaign.status == .published else { return false }
                if let startDate = campaign.startDate, startDate > referenceDate {
                    return false
                }
                if let days = FeedDateHelper.daysUntil(campaign.endDate, referenceDate: referenceDate), days < 0 {
                    return false
                }
                return true
            }
            .filter { campaign in
                showsAllPrograms || selectedProgramIDs.isEmpty || campaign.matchesSelectedPrograms(selectedProgramIDs)
            }
            .filter { campaign in
                selectedCategoryID == nil || campaign.category?.id == selectedCategoryID
            }
            .filter { campaign in
                guard !normalizedSearchText.isEmpty else { return true }
                let searchableText = [
                    campaign.title,
                    campaign.summary,
                    campaign.editorialSummary,
                    campaign.editorialAssessment?.decisionSummary,
                    campaign.editorialAssessment?.bestFor,
                    campaign.editorialAssessment?.notFor,
                    campaign.editorialAssessment?.reasonWhyItMatters,
                    campaign.editorialAssessment?.estimatedValueText
                ]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .lowercased()
                return searchableText.contains(normalizedSearchText)
            }
            .sorted { lhs, rhs in
                switch sort {
                case .expiringFirst:
                    return compareByExpiry(lhs, rhs, referenceDate: referenceDate)
                case .newest:
                    return (lhs.startDate ?? .distantPast) > (rhs.startDate ?? .distantPast)
                case .alphabetic:
                    return lhs.title.compare(rhs.title, locale: Locale(identifier: "nb")) == .orderedAscending
                }
            }
    }

    private func compareByExpiry(_ lhs: Campaign, _ rhs: Campaign, referenceDate: Date) -> Bool {
        switch (
            FeedDateHelper.daysUntil(lhs.endDate, referenceDate: referenceDate),
            FeedDateHelper.daysUntil(rhs.endDate, referenceDate: referenceDate)
        ) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
            return (lhs.editorialScore ?? 0) > (rhs.editorialScore ?? 0)
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return (lhs.editorialScore ?? 0) > (rhs.editorialScore ?? 0)
        }
    }
}

extension Campaign {
    var isFeedUrgent: Bool {
        guard let days = FeedDateHelper.daysUntil(endDate) else { return false }
        return days >= 0 && days <= 3
    }

    var isFeedHighValue: Bool {
        if editorialAssessment?.decisionLabel == .worthChecking {
            return true
        }

        return (editorialScore ?? 0) >= 80
    }

    var feedHeadline: String {
        if let value = editorialAssessment?.estimatedValueText?.feedValueLabel {
            return value
        }

        return title
    }

    var feedReason: String {
        if let decisionSummary = editorialAssessment?.decisionSummary?.trimmingCharacters(in: .whitespacesAndNewlines),
           !decisionSummary.isEmpty {
            return decisionSummary
        }

        if let reason = editorialAssessment?.reasonWhyItMatters, !reason.isEmpty {
            return reason
        }

        return displaySummary
    }

    var feedDecisionLabel: String? {
        if let label = editorialAssessment?.decisionLabel?.displayName {
            return label
        }

        return editorialScore == nil ? nil : editorialTierLabel
    }
}

extension String {
    var feedValueLabel: String? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let patterns = [
            #"\d[\d\s]*(?:kr|kroner)(?:\s+i\s+[A-Za-zÆØÅæøå-]+-bonus)?"#,
            #"\d[\d\s]*(?:EuroBonus-poeng|CashPoints|poeng)"#,
            #"\d+\s*%\s+[A-Za-zÆØÅæøå-]+-bonus"#,
            #"\d+\s*%\s+bonus"#,
            #"\d+\s+dager\s+gratis"#
        ]

        for pattern in patterns {
            if let match = normalized.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(normalized[match]).normalizedFeedValueLabel
            }
        }

        let firstSentence = normalized.split(separator: ".").first.map(String.init) ?? normalized
        if firstSentence.count <= 34 {
            return firstSentence
        }

        return nil
    }

    private var normalizedFeedValueLabel: String {
        replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
    }
}

extension BonusProgram {
    var shortDisplayName: String {
        switch slug {
        case "sas-eurobonus":
            return "SAS"
        case "norwegian-reward":
            return "Norwegian"
        default:
            return name
        }
    }

    var feedColor: Color {
        switch slug {
        case "sas-eurobonus":
            return Color(red: 0.08, green: 0.28, blue: 0.62)
        case "trumf":
            return Color(red: 0.10, green: 0.48, blue: 0.28)
        case "spenn":
            return Color(red: 0.62, green: 0.30, blue: 0.76)
        default:
            return PoengjegerTheme.accent
        }
    }
}
