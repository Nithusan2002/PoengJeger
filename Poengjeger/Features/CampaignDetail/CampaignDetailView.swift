import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DetailIntro(
                    campaign: campaign,
                    primaryProgramName: primaryProgramName
                )

                if hasEditorialAssessment {
                    DetailSection(title: "Hvorfor interessant", systemImage: "chart.line.uptrend.xyaxis") {
                        VStack(alignment: .leading, spacing: 12) {
                            if !campaign.editorialSummary.isEmpty {
                                DetailTextBlock(text: campaign.editorialSummary, prominence: .lead)
                            }

                            if let assessment = campaign.editorialAssessment {
                                DetailTextBlock(text: assessment.reasonWhyItMatters)

                                if let estimatedValueText = assessment.estimatedValueText {
                                    DetailFactLine(title: "Estimert verdi", value: estimatedValueText)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 8) {
                                        editorialMetrics
                                    }
                                }
                            } else if let score = campaign.editorialScore {
                                DetailFactLine(title: "Redaksjonell vurdering", value: campaign.editorialTierLabel)
                                DetailFactLine(title: "Scoregrunnlag", value: "\(score)/100")
                            }
                        }
                    }
                }

                DetailSection(title: "Slik fungerer det", systemImage: "gift") {
                    DetailTextBlock(text: campaign.details)
                }

                if !campaign.requirements.isEmpty {
                    DetailSection(title: "Viktigste krav", systemImage: "checklist") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(campaign.sortedRequirements) { requirement in
                                DetailRequirementRow(text: requirement.text)
                            }
                        }
                    }
                }

                if hasLimitations {
                    DetailSection(title: "Begrensninger", systemImage: "exclamationmark.triangle") {
                        VStack(alignment: .leading, spacing: 12) {
                            if let riskNote = campaign.editorialAssessment?.riskNote {
                                DetailTextBlock(text: riskNote)
                            }

                            if !campaign.geoRestrictions.isEmpty {
                                DetailFactLine(
                                    title: "Geografi",
                                    value: campaign.geoRestrictions.map(\.countryCode).joined(separator: ", ")
                                )
                            }

                            if let endDate = campaign.endDate {
                                DetailFactLine(
                                    title: "Utløper",
                                    value: endDate.formatted(date: .long, time: .omitted)
                                )
                            }
                        }
                    }
                }

                DetailSection(title: "Fakta og kilde", systemImage: "link") {
                    VStack(alignment: .leading, spacing: 14) {
                        CampaignFactList(campaign: campaign)

                        if !campaign.sources.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(campaign.sources) { source in
                                    SourceLinkRow(source: source)
                                }
                            }
                        }
                    }
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            DetailTopBar(
                isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id),
                onBack: { dismiss() },
                onToggleFavorite: { toggleFavorite(in: &environment.userSession.favoriteCampaignIDs) }
            )
        }
    }

    private var primaryProgramName: String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return environment.programs.first(where: { $0.id == primaryProgramID })?.name
    }

    private var hasEditorialAssessment: Bool {
        campaign.editorialScore != nil || campaign.editorialAssessment != nil || !campaign.editorialSummary.isEmpty
    }

    private var hasLimitations: Bool {
        campaign.editorialAssessment?.riskNote != nil || !campaign.geoRestrictions.isEmpty || campaign.endDate != nil
    }

    @ViewBuilder
    private var editorialMetrics: some View {
        if let score = campaign.editorialScore {
            DetailFactLine(title: "Vurdering", value: campaign.editorialTierLabel)
            DetailFactLine(title: "Scoregrunnlag", value: "\(score)/100")
        }

        if let difficultyLevel = campaign.editorialAssessment?.difficultyLevel {
            DetailFactLine(title: "Friksjon", value: difficultyLevel.displayName)
        }

        if let availabilityScope = campaign.editorialAssessment?.availabilityScope {
            DetailFactLine(title: "Tilgjengelighet", value: availabilityScope.displayName)
        }
    }

    private func toggleFavorite(in favoriteIDs: inout Set<UUID>) {
        if favoriteIDs.contains(campaign.id) {
            favoriteIDs.remove(campaign.id)
        } else {
            favoriteIDs.insert(campaign.id)
        }
    }

}

private struct DetailTopBar: View {
    let isFavorite: Bool
    let onBack: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tilbake")

            Spacer(minLength: 8)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(isFavorite ? PoengjegerTheme.highlight : PoengjegerTheme.accent)
            .accessibilityLabel(isFavorite ? "Fjern favoritt" : "Lagre favoritt")
            .accessibilityValue(isFavorite ? "Lagret" : "Ikke lagret")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct DetailIntro: View {
    let campaign: Campaign
    let primaryProgramName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    if let primaryProgramName {
                        Text(primaryProgramName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PoengjegerTheme.accent)
                            .textCase(.uppercase)
                    }

                    Text(campaign.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            Text(campaign.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                DetailQuickFactCard(
                    title: "Verdi",
                    value: campaign.detailValueLabel,
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                HStack(spacing: 10) {
                    DetailQuickFactCard(
                        title: "Frist",
                        value: FeedDateHelper.expiryLabel(campaign.endDate).text,
                        systemImage: "calendar"
                    )

                    DetailQuickFactCard(
                        title: "Friksjon",
                        value: campaign.editorialAssessment?.difficultyLevel?.displayName ?? "Ukjent",
                        systemImage: "gauge.with.dots.needle.50percent"
                    )
                }
            }

            if let primarySource = campaign.sources.first {
                CampaignSourceCTA(source: primarySource)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct DetailQuickFactCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title.uppercased(), systemImage: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CampaignSourceCTA: View {
    let source: CampaignSourceReference

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link(destination: source.url) {
                Label("Åpne kampanjesiden", systemImage: "arrow.up.right.square")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(PoengjegerTheme.accent)
            .accessibilityLabel("Åpne kampanjesiden hos \(source.sourceName)")

            Text("Primærkilde: \(source.sourceName)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("Kampanjer er samlet fra offentlige kilder. Sjekk alltid vilkårene hos tilbyder.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 2)
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

private struct DetailFactLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DetailRequirementRow: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
    }
}

private struct CampaignFactList: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            facts
        }
    }

    @ViewBuilder
    private var facts: some View {
        if let categoryName = campaign.category?.name {
            FactRow(
                systemImage: "tag",
                title: "Kategori",
                value: categoryName
            )
        }

        FactRow(
            systemImage: "checkmark.seal",
            title: "Kontrollert",
            value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted)
        )

        if let firstSource = campaign.sources.first {
            FactRow(
                systemImage: "link",
                title: "Primærkilde",
                value: firstSource.sourceName
            )
        }

    }
}

private struct SourceLinkRow: View {
    let source: CampaignSourceReference

    var body: some View {
        Link(destination: source.url) {
            VStack(alignment: .leading, spacing: 5) {
                Text(source.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)

                Text(source.sourceName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(source.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Kontrollert \(source.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let evidenceNote = source.evidenceNote {
                    Text(evidenceNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FactRow: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
    }
}

private struct DetailTextBlock: View {
    enum Prominence {
        case body
        case lead
    }

    let text: String
    var prominence: Prominence = .body

    var body: some View {
        Text(text)
            .font(prominence == .lead ? .headline : .body)
            .foregroundStyle(prominence == .lead ? .primary : .secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private extension Campaign {
    var detailValueLabel: String {
        if let value = editorialAssessment?.estimatedValueText?.detailValueLabel {
            return value
        }

        if editorialScore != nil {
            return editorialTierLabel
        }

        return "Se vilkår"
    }
}

private extension String {
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

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
