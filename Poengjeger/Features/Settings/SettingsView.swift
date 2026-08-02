import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        Form {
            Section("Varsler") {
                Toggle("Aktiver varsler", isOn: $environment.userSession.notificationsEnabled)
            }

            Section {
                HStack {
                    Text("Valgt nå")
                    Spacer()
                    Text("\(environment.userSession.selectedProgramIDs.count) av \(environment.programs.count)")
                        .foregroundStyle(.secondary)
                }

                Button("Velg alle") {
                    environment.userSession.selectedProgramIDs = Set(environment.programs.map(\.id))
                }
                .disabled(environment.programs.isEmpty)

                Button("Tøm valg", role: .destructive) {
                    environment.userSession.selectedProgramIDs.removeAll()
                }
                .disabled(environment.userSession.selectedProgramIDs.isEmpty)
            }

            Section("Valgte programmer") {
                ForEach(environment.programs) { program in
                    Button {
                        toggleProgramSelection(program.id, in: &environment.userSession.selectedProgramIDs)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: environment.userSession.selectedProgramIDs.contains(program.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(
                                    environment.userSession.selectedProgramIDs.contains(program.id)
                                    ? AnyShapeStyle(PoengjegerTheme.accent)
                                    : AnyShapeStyle(.tertiary)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(program.name)
                                    .foregroundStyle(.primary)
                                Text(program.issuerName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let dataSource = environment.dataSource {
                Section("Datakilde") {
                    Text(dataSource.label)
                }
            }
        }
        .navigationTitle("Innstillinger")
    }

    private func toggleProgramSelection(_ programID: UUID, in selectedProgramIDs: inout Set<UUID>) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}
