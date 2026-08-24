import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    private var selectedProgramCount: Int {
        environment.userSession.selectedProgramIDs
            .intersection(Set(programs.map(\.id)))
            .count
    }

    var body: some View {
        @Bindable var environment = environment

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                ProfileStatusCard(
                    selectedProgramCount: selectedProgramCount,
                    programCount: programs.count,
                    favoriteCount: environment.favoriteCampaigns.count
                )

                notificationCard

                ProfileProgramSection(
                    programs: programs,
                    selectedProgramIDs: $environment.userSession.selectedProgramIDs
                )

                #if DEBUG
                debugSection(dataSourceLabel: environment.dataSource?.label)
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profil")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.primary)

            Text("Styr hvilke bonusprogrammer som former søk, guider og anbefalte muligheter.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationCard: some View {
        ProfileInfoCard(
            iconName: "bell.slash",
            title: "Varsler kommer senere",
            subtitle: "MVP-en viser relevante muligheter i appen først. Varsler aktiveres når redaksjonell kontroll og preferanser er klare."
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

private struct ProfileStatusCard: View {
    let selectedProgramCount: Int
    let programCount: Int
    let favoriteCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.primary)
                    .frame(width: 46, height: 46)
                    .background(PoengjegerTheme.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Din Poengjeger")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Personlig visning uten konto-tilkobling.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                ProfileMetricPill(value: "\(selectedProgramCount)/\(programCount)", label: "programmer")
                ProfileMetricPill(value: "\(favoriteCount)", label: "lagret")
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

private struct ProfileMetricPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProfileProgramSection: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>

    private var selectedProgramCount: Int {
        selectedProgramIDs.intersection(Set(programs.map(\.id))).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeading(eyebrow: "BONUSPROGRAMMER", title: "Dine valg")

            HStack(spacing: 10) {
                Button {
                    selectedProgramIDs = Set(programs.map(\.id))
                } label: {
                    Label("Velg alle", systemImage: "checkmark.circle")
                }
                .disabled(programs.isEmpty)

                Button {
                    selectedProgramIDs.subtract(Set(programs.map(\.id)))
                } label: {
                    Label("Tøm", systemImage: "xmark.circle")
                }
                .disabled(selectedProgramCount == 0)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .tint(PoengjegerTheme.primary)

            VStack(spacing: 0) {
                ForEach(programs) { program in
                    Button {
                        toggleProgramSelection(program.id)
                    } label: {
                        ProfileProgramRow(
                            program: program,
                            isSelected: selectedProgramIDs.contains(program.id)
                        )
                    }
                    .buttonStyle(.plain)

                    if program.id != programs.last?.id {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .background(PoengjegerTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PoengjegerTheme.border, lineWidth: 1)
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

private struct ProfileProgramRow: View {
    let program: BonusProgram
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(program.programColor)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(program.issuerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? PoengjegerTheme.primary : Color(uiColor: .tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Valgt" : "Ikke valgt")
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
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(2.2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(.title2, design: .serif).weight(.bold))
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
