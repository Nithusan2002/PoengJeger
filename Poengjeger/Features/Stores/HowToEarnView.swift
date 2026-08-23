import SwiftUI

struct HowToEarnView: View {
    let store: Store
    let combination: EarningCombination

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let warningText = combination.warningText {
                    Label(warningText, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PoengjegerTheme.warning)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PoengjegerTheme.warningSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(
                        title: "Steg før handoff",
                        subtitle: "Les dette først. Deretter sendes du direkte videre."
                    )

                    ForEach(combination.steps.sorted { $0.sortOrder < $1.sortOrder }) { step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\((combination.steps.sorted { $0.sortOrder < $1.sortOrder }.firstIndex(of: step) ?? 0) + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(PoengjegerTheme.primary)
                                .clipShape(Circle())
                                .accessibilityHidden(true)

                            Text(step.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .background(PoengjegerTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PoengjegerTheme.border, lineWidth: 1)
                }

                handoffButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Vis steg")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.name.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)

            Text("Beste valg nå")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(combination.totalValueLabel)
                .font(.system(.title, design: .serif).weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(combination.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var handoffButton: some View {
        if let url = combination.primaryHandoffURL {
            Link(destination: url) {
                Label("Start hos \(handoffDestinationName(for: url))", systemImage: "arrow.up.forward.app.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(PoengjegerTheme.primary)
            .accessibilityHint("Åpner ekstern portal eller butikk.")
        } else {
            ContentUnavailableView(
                "Ingen handoff-lenke ennå",
                systemImage: "link.badge.plus",
                description: Text("Redaksjonen må legge inn riktig portal før direkte handoff kan brukes.")
            )
        }
    }

    private func handoffDestinationName(for url: URL) -> String {
        if let matchingRate = store.earningRates.first(where: { $0.handoffURL == url }) {
            return matchingRate.method.name
        }

        let host = url.host()?.localizedLowercase ?? ""
        if host.contains("sas") {
            return "EuroBonus Shopping"
        }
        if host.contains("trumf") {
            return "Trumf"
        }

        return store.name
    }
}

#Preview {
    NavigationStack {
        HowToEarnView(
            store: SampleData.stores[0],
            combination: SampleData.stores[0].bestCombination!
        )
    }
}
