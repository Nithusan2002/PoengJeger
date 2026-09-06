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
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.comfortable) {
                LearnHeader()

                if environment.loadState == .loading && programs.isEmpty {
                    ProgressView("Laster programmer...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, DesignTokens.Spacing.spacious)
                } else if programs.isEmpty {
                    LearnEmptyState()
                } else {
                    LearnFilterBar(filters: filters, selection: $selectedFilter)

                    if visibleGuides.isEmpty {
                        LearnFilteredEmptyState(filterTitle: selectedFilter.title)
                    } else {
                        LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.none) {
                            ForEach(visibleGuides) { guide in
                                if let program = programs.first(where: { $0.id == guide.programID }) {
                                    NavigationLink {
                                        ProgramDetailView(
                                            program: program,
                                            guide: guide,
                                            entryPoint: "learn"
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
                                            .padding(.leading, DesignTokens.Spacing.largeIconLeadingInset)
                                    }
                                }
                            }
                        }
                        .background(DesignTokens.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.screen)
            .padding(.top, DesignTokens.Spacing.sectionLarge)
            .padding(.bottom, DesignTokens.Spacing.section)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Guider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignTokens.Colors.background, for: .navigationBar)
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Guider")
                .font(DesignTokens.Typography.editorialLargeTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Korte forklaringer for EuroBonus og Trumf, skrevet for valgene du tar før du handler.")
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignTokens.Spacing.xxSmall)
    }
}

private struct LearnFilterBar: View {
    let filters: [LearnGuideFilter]
    @Binding var selection: LearnGuideFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                ForEach(filters) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.title)
                            .font(DesignTokens.Typography.subheadlineBold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, DesignTokens.Spacing.screen)
                            .padding(.vertical, DesignTokens.Spacing.controlGap)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        selection == filter
                            ? DesignTokens.Colors.textPrimary
                            : DesignTokens.Colors.brandPrimary
                    )
                    .background(DesignTokens.Colors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(selection == filter ? DesignTokens.Colors.brandPrimary : DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
                    }
                    .accessibilityAddTraits(selection == filter ? .isSelected : [])
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxSmall)
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
            ?? "Guide kommer når innholdet er bekreftet."
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.card) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                    .fill(program.programColor.opacity(DesignTokens.Opacity.soft))

                ProgramMark(program: program, size: 42)
            }
            .frame(width: 56, height: 56)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.smallPlus) {
                Text(guide.titleText(for: program))
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(previewText)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignTokens.Spacing.medium) {
                    LearnCardPill(
                        title: isReviewed ? "Kontrollert" : "Utkast",
                        systemImage: isReviewed ? "checkmark.seal" : "exclamationmark.triangle",
                        tint: isReviewed ? DesignTokens.Colors.success : DesignTokens.Colors.warning
                    )
                }
            }

            Spacer(minLength: DesignTokens.Spacing.medium)

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.top, DesignTokens.Spacing.comfortable)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, DesignTokens.Spacing.card)
        .padding(.vertical, DesignTokens.Spacing.screen)
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
            .font(DesignTokens.Typography.captionBold)
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, DesignTokens.Spacing.controlGap)
            .padding(.vertical, DesignTokens.Spacing.smallPlus)
            .background(tint.opacity(DesignTokens.Opacity.soft))
            .clipShape(Capsule())
    }
}

private struct LearnEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Ingen programmer ennå")
                .font(DesignTokens.Typography.headlineSemibold)

            Text("Når EuroBonus og Trumf er klare, vises de her med bekreftede guider.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
        }
    }
}

private struct LearnFilteredEmptyState: View {
    let filterTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Ingen guider i \(filterTitle)")
                .font(DesignTokens.Typography.headlineSemibold)

            Text("Prøv et annet filter, eller kom tilbake når nye programguider er publisert.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous)
                .stroke(DesignTokens.Colors.border, lineWidth: DesignTokens.Stroke.standard)
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
