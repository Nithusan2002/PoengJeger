import SwiftUI

struct LearnView: View {
    @Environment(AppEnvironment.self) private var environment

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("GUIDER")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.accent)

                    Text("Forstå poengene før du handler")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Korte programguider som forklarer hva du bør sjekke, når kampanjer er nyttige og hvilke feller som kan spise opp verdien.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 8)

                LearnChecklistCard()

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

    private var isReviewed: Bool {
        guide?.lastReviewedAt != nil
    }

    private var previewText: String {
        guide?.introText?.nonEmpty
            ?? guide?.strategy.nonEmpty
            ?? "Guide kommer. Aktive kampanjer vises likevel."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ProgramMark(program: program, size: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                LearnCardPill(
                    title: "\(activeCampaignCount) aktive",
                    systemImage: "ticket",
                    tint: PoengjegerTheme.accent
                )

                LearnCardPill(
                    title: isReviewed ? "Kontrollert" : "Utkast",
                    systemImage: isReviewed ? "checkmark.seal" : "exclamationmark.triangle",
                    tint: isReviewed ? PoengjegerTheme.success : PoengjegerTheme.warning
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
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

private struct LearnChecklistCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bruk guidene slik", systemImage: "checklist")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                LearnChecklistRow(text: "Start med programmet som er relevant for kjøpet ditt.")
                LearnChecklistRow(text: "Sjekk verdi, krav og vanlige feller før du åpner kampanjen.")
                LearnChecklistRow(text: "Gå tilbake til aktive kampanjer når du vet hva som faktisk passer.")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
    }
}

private struct LearnChecklistRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.success)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LearnCardPill: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
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
