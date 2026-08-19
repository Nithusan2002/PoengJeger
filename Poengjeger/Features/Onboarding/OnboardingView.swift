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
                VStack(alignment: .leading, spacing: 22) {
                    OnboardingHeader()

                    OnboardingProgramGrid(
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

                    Text("Du kan endre dette senere i Profil.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.top, 76)
                .padding(.bottom, 28)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hva samler du i?")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Velg programmene dine. Vi bruker valget til å tilpasse kampanjer, guider og varsler.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingProgramGrid: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            ForEach(programs) { program in
                OnboardingProgramCard(
                    program: program,
                    isSelected: selectedProgramIDs.contains(program.id)
                ) {
                    toggleProgramSelection(program.id)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleProgramSelection(_ programID: UUID) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}

private struct OnboardingProgramCard: View {
    let program: BonusProgram
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(program.programColor)
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? program.programColor : Color(uiColor: .tertiaryLabel))
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 18)

                VStack(alignment: .leading, spacing: 6) {
                    Text(program.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    Text(program.onboardingDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
            .background(PoengjegerTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? program.programColor.opacity(0.72) : PoengjegerTheme.border, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(program.name)
        .accessibilityValue(isSelected ? "Valgt" : "Ikke valgt")
        .accessibilityHint(program.onboardingDescription)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct OnboardingContinueButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isEnabled ? "Vis mine kampanjer" : "Velg minst ett program", systemImage: "arrow.right.circle.fill")
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

private extension BonusProgram {
    var onboardingDescription: String {
        switch slug {
        case "sas-eurobonus":
            return "Fly, kort og partnere"
        case "trumf":
            return "Dagligvarer, netthandel og overføring"
        default:
            return issuerName
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.mock())
}
