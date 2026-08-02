import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if let programName = primaryProgramName {
                        Text(programName)
                            .font(.caption)
                            .foregroundStyle(PoengjegerTheme.accent)
                            .textCase(.uppercase)
                    }

                    Text(campaign.summary)
                        .font(.headline)

                    Text(campaign.details)
                        .font(.body)

                    CampaignFactGrid(campaign: campaign)
                }
                .padding(.vertical, 4)
            }

            Section("Fakta") {
                if let categoryName = campaign.category?.name {
                    LabeledContent("Kategori", value: categoryName)
                }

                LabeledContent("Sist kontrollert") {
                    Text(campaign.lastVerifiedAt.formatted(date: .long, time: .shortened))
                        .multilineTextAlignment(.trailing)
                }

                if !campaign.geoRestrictions.isEmpty {
                    LabeledContent("Geografi") {
                        Text(campaign.geoRestrictions.map(\.countryCode).joined(separator: ", "))
                    }
                }

                if !campaign.sources.isEmpty {
                    LabeledContent("Kildegrunnlag", value: "\(campaign.sources.count) kilde\(campaign.sources.count == 1 ? "" : "r")")
                }
            }

            if campaign.editorialScore != nil || campaign.editorialAssessment != nil || !campaign.editorialSummary.isEmpty {
                Section("Redaksjonell vurdering") {
                    if let score = campaign.editorialScore {
                        LabeledContent("Poengjeger-score", value: "\(score)/100")
                    }

                    if !campaign.editorialSummary.isEmpty {
                        DetailTextBlock(
                            title: "Kort vurdering",
                            text: campaign.editorialSummary
                        )
                    }

                    if let assessment = campaign.editorialAssessment {
                        DetailTextBlock(
                            title: "Hvorfor interessant",
                            text: assessment.reasonWhyItMatters
                        )

                        if let estimatedValueText = assessment.estimatedValueText {
                            DetailTextBlock(
                                title: "Estimert verdi",
                                text: estimatedValueText
                            )
                        }

                        if let difficultyLevel = assessment.difficultyLevel {
                            LabeledContent("Friksjon", value: difficultyLabel(for: difficultyLevel))
                        }

                        if let availabilityScope = assessment.availabilityScope {
                            LabeledContent("Tilgjengelighet", value: availabilityLabel(for: availabilityScope))
                        }

                        if let riskNote = assessment.riskNote {
                            DetailTextBlock(
                                title: "Forbehold",
                                text: riskNote
                            )
                        }
                    }
                }
            }

            if !campaign.requirements.isEmpty {
                Section("Krav og vilkår") {
                    ForEach(campaign.requirements.sorted(by: { $0.sortOrder < $1.sortOrder })) { requirement in
                        Label(requirement.text, systemImage: "checkmark.circle")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }

            if !campaign.sources.isEmpty {
                Section("Kilder") {
                    ForEach(campaign.sources) { source in
                        Link(destination: source.url) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.title)
                                    .foregroundStyle(PoengjegerTheme.accent)
                                Text(source.url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text(source.sourceName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("Kontrollert \(source.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if let evidenceNote = source.evidenceNote {
                                    Text(evidenceNote)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Handlinger") {
                Button {
                    toggleFavorite(in: &environment.userSession.favoriteCampaignIDs)
                } label: {
                    Label(
                        environment.userSession.favoriteCampaignIDs.contains(campaign.id) ? "Fjern favoritt" : "Lagre favoritt",
                        systemImage: environment.userSession.favoriteCampaignIDs.contains(campaign.id) ? "star.slash" : "star"
                    )
                }
            }
        }
        .navigationTitle(campaign.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var primaryProgramName: String? {
        guard let primaryProgramID = campaign.primaryProgramID else {
            return nil
        }

        return environment.programs.first(where: { $0.id == primaryProgramID })?.name
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

private struct CampaignFactGrid: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let endDate = campaign.endDate {
                FactRow(
                    systemImage: "calendar",
                    title: "Utløper",
                    value: endDate.formatted(date: .long, time: .omitted)
                )
            }

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
                    value: "Fremhevet kampanje"
                )
            }
        }
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
                    .font(.subheadline)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(PoengjegerTheme.accent)
        }
        .labelStyle(.titleAndIcon)
    }
}

private struct DetailTextBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.mock())
    }
}
