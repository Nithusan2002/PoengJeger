import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppEnvironment.self) private var environment

    let campaign: Campaign

    var body: some View {
        @Bindable var environment = environment

        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(campaign.summary)
                        .font(.headline)

                    Text(campaign.details)
                        .font(.body)

                    if let summary = campaign.editorialAssessment?.reasonWhyItMatters {
                        LabeledContent("Hvorfor interessant") {
                            Text(summary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if !campaign.requirements.isEmpty {
                Section("Krav") {
                    ForEach(campaign.requirements.sorted(by: { $0.sortOrder < $1.sortOrder })) { requirement in
                        Text(requirement.text)
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
                                Text(source.sourceName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("Kontrollert \(source.checkedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
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

    private func toggleFavorite(in favoriteIDs: inout Set<UUID>) {
        if favoriteIDs.contains(campaign.id) {
            favoriteIDs.remove(campaign.id)
        } else {
            favoriteIDs.insert(campaign.id)
        }
    }
}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: SampleData.campaigns[0])
            .environment(AppEnvironment.bootstrap())
    }
}
