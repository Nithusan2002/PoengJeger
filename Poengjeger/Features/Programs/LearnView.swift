import SwiftUI

struct LearnView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("GUIDER")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.accent)

                    Text("Læringsstier for EuroBonus og Trumf")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Praktiske guider som støtter kjøpsreisen uten å skjule kjerneverdien bak betaling.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 8)

                if environment.loadState == .loading && programs.isEmpty {
                    ProgressView("Laster programmer...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if programs.isEmpty {
                    LearnEmptyState()
                } else {
                    ForEach(programs) { program in
                        NavigationLink {
                            ProgramDetailView(
                                program: program,
                                guide: environment.programGuide(for: program),
                                campaigns: environment.campaigns
                            )
                        } label: {
                            LearnProgramCard(
                                program: program,
                                guide: environment.programGuide(for: program),
                                activeCampaignCount: activeCampaignCount(for: program)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Guider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
    }

    private func activeCampaignCount(for program: BonusProgram) -> Int {
        environment.firstPhaseCampaigns.filter { $0.isActive && $0.linkedProgramIDs.contains(program.id) }.count
    }
}

private struct LearnProgramCard: View {
    let program: BonusProgram
    let guide: ProgramGuide?
    let activeCampaignCount: Int

    private var previewText: String {
        guide?.introText?.nonEmpty
            ?? guide?.strategy.nonEmpty
            ?? "Guide kommer. Aktive kampanjer vises likevel."
    }

    var body: some View {
        HStack(spacing: 14) {
            ProgramMark(program: program, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Label("\(activeCampaignCount) aktive kampanjer nå", systemImage: "ticket")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PoengjegerTheme.accent)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .contentShape(Rectangle())
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LearnEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingen programmer ennå")
                .font(.headline.weight(.semibold))

            Text("Når EuroBonus og Trumf er klare, vises de her med guider og aktive kampanjer.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    NavigationStack {
        LearnView()
            .environment(AppEnvironment.mock())
    }
}
