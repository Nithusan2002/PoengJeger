import Foundation

struct StoreDetailViewModel {
    let store: Store
    let selectedProgramIDs: Set<UUID>

    var publishedRates: [StoreEarningRate] {
        store.sortedEarningRates.filter { $0.status == .published }
    }

    var preferredCombination: EarningCombination? {
        store.bestCombination(for: selectedProgramIDs)
    }

    var primaryRates: [StoreEarningRate] {
        guard !selectedProgramIDs.isEmpty else { return publishedRates }
        let selectedRates = publishedRates.filter { $0.matchesSelectedPrograms(selectedProgramIDs) }
        return selectedRates.isEmpty ? publishedRates : selectedRates
    }

    var activePromotions: [StoreEarningRate] {
        primaryRates
            .filter { !$0.isBaseRate && $0.isActive }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var baseContextRates: [StoreEarningRate] {
        primaryRates
            .filter(\.isBaseRate)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var displayedBaseContextRates: [StoreEarningRate] {
        guard let preferredCombination else { return baseContextRates }
        let includedRates = rates(in: preferredCombination)
        let addsToBaseRate = preferredCombination.rateIDs.count > 1 || includedRates.contains { !$0.isBaseRate }
        return addsToBaseRate ? baseContextRates : []
    }

    var otherAvailableRates: [StoreEarningRate] {
        let selectedRateIDs = Set(preferredCombination?.rateIDs ?? [])
        let contextualRateIDs = selectedRateIDs.union(Set(displayedBaseContextRates.map(\.id)))

        return (primaryRates + secondaryRates)
            .reduce(into: [StoreEarningRate]()) { result, rate in
                guard !contextualRateIDs.contains(rate.id), !result.contains(where: { $0.id == rate.id }) else {
                    return
                }
                result.append(rate)
            }
    }

    var categoryLine: String {
        store.category?.name ?? "Butikk"
    }

    func rates(in combination: EarningCombination) -> [StoreEarningRate] {
        combination.rateIDs.compactMap { rateID in
            store.earningRates.first { $0.id == rateID && $0.status == .published }
        }
    }

    func combinationUsesSelectedPrograms(_ combination: EarningCombination) -> Bool {
        guard !selectedProgramIDs.isEmpty else { return true }
        let programIDs = Set(rates(in: combination).compactMap(\.method.programID))
        return !programIDs.isEmpty && programIDs.isSubset(of: selectedProgramIDs)
    }

    func expiryText(for rates: [StoreEarningRate]) -> String? {
        guard let firstExpiry = rates.compactMap(\.endsAt).min() else { return nil }
        return "Gyldig til \(shortDate(firstExpiry))"
    }

    func sourceDestinationName(for url: URL) -> String {
        let host = url.host()?.localizedLowercase ?? ""
        if host.contains("trumf") {
            return "Trumf"
        }
        if host.contains("sas") || host.contains("eurobonus") {
            return "EuroBonus Shopping"
        }
        return url.host() ?? "Kilde"
    }

    func handoffDestinationName(for combination: EarningCombination) -> String {
        guard let url = combination.primaryHandoffURL else { return "riktig portal" }

        if let matchingRate = store.earningRates.first(where: { $0.handoffURL == url }) {
            return matchingRate.method.name
        }

        return sourceDestinationName(for: url)
    }

    func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .locale(Locale(identifier: "nb_NO"))
        )
    }

    private var secondaryRates: [StoreEarningRate] {
        guard !selectedProgramIDs.isEmpty else { return [] }
        return publishedRates.filter { !$0.matchesSelectedPrograms(selectedProgramIDs) }
    }
}
