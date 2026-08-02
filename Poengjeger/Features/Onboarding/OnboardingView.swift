import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        NavigationStack {
            List {
                Section {
                    Text("Velg ett eller flere bonusprogrammer du vil følge. Feed og varsler skal bare vise kampanjer som er relevante for disse valgene.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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

                Section("Bonusprogrammer") {
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

                                VStack(alignment: .leading, spacing: 4) {
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

                if let dataSource = environment.dataSource, dataSource.isFallback {
                    Section {
                        Text("Viser \(dataSource.label.lowercased()) til Supabase-konfigurasjon er på plass.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Dine programmer")
            .overlay {
                if case .loading = environment.loadState, environment.programs.isEmpty {
                    ProgressView()
                }
            }
            .refreshable {
                await environment.refresh()
            }
        }
    }

    private func toggleProgramSelection(_ programID: UUID, in selectedProgramIDs: inout Set<UUID>) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.mock())
}
