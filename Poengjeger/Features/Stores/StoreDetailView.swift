import SwiftUI

struct StoreDetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isRecommendationExpanded = false
    @State private var isOtherMethodsExpanded = false
    @State private var isFavorite = false

    let store: Store

    private var viewModel: StoreDetailViewModel {
        StoreDetailViewModel(
            store: store,
            selectedProgramIDs: environment.selectedFirstPhaseProgramIDs
        )
    }

    private var publishedRates: [StoreEarningRate] {
        viewModel.publishedRates
    }

    private var preferredCombination: EarningCombination? {
        viewModel.preferredCombination
    }

    private var primaryRates: [StoreEarningRate] {
        viewModel.primaryRates
    }

    private var activePromotions: [StoreEarningRate] {
        viewModel.activePromotions
    }

    private var baseContextRates: [StoreEarningRate] {
        viewModel.baseContextRates
    }

    private var displayedBaseContextRates: [StoreEarningRate] {
        viewModel.displayedBaseContextRates
    }

    private var otherAvailableRates: [StoreEarningRate] {
        viewModel.otherAvailableRates
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.none) {
            topBar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.largePlus) {
                    header
                    bestOpportunitySection
                    otherMethodsSection
                    sourceSection
                }
                .padding(.horizontal, DesignTokens.Spacing.comfortable)
                .padding(.top, DesignTokens.Spacing.controlGap)
                .padding(.bottom, DesignTokens.Spacing.xxLarge)
            }
        }
        .background(LovableStoreStyle.pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task(id: store.id) {
            isFavorite = environment.userSession.favoriteStoreIDs.contains(store.id)
            trackStoreDetailOpened()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    Image(systemName: "chevron.left")
                        .font(DesignTokens.Typography.subheadlineSemibold)

                    Text("Tilbake")
                        .font(DesignTokens.Typography.subheadlineSemibold)
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .minimumTouchTarget()
            .accessibilityLabel("Tilbake")

            Spacer()

            SaveToggleButton(
                isSaved: isFavorite,
                savedAccessibilityLabel: "Fjern butikk fra lagret",
                unsavedAccessibilityLabel: "Lagre butikk",
                action: toggleFavorite
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.comfortable)
        .padding(.top, DesignTokens.Spacing.medium)
        .padding(.bottom, DesignTokens.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LovableStoreStyle.pageBackground)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.card) {
            StoreInitialMark(name: store.name)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text(store.name)
                    .font(DesignTokens.Typography.editorialTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(categoryLine)
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer(minLength: DesignTokens.Spacing.none)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var bestOpportunitySection: some View {
        if let combination = preferredCombination {
            let includedRates = rates(in: combination)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                if !displayedBaseContextRates.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                        Text("Vanlig opptjening")
                            .font(DesignTokens.Typography.captionSemibold)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)

                        ForEach(displayedBaseContextRates) { rate in
                            CompactRateSummary(rate: rate)
                        }
                    }

                    Divider()
                }

                Text("DIN BESTE OPPTJENINGSVEI")
                    .font(DesignTokens.Typography.captionBold)
                    .tracking(2.2)
                    .foregroundStyle(DesignTokens.Colors.brandPrimary)

                Text(combination.totalValueLabel)
                    .font(DesignTokens.Typography.valueDisplay)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(TextListNormalizer.firstSentence(from: combination.summary))
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                bestOpportunityMeta(rates: includedRates, verifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt)

                NavigationLink {
                    HowToEarnView(store: store, combination: combination)
                } label: {
                    LovablePrimaryButtonLabel(title: "Slik gjør du det")
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    environment.track(.init(
                        name: "how_to_earn_opened",
                        surface: "store_detail",
                        entityType: "earning_combination",
                        entityID: combination.id,
                        properties: [
                            "store_id": store.id.uuidString,
                            "destination_type": viewModel.handoffDestinationName(for: combination),
                            "requires_warning": combination.warningText == nil ? "false" : "true"
                        ]
                    ))
                })

                Button {
                    withAnimation(recommendationDisclosureAnimation) {
                        isRecommendationExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Hvorfor er dette best?")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "chevron.down")
                            .font(DesignTokens.Typography.captionBold)
                            .foregroundStyle(DesignTokens.Colors.brandPrimary)
                            .rotationEffect(.degrees(isRecommendationExpanded ? 180 : 0))
                    }
                    .font(DesignTokens.Typography.subheadlineMedium)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.xxSmall)
                    .padding(.vertical, DesignTokens.Spacing.xSmall)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(DisclosureToggleButtonStyle())
                .minimumTouchTarget()
                .animation(recommendationDisclosureAnimation, value: isRecommendationExpanded)

                if isRecommendationExpanded {
                    RecommendationExplanation(
                        combination: combination,
                        rates: includedRates,
                        lastVerifiedAt: combination.lastVerifiedAt ?? store.lastVerifiedAt,
                        sourceFormatter: viewModel.sourceDestinationName
                    )
                    .transition(recommendationExplanationTransition)
                }
            }
            .padding(DesignTokens.Spacing.comfortable)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LovableStoreStyle.recommendationBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.prominentCard, style: .continuous)
                    .stroke(LovableStoreStyle.primaryBorder, lineWidth: DesignTokens.Stroke.emphasized)
            }
            .accessibilityElement(children: .contain)
        } else {
            if !baseContextRates.isEmpty {
                BaseEarningSummaryCard(rates: baseContextRates)
            } else {
                EmptyBestOpportunityCard()
            }
        }
    }

    private func bestOpportunityMeta(rates: [StoreEarningRate], verifiedAt: Date?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DesignTokens.Spacing.card) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                metaItems(rates: rates, verifiedAt: verifiedAt)
            }
        }
        .font(DesignTokens.Typography.captionSemibold)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func metaItems(rates: [StoreEarningRate], verifiedAt: Date?) -> some View {
        if let expiryText = viewModel.expiryText(for: rates) {
            Text(expiryText)
                .foregroundStyle(LovableStoreStyle.expiryText)
        }

        if let verifiedAt {
            Label("Sist kontrollert \(viewModel.shortDate(verifiedAt))", systemImage: "checkmark")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    @ViewBuilder
    private var otherMethodsSection: some View {
        if !otherAvailableRates.isEmpty {
            DisclosureGroup(isExpanded: $isOtherMethodsExpanded) {
                VStack(spacing: DesignTokens.Spacing.none) {
                    ForEach(otherAvailableRates) { rate in
                        CompactEarningMethodRow(rate: rate, storeID: store.id)

                        if rate.id != otherAvailableRates.last?.id {
                            Divider()
                                .padding(.leading, DesignTokens.Spacing.screen)
                        }
                    }
                }
                .padding(.top, DesignTokens.Spacing.medium)
            } label: {
                Text("Andre opptjeningsmuligheter (\(otherAvailableRates.count))")
                    .font(DesignTokens.Typography.headlineSemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .tint(DesignTokens.Colors.brandPrimary)
            .padding(DesignTokens.Spacing.screen)
            .background(LovableStoreStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.largeCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.largeCard, style: .continuous)
                    .stroke(LovableStoreStyle.border, lineWidth: DesignTokens.Stroke.standard)
            }
            .minimumTouchTarget()
            .accessibilityHint(isOtherMethodsExpanded ? "Skjuler øvrige opptjeningsmuligheter." : "Viser øvrige opptjeningsmuligheter.")
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.standard) {
                    sourceItems
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    sourceItems
                }
            }

            Text("Kontroller alltid gjeldende sats og vilkår hos tilbyderen før kjøp.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, DesignTokens.Spacing.xxSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var sourceItems: some View {
        if let lastVerifiedAt = store.lastVerifiedAt {
            Label("Kontrollert \(viewModel.shortDate(lastVerifiedAt))", systemImage: "checkmark.seal")
                .font(DesignTokens.Typography.captionSemibold)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }

        if let sourceRate = publishedRates.first(where: { $0.sourceURL != nil }),
           let sourceURL = sourceRate.sourceURL {
            Link(destination: sourceURL) {
                Label(sourceRate.sourceTitle ?? "Åpne kilde", systemImage: "arrow.up.right.square")
                    .font(DesignTokens.Typography.captionSemibold)
            }
            .tint(DesignTokens.Colors.brandPrimary)
            .minimumTouchTarget()
            .accessibilityHint("Åpner kilden eksternt.")
        }
    }

    private var categoryLine: String {
        viewModel.categoryLine
    }

    private func rates(in combination: EarningCombination) -> [StoreEarningRate] {
        viewModel.rates(in: combination)
    }

    private var recommendationDisclosureAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.34, dampingFraction: 0.86)
    }

    private var recommendationExplanationTransition: AnyTransition {
        if accessibilityReduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity
                .combined(with: .move(edge: .top))
                .combined(with: .scale(scale: 0.98, anchor: .top)),
            removal: .opacity
                .combined(with: .scale(scale: 0.98, anchor: .top))
        )
    }

    private func trackStoreDetailOpened() {
        let programIDs = Set(primaryRates.compactMap(\.method.programID))
        environment.track(.init(
            name: "store_detail_opened",
            surface: "store_detail",
            entityType: "store",
            entityID: store.id,
            properties: [
                "program_ids": programIDs.map(\.uuidString).sorted().joined(separator: ","),
                "program_count": "\(programIDs.count)",
                "has_active_campaign": activePromotions.isEmpty ? "false" : "true",
                "has_best_combination": preferredCombination == nil ? "false" : "true",
                "uses_selected_program": preferredCombination.map { viewModel.combinationUsesSelectedPrograms($0) ? "true" : "false" } ?? "false"
            ]
        ))

        if let bestCombination = preferredCombination {
            let bestProgramIDs = Set(rates(in: bestCombination).compactMap(\.method.programID))
            environment.track(.init(
                name: "best_combination_viewed",
                surface: "store_detail",
                entityType: "earning_combination",
                entityID: bestCombination.id,
                properties: [
                    "store_id": store.id.uuidString,
                    "program_ids": bestProgramIDs.map(\.uuidString).sorted().joined(separator: ","),
                    "mechanism_count": "\(bestCombination.rateIDs.count)"
                ]
            ))
        }
    }

    private func toggleFavorite() {
        if isFavorite {
            isFavorite = false
            environment.userSession.favoriteStoreIDs.remove(store.id)
            environment.track(.init(
                name: "favorite_removed",
                surface: "store_detail",
                entityType: "store",
                entityID: store.id,
                properties: ["favorite_type": "store"]
            ))
        } else {
            isFavorite = true
            environment.userSession.favoriteStoreIDs.insert(store.id)
            environment.track(.init(
                name: "favorite_added",
                surface: "store_detail",
                entityType: "store",
                entityID: store.id,
                properties: ["favorite_type": "store"]
            ))
        }
    }
}
