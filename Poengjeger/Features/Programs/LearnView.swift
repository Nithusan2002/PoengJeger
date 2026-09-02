import SwiftUI

struct LearnView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedFilter: LearnGuideFilter = .all

    private var programs: [BonusProgram] {
        environment.firstPhasePrograms
    }

    private var filters: [LearnGuideFilter] {
        [.all] + programs.map { .program($0.id, $0.name) }
    }

    private var visibleGuides: [ProgramGuide] {
        let guides = environment.publishedGuides(for: programs)
        switch selectedFilter {
        case .all:
            return guides
        case let .program(programID, _):
            return guides.filter { $0.programID == programID }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                LearnHeader()

                if environment.loadState == .loading && programs.isEmpty {
                    ProgressView("Laster programmer...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if programs.isEmpty {
                    LearnEmptyState()
                } else {
                    LearnFilterBar(filters: filters, selection: $selectedFilter)

                    if visibleGuides.isEmpty {
                        LearnFilteredEmptyState(filterTitle: selectedFilter.title)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(visibleGuides) { guide in
                                if let program = programs.first(where: { $0.id == guide.programID }) {
                                    NavigationLink {
                                        ProgramDetailView(
                                            program: program,
                                            guide: guide
                                        )
                                    } label: {
                                        LearnGuideRow(
                                            program: program,
                                            guide: guide
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    if guide.id != visibleGuides.last?.id {
                                        Divider()
                                            .padding(.leading, 78)
                                    }
                                }
                            }
                        }
                        .background(PoengjegerTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(PoengjegerTheme.border, lineWidth: 1)
                        }
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
}

private enum LearnGuideFilter: Hashable, Identifiable {
    case all
    case program(UUID, String)

    var id: String {
        switch self {
        case .all:
            return "all"
        case let .program(programID, _):
            return programID.uuidString
        }
    }

    var title: String {
        switch self {
        case .all:
            return "Alle"
        case let .program(_, name):
            return name
        }
    }
}

private struct LearnHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Guider")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Korte forklaringer for EuroBonus og Trumf, skrevet for valgene du tar før du handler.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 2)
    }
}

private struct LearnFilterBar: View {
    let filters: [LearnGuideFilter]
    @Binding var selection: LearnGuideFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selection == filter ? .primary : PoengjegerTheme.accent)
                    .background(PoengjegerTheme.elevatedSurface)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(selection == filter ? PoengjegerTheme.accent : PoengjegerTheme.border, lineWidth: 1)
                    }
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

private struct LearnGuideRow: View {
    let program: BonusProgram
    let guide: ProgramGuide

    private var isReviewed: Bool {
        guide.lastReviewedAt != nil
    }

    private var previewText: String {
        guide.introText?.nonEmpty
            ?? guide.bodyMarkdownExcerpt
            ?? guide.strategy.nonEmpty
            ?? "Guide kommer når innholdet er redaksjonelt kontrollert."
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(program.programColor.opacity(0.12))

                ProgramMark(program: program, size: 42)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(guide.titleText(for: program))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    LearnCardPill(
                        title: isReviewed ? "Kontrollert" : "Utkast",
                        systemImage: isReviewed ? "checkmark.seal" : "exclamationmark.triangle",
                        tint: isReviewed ? PoengjegerTheme.success : PoengjegerTheme.warning
                    )
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 18)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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

            Text("Når EuroBonus og Trumf er klare, vises de her med redaksjonelt kontrollerte guider.")
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

private struct LearnFilteredEmptyState: View {
    let filterTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingen guider i \(filterTitle)")
                .font(.headline.weight(.semibold))

            Text("Prøv et annet filter, eller kom tilbake når nye programguider er publisert.")
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
