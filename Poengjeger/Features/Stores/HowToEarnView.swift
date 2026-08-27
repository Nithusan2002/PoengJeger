import SwiftUI

struct HowToEarnView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.openURL) private var openURL

    let store: Store
    let combination: EarningCombination

    private var sortedSteps: [EarningCombinationStep] {
        combination.steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                header

                if let warningText = combination.warningText {
                    warningCard(warningText)
                }

                stepsSection

                handoffButton

                handoffDisclosure
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(PoengjegerTheme.background)
        .navigationTitle("Slik gjør du det")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PoengjegerTheme.background, for: .navigationBar)
        .task(id: combination.id) {
            environment.track(.init(
                name: "handoff_opened",
                surface: "how_to_earn",
                entityType: "earning_combination",
                entityID: combination.id,
                properties: [
                    "store_id": store.id.uuidString,
                    "requires_warning": combination.warningText == nil ? "false" : "true"
                ]
            ))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                StoreInitialMark(name: store.name)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(store.category?.name ?? "Butikk")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("BESTE KOMBINASJON")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(PoengjegerTheme.primary)

                Text(combination.totalValueLabel)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(combination.summary)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PoengjegerTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: PoengjegerTheme.shadow, radius: 8, y: 3)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PoengjegerTheme.primaryBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("HANDLING")
                    .font(.caption.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(.secondary)

                Text("Følg stegene i rekkefølge")
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { index, step in
                    StepInstructionRow(index: index + 1, text: step.text)

                    if step.id != sortedSteps.last?.id {
                        Divider()
                            .padding(.leading, 44)
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

    private func warningCard(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(PoengjegerTheme.warning)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PoengjegerTheme.warningSoft)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PoengjegerTheme.warning.opacity(0.18), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var handoffButton: some View {
        if let url = combination.primaryHandoffURL {
            Button {
                environment.track(.init(
                    name: "external_destination_opened",
                    surface: "how_to_earn",
                    entityType: "earning_combination",
                    entityID: combination.id,
                    properties: [
                        "store_id": store.id.uuidString,
                        "destination_type": handoffDestinationName(for: url)
                    ]
                ))
                openURL(url)
            } label: {
                Label("Start handelen", systemImage: "arrow.up.forward.app.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(PoengjegerTheme.primary)
            .accessibilityHint("Åpner \(handoffDestinationName(for: url)) eksternt.")
        } else {
            ContentUnavailableView(
                "Ingen handoff-lenke ennå",
                systemImage: "link.badge.plus",
                description: Text("Redaksjonen må legge inn riktig portal før direkte handoff kan brukes.")
            )
        }
    }

    private var handoffDisclosure: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("Du sendes videre til \(handoffDestinationNameForDisclosure).")

            Text("Lenken kan gi Poengjeger provisjon. Den påvirker verken rangeringen eller hva vi anbefaler.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
    }

    private var handoffDestinationNameForDisclosure: String {
        guard let url = combination.primaryHandoffURL else { return "riktig portal" }
        return handoffDestinationName(for: url)
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

private struct StepInstructionRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(PoengjegerTheme.primary)
                .frame(width: 26, height: 26)
                .background(PoengjegerTheme.primarySoft)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Steg \(index). \(text)")
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
