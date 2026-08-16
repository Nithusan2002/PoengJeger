import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        @Bindable var environment = environment

        Form {
            Section("Varsler") {
                Label("Varsler kommer etter at push-flyten er koblet opp.", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)
            }

            ProgramSelectionControlsSection(
                programs: programs,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )

            ProgramSelectionSection(
                title: "Valgte programmer",
                programs: programs,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )

            Section("Programguider") {
                ForEach(programs) { program in
                    NavigationLink {
                        ProgramDetailView(
                            program: program,
                            guide: environment.programGuide(for: program),
                            campaigns: environment.campaigns
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(program.name)
                                .foregroundStyle(.primary)
                            Text("Strategi, feller og aktive kampanjer")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Åpne programguide for \(program.name)")
                }
            }

            if let dataSource = environment.dataSource {
                Section("Datakilde") {
                    Text(dataSource.label)
                }
            }

            #if DEBUG
            Section {
                NavigationLink("Admin-kø") {
                    AdminQueueView()
                }
            } header: {
                Text("Redaksjon")
            } footer: {
                Text("Denne skjermen er for intern review av ingestion-kandidater. Live admin krever egen admin-session.")
            }
            #endif
        }
        .navigationTitle("Innstillinger")
    }
}
