import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                DetailHero(
                    campaign: campaign,
                    primaryProgramName: primaryProgramName,
                    isFavorite: environment.userSession.favoriteCampaignIDs.contains(campaign.id)
                )

                DetailCard(title: "Hva får du?", systemImage: "gift") {
                    DetailTextBlock(text: campaign.summary, prominence: .lead)
                    DetailTextBlock(text: campaign.details)
                }

                if !campaign.requirements.isEmpty {
                    DetailCard(title: "Viktigste krav", systemImage: "checklist") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(campaign.requirements.sorted(by: { $0.sortOrder < $1.sortOrder })) { requirement in
                                DetailRequirementRow(text: requirement.text)
                            }
                        }
                    }
                }

                if hasEditorialAssessment {
                    DetailCard(title: "Hvorfor interessant", systemImage: "chart.line.uptrend.xyaxis") {
                        VStack(alignment: .leading, spacing: 12) {
                            if !campaign.editorialSummary.isEmpty {
                                DetailTextBlock(text: campaign.editorialSummary, prominence: .lead)
                            }

                            if let assessment = campaign.editorialAssessment {
                                DetailTextBlock(text: assessment.reasonWhyItMatters)

                                if let estimatedValueText = assessment.estimatedValueText {
                                    DetailMetricRow(title: "Estimert verdi", value: estimatedValueText)
                                }

                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 10) {
                                        editorialMetrics
                                    }

                                    VStack(alignment: .leading, spacing: 10) {
                                        editorialMetrics
                                    }
                                }
                            } else if let score = campaign.editorialScore {
                                DetailMetricRow(title: "Poengjeger-score", value: "\(score)/100")
                            }
                        }
                    }
                }

                if hasLimitations {
                    DetailCard(title: "Begrensninger", systemImage: "exclamationmark.triangle") {
                        VStack(alignment: .leading, spacing: 12) {
                            if let riskNote = campaign.editorialAssessment?.riskNote {
                                DetailTextBlock(text: riskNote)
                            }

                            if !campaign.geoRestrictions.isEmpty {
                                DetailMetricRow(
                                    title: "Geografi",
                                    value: campaign.geoRestrictions.map(\.countryCode).joined(separator: ", ")
                                )
                            }

                            if let endDate = campaign.endDate {
                                DetailMetricRow(
                                    title: "Utløper",
                                    value: endDate.formatted(date: .long, time: .omitted)
                                )
                            }
                        }
                    }
                }

                DetailCard(title: "Fakta og kilde", systemImage: "link") {
                    VStack(alignment: .leading, spacing: 14) {
                        CampaignFactGrid(campaign: campaign)

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

                Button {
                    toggleFavorite(in: &environment.userSession.favoriteCampaignIDs)
                } label: {
                    Label(
                        environment.userSession.favoriteCampaignIDs.contains(campaign.id) ? "Fjern favoritt" : "Lagre favoritt",
                        systemImage: environment.userSession.favoriteCampaignIDs.contains(campaign.id) ? "star.slash" : "star"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PoengjegerTheme.accent)
                .controlSize(.large)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle(campaign.title)
        .navigationBarTitleDisplayMode(.inline)
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
            DetailMetricRow(title: "Score", value: "\(score)/100")
        }

        if let difficultyLevel = campaign.editorialAssessment?.difficultyLevel {
            DetailMetricRow(title: "Friksjon", value: difficultyLabel(for: difficultyLevel))
        }

        if let availabilityScope = campaign.editorialAssessment?.availabilityScope {
            DetailMetricRow(title: "Tilgjengelighet", value: availabilityLabel(for: availabilityScope))
        }
    }

    private func toggleFavorite(in favoriteIDs: inout Set<UUID>) {
        if favoriteIDs.contains(campaign.id) {
            favoriteIDs.remove(campaign.id)
        } else {
            favoriteIDs.insert(campaign.id)
        }
    }

    private func difficultyLabel(for difficultyLevel: DifficultyLevel) -> String {
        switch difficultyLevel {
        case .low:
            return "Lav"
        case .medium:
            return "Middels"
        case .high:
            return "Høy"
        }
    }

    private func availabilityLabel(for availabilityScope: AvailabilityScope) -> String {
        switch availabilityScope {
        case .narrow:
            return "Smal"
        case .regional:
            return "Regional"
        case .broad:
            return "Bred"
        }
    }
}

private struct DetailHero: View {
    let campaign: Campaign
    let primaryProgramName: String?
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.highlight)
                        .accessibilityLabel("Lagret som favoritt")
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    heroFacts
                }

                VStack(alignment: .leading, spacing: 10) {
                    heroFacts
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var heroFacts: some View {
        if let score = campaign.editorialScore {
            DetailMetricRow(title: "Score", value: "\(score)/100")
        }

        if let endDate = campaign.endDate {
            DetailMetricRow(
                title: "Utløper",
                value: endDate.formatted(date: .abbreviated, time: .omitted)
            )
        }

        DetailMetricRow(
            title: "Kontrollert",
            value: campaign.lastVerifiedAt.formatted(date: .abbreviated, time: .omitted)
        )
    }
}

private struct DetailCard<Content: View>: View {
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

private struct DetailMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(PoengjegerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private struct CampaignFactGrid: View {
    let campaign: Campaign

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                facts
            }

            VStack(alignment: .leading, spacing: 10) {
                facts
            }
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

        if campaign.isFeatured {
            FactRow(
                systemImage: "sparkles",
                title: "Feed-status",
                value: "Fremhevet"
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

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
