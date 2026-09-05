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
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.86)
            .padding(.horizontal, 9)
            .frame(minHeight: 36)
            .background(isSelected ? PoengjegerTheme.accentSoft : PoengjegerTheme.surface)
            .foregroundStyle(isSelected ? PoengjegerTheme.accent : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(campaign.feedHeadline)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                Text(expiry.text.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(expiry.urgent ? PoengjegerTheme.warning : .secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .accessibilityLabel(expiry.text)
            }

            if campaign.feedHeadline != campaign.title {
                Text(campaign.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(campaign.feedReason)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if campaign.feedDecisionLabel != nil || !programs.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        metadata
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
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
            .font(.caption2.weight(.bold))
            .foregroundStyle(PoengjegerTheme.accent)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PoengjegerTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Vurdering \(label)")
    }
}

struct ProgramTag: View {
    let program: BonusProgram

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(program.feedColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)

            Text(program.shortDisplayName.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(program.feedColor)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FeedPlaceholderRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("15 % bonus")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Spacer()
                Text("3 DAGER IGJEN")
                    .font(.caption2.weight(.bold))
            }

            Text("Kampanjetittel med kort forklaring")
                .font(.subheadline)

            HStack {
                ProgramTag(program: SampleData.trumf)
                ProgramTag(program: SampleData.euroBonus)
            }
        }
        .padding(.vertical, 2)
        .listRowInsets(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16))
        .listRowBackground(PoengjegerTheme.background)
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
                            HStack(spacing: 12) {
                                Image(systemName: selectedProgramIDs.contains(program.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedProgramIDs.contains(program.id) ? PoengjegerTheme.accent : .secondary)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(program.name)
                                        .foregroundStyle(.primary)
                                    Text(program.issuerName)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
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
