import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
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
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profil")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)

            Text("Tilpass Poengjeger til programmene du faktisk bruker.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationCard: some View {
        ProfileInfoCard(
            iconName: "bell.slash",
            title: "Varsler",
            subtitle: "Kommer senere når redaksjonell kontroll og tydelige preferanser er klare."
        )
    }

    #if DEBUG
    private func debugSection(dataSourceLabel: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeading(eyebrow: "INTERN", title: "Redaksjon")

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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Mine programmer")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 12)

                    Text("\(selectedProgramCount) av \(programs.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                }

                Text("Prioriterer kampanjer, butikker og guider uten konto-tilkobling.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button {
                    selectedProgramIDs = Set(programs.map(\.id))
                } label: {
                    Label("Alle", systemImage: "checkmark.circle")
                }
                .disabled(programs.isEmpty)

                Button {
                    selectedProgramIDs.subtract(Set(programs.map(\.id)))
                } label: {
                    Label("Ingen", systemImage: "xmark.circle")
                }
                .disabled(selectedProgramCount == 0)
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(PoengjegerTheme.primary)

            VStack(spacing: 0) {
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
                            .padding(.leading, 44)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
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
            HStack(spacing: 11) {
                Circle()
                    .fill(program.programColor)
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(program.issuerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .tint(PoengjegerTheme.primary)
        .accessibilityValue(isSelected ? "Valgt" : "Ikke valgt")
    }
}

private struct ProfileAppearanceSection: View {
    @Binding var prefersDarkMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $prefersDarkMode) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.primary)
                        .frame(width: 34, height: 34)
                        .background(PoengjegerTheme.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mørk modus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(prefersDarkMode ? "Appen vises med mørk bakgrunn." : "Appen vises med lys bakgrunn.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .tint(PoengjegerTheme.primary)
            .accessibilityValue(prefersDarkMode ? "På" : "Av")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

private struct ProfileActionRow: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.primary)
                .frame(width: 34, height: 34)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.primary)
                .frame(width: 34, height: 34)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileSectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
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
