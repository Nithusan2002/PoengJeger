import SwiftUI

struct ProgramDetailView: View {
    let program: BonusProgram
    let guide: ProgramGuide?
    let campaigns: [Campaign]

    private var activeCampaigns: [Campaign] {
        campaigns
            .filter { $0.isActive && $0.linkedProgramIDs.contains(program.id) }
            .sorted { first, second in
                switch (first.endDate, second.endDate) {
                case let (firstDate?, secondDate?):
                    return firstDate < secondDate
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return first.title.localizedCompare(second.title) == .orderedAscending
                }
            }
    }

    private var introText: String {
        guide?.introText?.nonEmpty
            ?? guide?.strategy.nonEmpty
            ?? "Ingen publisert programguide for \(program.name) ennå. Aktive kampanjer vises fortsatt under."
    }

    private var strategyText: String? {
        guard guide?.introText?.nonEmpty != nil else {
            return nil
        }

        return guide?.strategy.nonEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ProgramHero(
                    program: program,
                    activeCampaignCount: activeCampaigns.count,
                    introText: introText,
                    kicker: guide.guideKickerText,
                    readingTimeLabel: guide.readingTimeLabelText,
                    lastReviewedAt: guide?.lastReviewedAt
                )

                ProgramInsightRail(
                    cards: [
                        ProgramInsight(
                            systemImage: "centsign.circle",
                            eyebrow: "Verdi",
                            title: guide?.valueEstimateLabel?.nonEmpty ?? "Ukjent",
                            detail: guide?.valueEstimateDetail?.nonEmpty ?? "Verdien legges inn når den er kontrollert."
                        ),
                        ProgramInsight(
                            systemImage: "hourglass",
                            eyebrow: "Utløp",
                            title: guide?.expirationSummary?.nonEmpty ?? "Sjekk vilkår",
                            detail: guide?.expirationDetail?.nonEmpty ?? "Kontroller programmets egne vilkår før du lar poeng stå ubrukt."
                        ),
                        ProgramInsight(
                            systemImage: "ticket",
                            eyebrow: "Kampanjer",
                            title: "\(activeCampaigns.count) aktive",
                            detail: activeCampaigns.isEmpty ? "Ingen publiserte kampanjer akkurat nå." : "Se aktuelle muligheter for \(program.name) lenger ned."
                        )
                    ]
                )

                ProgramDecisionSnapshot(
                    title: guide.decisionSectionTitleText,
                    earningLabel: guide.earningDecisionLabelText,
                    earningTip: guide?.earningTips.first,
                    redemptionLabel: guide.redemptionDecisionLabelText,
                    redemptionTip: guide?.redemptionTips.first,
                    riskLabel: guide.riskDecisionLabelText,
                    riskNote: guide?.riskNotes.first
                )

                if let strategyText {
                    ProgramStrategyCard(title: guide.strategySectionTitleText, text: strategyText)
                }

                ProgramTipSection(
                    title: guide.earningSectionTitleText,
                    subtitle: guide.earningSectionIntroText,
                    systemImage: "plus.circle",
                    items: guide?.earningTips ?? []
                )

                ProgramTipSection(
                    title: guide.redemptionSectionTitleText,
                    subtitle: guide.redemptionSectionIntroText,
                    systemImage: "arrow.up.right.circle",
                    items: guide?.redemptionTips ?? []
                )

                ProgramTipSection(
                    title: guide.riskSectionTitleText,
                    subtitle: guide.riskSectionIntroText,
                    systemImage: "exclamationmark.triangle",
                    items: guide?.riskNotes ?? []
                )

                ProgramCampaignSection(
                    program: program,
                    title: guide.campaignsSectionTitleText,
                    subtitle: guide.campaignsSectionIntroText(for: program),
                    campaigns: activeCampaigns
                )

                ProgramReviewNote(lastReviewedAt: guide?.lastReviewedAt)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
    }
}

private struct ProgramHero: View {
    let program: BonusProgram
    let activeCampaignCount: Int
    let introText: String
    let kicker: String
    let readingTimeLabel: String
    let lastReviewedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                ProgramMark(program: program, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(kicker)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PoengjegerTheme.accent)

                    Text(program.name)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        ProgramHeroMetaPill(text: readingTimeLabel, systemImage: "book")
                        ProgramHeroMetaPill(text: "\(activeCampaignCount) aktive", systemImage: "ticket")
                    }
                }

                Spacer(minLength: 8)
            }

            Text(introText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text(reviewText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }

    private var reviewText: String {
        if let lastReviewedAt {
            return "Redaksjonelt kontrollert \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted)). Programvilkår kan endre seg, så sjekk alltid kilden før større valg."
        }

        return "Guiden har begrenset innhold til den er redaksjonelt kontrollert."
    }
}

private struct ProgramHeroMetaPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(PoengjegerTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(PoengjegerTheme.accentSoft)
            .clipShape(Capsule())
    }
}

struct ProgramMark: View {
    let program: BonusProgram
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(program.programColor.opacity(0.14))

            Text(program.initials)
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(program.programColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct ProgramInsight: Identifiable {
    let id = UUID()
    let systemImage: String
    let eyebrow: String
    let title: String
    let detail: String
}

private struct ProgramInsightRail: View {
    let cards: [ProgramInsight]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(cards) { card in
                    ProgramInsightCard(card: card)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}

private struct ProgramInsightCard: View {
    let card: ProgramInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: card.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PoengjegerTheme.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(card.eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(card.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(card.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 166, alignment: .topLeading)
        .frame(minHeight: 160, alignment: .topLeading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.border, lineWidth: 1)
        }
    }
}

private struct ProgramStrategyCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "target")
                .font(.headline.weight(.bold))
                .foregroundStyle(PoengjegerTheme.accent)

            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
    }
}

private struct ProgramDecisionSnapshot: View {
    let title: String
    let earningLabel: String
    let earningTip: String?
    let redemptionLabel: String
    let redemptionTip: String?
    let riskLabel: String
    let riskNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "checklist")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                ProgramDecisionRow(
                    title: earningLabel,
                    text: earningTip?.nonEmpty ?? "kampanjen passer et kjøp du uansett skal gjøre.",
                    systemImage: "plus.circle",
                    tint: PoengjegerTheme.success
                )

                ProgramDecisionRow(
                    title: redemptionLabel,
                    text: redemptionTip?.nonEmpty ?? "du kan sammenligne poengbruk med kontantpris og vilkår.",
                    systemImage: "arrow.up.right.circle",
                    tint: PoengjegerTheme.accent
                )

                ProgramDecisionRow(
                    title: riskLabel,
                    text: riskNote?.nonEmpty ?? "vilkår, frist eller kostnad gjør verdien uklar.",
                    systemImage: "exclamationmark.triangle",
                    tint: PoengjegerTheme.warning
                )
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

private struct ProgramDecisionRow: View {
    let title: String
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProgramTipSection: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if items.isEmpty {
                ProgramEmptyGuideRow(text: "Ikke publisert ennå.")
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        ProgramGuideParagraph(text: item)
                            .accessibilityLabel("Avsnitt \(index + 1): \(item)")
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.top, 4)
    }
}

private struct ProgramGuideParagraph: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProgramEmptyGuideRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
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

private struct ProgramCampaignSection: View {
    let program: BonusProgram
    let title: String
    let subtitle: String
    let campaigns: [Campaign]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: "ticket")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if campaigns.isEmpty {
                ProgramEmptyGuideRow(text: "Ingen aktive kampanjer for \(program.name) akkurat nå.")
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(campaigns.prefix(2)) { campaign in
                        NavigationLink {
                            CampaignDetailView(campaign: campaign)
                        } label: {
                            ProgramCampaignPreview(campaign: campaign)
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        ProgramCampaignListView(program: program, campaigns: campaigns)
                    } label: {
                        Label("Se alle kampanjer", systemImage: "ticket")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.09, green: 0.12, blue: 0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .accessibilityLabel("Se alle aktive kampanjer for \(program.name)")
                }
            }
        }
    }
}

private struct ProgramCampaignPreview: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(campaign.editorialAssessment?.estimatedValueText?.nonEmpty ?? campaign.editorialSummary.nonEmpty ?? "Aktiv kampanje")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                if let endDateText = campaign.endDate?.relativeDeadlineText {
                    Text(endDateText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Text(campaign.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct ProgramCampaignListView: View {
    let program: BonusProgram
    let campaigns: [Campaign]

    var body: some View {
        List(campaigns) { campaign in
            NavigationLink {
                CampaignDetailView(campaign: campaign)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campaign.title)
                        .font(.headline)
                    Text(campaign.displaySummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProgramReviewNote: View {
    let lastReviewedAt: Date?

    var body: some View {
        Text(reviewText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 2)
    }

    private var reviewText: String {
        if let lastReviewedAt {
            return "Sist redaksjonelt kontrollert \(lastReviewedAt.formatted(date: .long, time: .omitted)). Sjekk alltid gjeldende programvilkår og kampanjekilde før større valg."
        }

        return "Guiden vises med begrenset innhold til den er kontrollert."
    }
}

extension BonusProgram {
    var initials: String {
        switch slug {
        case "sas-eurobonus":
            return "EUR"
        case "trumf":
            return "TRU"
        case "spenn":
            return "SPE"
        case "norwegian-cashpoints", "norwegian-reward":
            return "CAS"
        case "flying-blue":
            return "FLY"
        case "avios":
            return "AVI"
        default:
            let words = name.split(separator: " ")
            let letters = words.prefix(2).compactMap(\.first)
            let value = String(letters).uppercased()
            return value.isEmpty ? String(name.prefix(2)).uppercased() : value
        }
    }

    var programColor: Color {
        switch slug {
        case "sas-eurobonus":
            return Color(red: 0.08, green: 0.28, blue: 0.62)
        case "trumf":
            return Color(red: 0.78, green: 0.23, blue: 0.14)
        case "spenn":
            return Color(red: 0.09, green: 0.50, blue: 0.44)
        case "norwegian-cashpoints", "norwegian-reward":
            return Color(red: 0.79, green: 0.10, blue: 0.12)
        case "flying-blue":
            return Color(red: 0.20, green: 0.39, blue: 0.86)
        case "avios":
            return Color(red: 0.05, green: 0.44, blue: 0.68)
        default:
            return PoengjegerTheme.accent
        }
    }
}

private extension Optional where Wrapped == ProgramGuide {
    var guideKickerText: String {
        self?.guideKicker?.nonEmpty ?? "PROGRAMGUIDE"
    }

    var readingTimeLabelText: String {
        self?.readingTimeLabel?.nonEmpty ?? "4 min lesing"
    }

    var strategySectionTitleText: String {
        self?.strategySectionTitle?.nonEmpty ?? "Slik bør du bruke det"
    }

    var decisionSectionTitleText: String {
        self?.decisionSectionTitle?.nonEmpty ?? "Før du går videre"
    }

    var earningDecisionLabelText: String {
        self?.earningDecisionLabel?.nonEmpty ?? "Tjen poeng når"
    }

    var redemptionDecisionLabelText: String {
        self?.redemptionDecisionLabel?.nonEmpty ?? "Bruk poeng når"
    }

    var riskDecisionLabelText: String {
        self?.riskDecisionLabel?.nonEmpty ?? "Stopp opp hvis"
    }

    var earningSectionTitleText: String {
        self?.earningSectionTitle?.nonEmpty ?? "Slik tjener du poeng"
    }

    var earningSectionIntroText: String {
        self?.earningSectionIntro?.nonEmpty ?? "Start her før du går for en kampanje."
    }

    var redemptionSectionTitleText: String {
        self?.redemptionSectionTitle?.nonEmpty ?? "Slik bruker du poengene smart"
    }

    var redemptionSectionIntroText: String {
        self?.redemptionSectionIntro?.nonEmpty ?? "Bruk poengene der du ser hva du får igjen."
    }

    var riskSectionTitleText: String {
        self?.riskSectionTitle?.nonEmpty ?? "Vanlige feller"
    }

    var riskSectionIntroText: String {
        self?.riskSectionIntro?.nonEmpty ?? "Ting som kan gjøre en god kampanje mindre god."
    }

    var campaignsSectionTitleText: String {
        self?.campaignsSectionTitle?.nonEmpty ?? "Kampanjer nå"
    }

    func campaignsSectionIntroText(for program: BonusProgram) -> String {
        self?.campaignsSectionIntro?.nonEmpty ?? "Aktive kampanjer knyttet til \(program.name)."
    }
}

private extension Date {
    var relativeDeadlineText: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.startOfDay(for: self)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days < 0 {
            return "UTLØPT"
        }

        if days == 0 {
            return "I DAG"
        }

        if days == 1 {
            return "1 DAG IGJEN"
        }

        return "\(days) DAGER IGJEN"
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
        ProgramDetailView(
            program: SampleData.trumf,
            guide: SampleData.programGuides.first { $0.programID == SampleData.trumf.id },
            campaigns: SampleData.campaigns
        )
    }
}
