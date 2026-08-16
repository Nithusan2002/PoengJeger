import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var draftSelectedProgramIDs: Set<UUID> = []

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        @Bindable var environment = environment

        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    OnboardingHeader(
                        selectedCount: draftSelectedProgramIDs.count,
                        programCount: programs.count
                    )

                    OnboardingProgramList(
                        programs: programs,
                        selectedProgramIDs: $draftSelectedProgramIDs
                    )

                    if let dataSource = environment.dataSource, dataSource.isFallback {
                        FeedStatusBanner(text: "Viser \(dataSource.label.lowercased()) til Supabase-konfigurasjon er på plass.")
                    }

                    OnboardingContinueButton(
                        isEnabled: !draftSelectedProgramIDs.isEmpty
                    ) {
                        environment.userSession.selectedProgramIDs = draftSelectedProgramIDs
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(PoengjegerTheme.background)
            .navigationTitle("")
            .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
            .overlay {
                if case .loading = environment.loadState, environment.programs.isEmpty {
                    ProgressView()
                }
            }
            .refreshable {
                await environment.refresh()
            }
            .onAppear {
                let firstPhaseProgramIDs = Set(programs.map(\.id))
                let selectedFirstPhaseProgramIDs = environment.userSession.selectedProgramIDs.intersection(firstPhaseProgramIDs)
                draftSelectedProgramIDs = selectedFirstPhaseProgramIDs.isEmpty ? firstPhaseProgramIDs : selectedFirstPhaseProgramIDs
            }
        }
    }
}

private struct OnboardingHeader: View {
    let selectedCount: Int
    let programCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hva samler du på?")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Velg programmene du bruker, så viser vi kampanjer og tips som passer deg.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Label("\(selectedCount) av \(programCount) valgt", systemImage: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.accent)
                .accessibilityLabel("\(selectedCount) av \(programCount) programmer valgt")
        }
        .padding(.top, 72)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingProgramList: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(programs) { program in
                ProgramSelectionRow(
                    program: program,
                    isSelected: selectedProgramIDs.contains(program.id)
                ) {
                    toggleProgramSelection(program.id)
                }

                if program.id != programs.last?.id {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }

    private func toggleProgramSelection(_ programID: UUID) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}

private struct OnboardingContinueButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Vis kampanjer", systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(PoengjegerTheme.accent)
        .disabled(!isEnabled)
        .accessibilityHint(isEnabled ? "Åpner den personlige kampanjefeeden." : "Velg minst ett bonusprogram først.")
    }
}

struct ProgramSelectionControlsSection: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    var body: some View {
        Section {
            HStack {
                Text("Valgt nå")
                Spacer()
                Text("\(selectedProgramCount) av \(programs.count)")
                    .foregroundStyle(.secondary)
            }

            Button("Velg alle") {
                selectedProgramIDs = Set(programs.map(\.id))
            }
            .disabled(programs.isEmpty)

            Button("Tøm valg", role: .destructive) {
                selectedProgramIDs.subtract(Set(programs.map(\.id)))
            }
            .disabled(selectedProgramCount == 0)
        }
    }

    private var selectedProgramCount: Int {
        selectedProgramIDs.intersection(Set(programs.map(\.id))).count
    }
}

struct ProgramSelectionSection: View {
    let title: String
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    var body: some View {
        Section(title) {
            ForEach(programs) { program in
                ProgramSelectionRow(
                    program: program,
                    isSelected: selectedProgramIDs.contains(program.id)
                ) {
                    toggleProgramSelection(program.id)
                }
            }
        }
    }

    private func toggleProgramSelection(_ programID: UUID) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}

private struct ProgramSelectionRow: View {
    let program: BonusProgram
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        isSelected
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Valgt" : "Ikke valgt")
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.mock())
}
