import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        Form {
            Section("Varsler") {
                Label("Varsler kommer etter at push-flyten er koblet opp.", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)
            }

            ProgramSelectionControlsSection(
                programs: environment.programs,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )

            ProgramSelectionSection(
                title: "Valgte programmer",
                programs: environment.programs,
                selectedProgramIDs: $environment.userSession.selectedProgramIDs
            )

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
