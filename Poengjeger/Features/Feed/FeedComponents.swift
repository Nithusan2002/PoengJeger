import SwiftUI

struct FeedPriorityStats {
    let urgentCount: Int
    let highValueCount: Int

    init(campaigns: [Campaign]) {
        urgentCount = campaigns.filter(\.isFeedUrgent).count
        highValueCount = campaigns.filter { $0.isFeedHighValue && !$0.isFeedUrgent }.count
    }
}

struct FeedSectionModel: Identifiable {
    let id: String
    let title: String
    let detail: String
    let campaigns: [Campaign]

    static func makeSections(from campaigns: [Campaign]) -> [FeedSectionModel] {
        let urgent = campaigns.filter(\.isFeedUrgent)
        let highValue = campaigns.filter { $0.isFeedHighValue && !$0.isFeedUrgent }
        let other = campaigns.filter { !$0.isFeedUrgent && !$0.isFeedHighValue }

        return [
            FeedSectionModel(
                id: "urgent",
                title: "Haster",
                detail: "Frister du bør sjekke først",
                campaigns: urgent
            ),
            FeedSectionModel(
                id: "high-value",
                title: "Høy verdi",
                detail: "Vurdert som mest interessant",
                campaigns: highValue
            ),
            FeedSectionModel(
                id: "other",
                title: "Flere muligheter",
                detail: "Aktive kampanjer for videre vurdering",
                campaigns: other
            )
        ]
        .filter { !$0.campaigns.isEmpty }
    }
}

struct FeedSectionHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxSmall) {
            Text(title)
                .font(DesignTokens.Typography.footnoteBold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(detail)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.top, DesignTokens.Spacing.medium)
        .padding(.bottom, DesignTokens.Spacing.xSmall)
    }
}

struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(DesignTokens.Typography.calloutSemibold)
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .padding(.horizontal, DesignTokens.Spacing.mediumPlus)
            .frame(minHeight: 36)
            .background(isSelected ? DesignTokens.Colors.brandPrimarySoft : DesignTokens.Colors.surface)
            .foregroundStyle(isSelected ? DesignTokens.Colors.brandPrimary : DesignTokens.Colors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous))
    }
}

extension FeedSort {
    var shortTitle: String {
        switch self {
        case .expiringFirst:
            return "Frist"
        case .newest:
            return "Nyeste"
        case .alphabetic:
            return "A-Å"
        }
    }
}

struct FeedCampaignRow: View {
    let campaign: Campaign
    let programs: [BonusProgram]

    private var expiry: ExpiryDisplay {
        FeedDateHelper.expiryLabel(campaign.endDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.smallPlus) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.standard) {
                Text(campaign.feedHeadline)
                    .font(DesignTokens.Typography.feedValue)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: DesignTokens.Spacing.medium)

                Text(expiry.text.uppercased())
                    .font(DesignTokens.Typography.caption2Bold)
                    .foregroundStyle(
                        expiry.urgent
                            ? DesignTokens.Colors.warning
                            : DesignTokens.Colors.textSecondary
                    )
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .accessibilityLabel(expiry.text)
            }

            if campaign.feedHeadline != campaign.title {
                Text(campaign.title)
                    .font(DesignTokens.Typography.subheadlineMedium)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(campaign.feedReason)
                .font(DesignTokens.Typography.footnote)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if campaign.feedDecisionLabel != nil || !programs.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DesignTokens.Spacing.controlGap) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                        metadata
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, DesignTokens.Spacing.xxSmall)
    }

    @ViewBuilder
    private var metadata: some View {
        if let decisionLabel = campaign.feedDecisionLabel {
            FeedEditorialTierPill(label: decisionLabel)
        }

        ForEach(programs) { program in
            ProgramTag(program: program)
        }
    }
}

struct FeedEditorialTierPill: View {
    let label: String

    var body: some View {
        Text(label.uppercased())
            .font(DesignTokens.Typography.caption2Bold)
            .foregroundStyle(DesignTokens.Colors.brandPrimary)
            .lineLimit(1)
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.xSmall)
            .background(DesignTokens.Colors.brandPrimarySoft)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.small, style: .continuous))
            .accessibilityLabel("Vurdering \(label)")
    }
}

struct ProgramTag: View {
    let program: BonusProgram

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.compact) {
            Circle()
                .fill(program.feedColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)

            Text(program.shortDisplayName.uppercased())
                .font(DesignTokens.Typography.caption2Bold)
                .foregroundStyle(program.feedColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FeedPlaceholderRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Text("15 % bonus")
                    .font(DesignTokens.Typography.feedValue)
                Spacer()
                Text("3 DAGER IGJEN")
                    .font(DesignTokens.Typography.caption2Bold)
            }

            Text("Kampanjetittel med kort forklaring")
                .font(DesignTokens.Typography.subheadline)

            HStack {
                ProgramTag(program: SampleData.trumf)
                ProgramTag(program: SampleData.euroBonus)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xxSmall)
        .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
        .listRowBackground(DesignTokens.Colors.background)
    }
}

struct ProgramFilterSheet: View {
    let programs: [BonusProgram]
    @Binding var selectedProgramIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Velg alle") {
                        selectedProgramIDs = Set(programs.map(\.id))
                    }

                    Button("Tøm valg", role: .destructive) {
                        selectedProgramIDs.subtract(Set(programs.map(\.id)))
                    }
                    .disabled(selectedProgramIDs.intersection(Set(programs.map(\.id))).isEmpty)
                }

                Section("Programmer") {
                    ForEach(programs) { program in
                        Button {
                            toggle(program.id)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.standard) {
                                Image(systemName: selectedProgramIDs.contains(program.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(
                                        selectedProgramIDs.contains(program.id)
                                            ? DesignTokens.Colors.brandPrimary
                                            : DesignTokens.Colors.textSecondary
                                    )
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
                                    Text(program.name)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    Text(program.issuerName)
                                        .font(DesignTokens.Typography.footnote)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                }

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(program.name)
                        .accessibilityValue(selectedProgramIDs.contains(program.id) ? "Valgt" : "Ikke valgt")
                    }
                }
            }
            .navigationTitle("Dine programmer")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ programID: UUID) {
        if selectedProgramIDs.contains(programID) {
            selectedProgramIDs.remove(programID)
        } else {
            selectedProgramIDs.insert(programID)
        }
    }
}
