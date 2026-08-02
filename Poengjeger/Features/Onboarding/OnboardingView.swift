import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        NavigationStack {
            List {
                Section {
                    Text("Velg bonusprogrammene du vil følge. Feed og varsler skal bare vise kampanjer som er relevante for disse valgene.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Bonusprogrammer") {
                    ForEach(environment.programs) { program in
                        Toggle(
                            isOn: Binding(
                                get: { environment.userSession.selectedProgramIDs.contains(program.id) },
                                set: { isSelected in
                                    if isSelected {
                                        environment.userSession.selectedProgramIDs.insert(program.id)
                                    } else {
                                        environment.userSession.selectedProgramIDs.remove(program.id)
                                    }
                                }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(program.name)
                                Text(program.issuerName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.bootstrap())
}
