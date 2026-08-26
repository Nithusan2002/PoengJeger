import Foundation

extension Campaign {
    var detailValueLabel: String {
        if let value = editorialAssessment?.estimatedValueText?.detailValueLabel {
            return value
        }

        if editorialScore != nil {
            return "Varierer"
        }

        return "Se vilkår"
    }

    var requirementSignal: String {
        let requirementsText = sortedRequirements
            .map(\.text)
            .joined(separator: " ")
            .lowercased()

        if requirementsText.contains("kort") && requirementsText.contains("bruk") {
            return "Krever kortbruk"
        }

        if requirementsText.contains("søk om kort") || category?.slug == "kredittkort" {
            return "Krever nytt kort"
        }

        if requirementsText.contains("aktiver") {
            return "Må aktiveres"
        }

        if requirementsText.contains("ny ") || requirementsText.contains("nye ") {
            return "Kun nye kunder"
        }

        return editorialAssessment?.difficultyLevel?.displayName ?? "Sjekk vilkårene"
    }

    var suitabilityFitText: String {
        if let bestFor = editorialAssessment?.bestFor?.trimmingCharacters(in: .whitespacesAndNewlines),
           !bestFor.isEmpty {
            return bestFor
        }

        switch category?.slug {
        case "kredittkort":
            return "Deg som allerede vurderer kortet."
        case "dagligvare":
            return "Deg som uansett skal handle hos butikkene."
        default:
            if let reason = editorialAssessment?.reasonWhyItMatters.firstSentence {
                return reason
            }

            return "Deg som uansett skulle bruke leverandøren."
        }
    }

    var suitabilityCaveatText: String? {
        if let notFor = editorialAssessment?.notFor?.trimmingCharacters(in: .whitespacesAndNewlines),
           !notFor.isEmpty {
            return notFor
        }

        if category?.slug == "kredittkort" {
            return "Deg som vil unngå kredittsjekk eller faste gebyrer."
        }

        return editorialAssessment?.riskNote?.firstSentence
    }

    var decisionConclusion: String {
        if let decisionSummary = editorialAssessment?.decisionSummary?.trimmingCharacters(in: .whitespacesAndNewlines),
           !decisionSummary.isEmpty {
            return decisionSummary
        }

        if !editorialSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return editorialSummary
        }

        if let reason = editorialAssessment?.reasonWhyItMatters,
           !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return reason
        }

        return summary
    }

    var decisionNextStep: String? {
        if let firstRequirement = sortedRequirements.first?.text {
            return firstRequirement
        }

        let normalizedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedDetails.isEmpty else { return nil }

        let firstSentence = normalizedDetails.split(separator: ".").first.map(String.init) ?? normalizedDetails
        return firstSentence.count <= 120 ? firstSentence : nil
    }
}

extension GeoRestriction {
    var displayName: String {
        switch countryCode.uppercased() {
        case "NO":
            return "Norge"
        default:
            return countryCode.uppercased()
        }
    }
}

extension String {
    var firstSentence: String? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let sentence = normalized.split(separator: ".").first.map(String.init) ?? normalized
        return sentence.isEmpty ? nil : sentence + (normalized.contains(".") ? "." : "")
    }

    var detailValueLabel: String? {
        let normalized = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let patterns = [
            #"\d[\d\s]*(?:kr|kroner)(?:\s+i\s+[A-Za-zÆØÅæøå-]+-bonus)?"#,
            #"\d[\d\s]*(?:EuroBonus-poeng|CashPoints|poeng)"#,
            #"\d+\s*%\s+[A-Za-zÆØÅæøå-]+-bonus"#,
            #"\d+\s*%\s+bonus"#,
            #"~?\d+(?:,\d+)?\s*cent/poeng"#
        ]

        for pattern in patterns {
            if let match = normalized.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return String(normalized[match]).replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
            }
        }

        let firstSentence = normalized.split(separator: ".").first.map(String.init) ?? normalized
        return firstSentence.count <= 38 ? firstSentence : nil
    }
}
