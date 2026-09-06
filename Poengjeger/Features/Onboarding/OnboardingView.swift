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
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
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
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DesignTokens.Spacing.screen)
                .padding(.top, DesignTokens.Spacing.onboardingTop)
                .padding(.bottom, DesignTokens.Spacing.sectionLarge)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("")
            .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.screen) {
            Text("Hva samler du i?")
                .font(DesignTokens.Typography.heroTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Velg programmene dine. Vi bruker valget til å tilpasse kampanjer, guider og varsler.")
                .font(DesignTokens.Typography.title3)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignTokens.Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingProgramGrid: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: DesignTokens.Spacing.card)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.Spacing.card) {
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.screen) {
                HStack(alignment: .top) {
                    Circle()
                        .fill(program.programColor)
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(DesignTokens.Typography.title3Semibold)
                        .foregroundStyle(isSelected ? program.programColor : DesignTokens.Colors.textTertiary)
                        .accessibilityHidden(true)
                }

                Spacer(minLength: DesignTokens.Spacing.comfortable)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text(program.name)
                        .font(DesignTokens.Typography.headlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    Text(program.onboardingDescription)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DesignTokens.Spacing.comfortable)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
            .background(DesignTokens.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                    .stroke(isSelected ? program.programColor.opacity(DesignTokens.Opacity.selectedBorder) : DesignTokens.Colors.border, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
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
        .tint(DesignTokens.Colors.brandPrimaryButton)
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
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
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
            HStack(spacing: DesignTokens.Spacing.standard) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        isSelected
                        ? AnyShapeStyle(DesignTokens.Colors.brandPrimary)
                        : AnyShapeStyle(.tertiary)
                    )

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text(program.name)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text(program.issuerName)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.vertical, DesignTokens.Spacing.standard)
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
