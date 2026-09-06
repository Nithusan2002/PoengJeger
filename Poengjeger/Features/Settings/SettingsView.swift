import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                header

                ProfileProgramSection(
                    programs: programs,
                    selectedProgramIDs: $environment.userSession.selectedProgramIDs
                )

                ProfileAppearanceSection(prefersDarkMode: $environment.userSession.prefersDarkMode)

                notificationCard

                #if DEBUG
                debugSection(dataSourceLabel: environment.dataSource?.label)
                #endif
            }
            .padding(.horizontal, DesignTokens.Spacing.comfortable)
            .padding(.top, DesignTokens.Spacing.largePlus)
            .padding(.bottom, DesignTokens.Spacing.sectionLarge)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Profil")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Tilpass Poengjeger til programmene du faktisk bruker.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationCard: some View {
        ProfileInfoCard(
            iconName: "bell.slash",
            title: "Varsler",
            subtitle: "Kommer senere når bekreftet innhold og tydelige preferanser er klare."
        )
    }

    #if DEBUG
    private func debugSection(dataSourceLabel: String?) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            ProfileSectionHeading(eyebrow: "INTERN", title: "Kontroll")

            if let dataSourceLabel {
                ProfileInfoCard(
                    iconName: "server.rack",
                    title: "Datakilde",
                    subtitle: dataSourceLabel
                )
            }

            let supabaseSummary = SupabaseConfiguration.bundleDebugSummary()
            ProfileInfoCard(
                iconName: "link",
                title: "Supabase-konfig",
                subtitle: "Host: \(supabaseSummary.host)\nPublishable key: \(supabaseSummary.hasPublishableKey ? "Finnes" : "Mangler")"
            )

            NavigationLink {
                AdminQueueView()
            } label: {
                ProfileActionRow(
                    iconName: "tray.full",
                    title: "Admin-kø",
                    subtitle: "Intern review av ingestion-kandidater."
                )
            }
            .buttonStyle(.plain)
        }
    }
    #endif
}

private struct ProfileProgramSection: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    private var selectedProgramCount: Int {
        selectedProgramIDs.intersection(Set(programs.map(\.id))).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Mine programmer")
                        .font(DesignTokens.Typography.headlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Spacer(minLength: DesignTokens.Spacing.standard)

                    Text("\(selectedProgramCount) av \(programs.count)")
                        .font(DesignTokens.Typography.captionSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                }

                Text("Prioriterer kampanjer, butikker og guider uten konto-tilkobling.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: DesignTokens.Spacing.medium) {
                Button {
                    selectedProgramIDs = Set(programs.map(\.id))
                } label: {
                    Label("Alle", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .minimumTouchTarget()
                .disabled(programs.isEmpty)

                Button {
                    selectedProgramIDs.subtract(Set(programs.map(\.id)))
                } label: {
                    Label("Ingen", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .minimumTouchTarget()
                .disabled(selectedProgramCount == 0)
            }
            .font(DesignTokens.Typography.captionSemibold)
            .tint(DesignTokens.Colors.brandPrimary)

            VStack(spacing: DesignTokens.Spacing.none) {
                ForEach(programs) { program in
                    ProfileProgramRow(
                        program: program,
                        isSelected: Binding(
                            get: { selectedProgramIDs.contains(program.id) },
                            set: { isSelected in
                                setProgramSelection(program.id, isSelected: isSelected)
                            }
                        )
                    )

                    if program.id != programs.last?.id {
                        Divider()
                            .padding(.leading, DesignTokens.Spacing.searchLeadingInset)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
    }

    private func setProgramSelection(_ programID: UUID, isSelected: Bool) {
        if isSelected {
            selectedProgramIDs.insert(programID)
        } else {
            selectedProgramIDs.remove(programID)
        }
    }
}

private struct ProfileProgramRow: View {
    let program: BonusProgram
    @Binding var isSelected: Bool

    var body: some View {
        Toggle(isOn: $isSelected) {
            HStack(spacing: DesignTokens.Spacing.controlGapPlus) {
                Circle()
                    .fill(program.programColor)
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text(program.name)
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(program.issuerName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.standard)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .tint(DesignTokens.Colors.brandPrimary)
        .accessibilityValue(isSelected ? "Valgt" : "Ikke valgt")
    }
}

private struct ProfileAppearanceSection: View {
    @Binding var prefersDarkMode: Bool

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.none) {
            Toggle(isOn: $prefersDarkMode) {
                HStack(spacing: DesignTokens.Spacing.standard) {
                    Image(systemName: "moon.fill")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(DesignTokens.Colors.brandPrimary)
                        .frame(width: 34, height: 34)
                        .background(DesignTokens.Colors.brandPrimarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                        Text("Mørk modus")
                            .font(DesignTokens.Typography.subheadlineSemibold)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text(prefersDarkMode ? "Appen vises med mørk bakgrunn." : "Appen vises med lys bakgrunn.")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(DesignTokens.Spacing.card)
            .minimumTouchTarget()
            .tint(DesignTokens.Colors.brandPrimary)
            .accessibilityValue(prefersDarkMode ? "På" : "Av")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
    }
}

private struct ProfileActionRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            Image(systemName: iconName)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .frame(width: 34, height: 34)
                .background(DesignTokens.Colors.brandPrimarySoft)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(title)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .frame(minHeight: 66, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileInfoCard: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.standard) {
            Image(systemName: iconName)
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.brandPrimary)
                .frame(width: 34, height: 34)
                .background(DesignTokens.Colors.brandPrimarySoft)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(title)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .shadow(color: DesignTokens.Colors.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileSectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text(eyebrow)
                .font(DesignTokens.Typography.caption2Bold)
                .tracking(1.6)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(title)
                .font(DesignTokens.Typography.headlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppEnvironment.mock())
    }
}
