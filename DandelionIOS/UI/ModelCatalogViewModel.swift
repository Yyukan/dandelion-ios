//
//  ModelCatalogViewModel.swift
//  Dandelion
//
//  Drives ModelCatalogView: loads the merged Zen + Go pricing/limit catalog.
//  There's no local API key to discover/validate first - the catalog comes
//  from OpenCode's own public endpoints and docs pages, so it just loads
//  directly on appearance.
//

import Foundation
import Observation

enum CatalogSortOption: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case priceAscending = "Price ascending"
    case priceDescending = "Price descending"
    case usageLimitAscending = "Usage limit ascending"
    case usageLimitDescending = "Usage limit descending"

    var id: String { rawValue }

    /// Compact glyph shown in the sort picker instead of a text label - an
    /// arrow direction plus a `$`/`#` marker so price and usage-limit sorts
    /// (which'd otherwise share the same bare arrow) stay distinguishable.
    var shortLabel: String {
        switch self {
        case .name: "Aa"
        case .priceAscending: "↑$"
        case .priceDescending: "↓$"
        case .usageLimitAscending: "↑#"
        case .usageLimitDescending: "↓#"
        }
    }
}

@MainActor
@Observable
final class ModelCatalogViewModel {
    private(set) var models: [CatalogModel] = []
    private(set) var isLoadingCatalog = false

    var searchText: String = ""
    var providerFilter: CatalogProvider = .zen {
        didSet {
            guard !availableSortOptions.contains(sortOption) else { return }
            sortOption = .name
        }
    }
    var sortOption: CatalogSortOption = .name

    /// Usage-limit sorting only makes sense for Go (Zen models never carry
    /// `usageLimits`), so hide those options unless Go is the active filter.
    var availableSortOptions: [CatalogSortOption] {
        switch providerFilter {
        case .zen: [.name, .priceAscending, .priceDescending]
        case .go: CatalogSortOption.allCases
        }
    }

    private let catalogService: ModelCatalogService

    init(catalogService: ModelCatalogService = ModelCatalogService()) {
        self.catalogService = catalogService
    }

    var filteredModels: [CatalogModel] {
        var result = models.filter { $0.provider == providerFilter }

        if !searchText.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
                    || $0.modelID.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .name:
            result.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .priceAscending:
            result.sort { isOrdered($0.pricing.inputPerM, $1.pricing.inputPerM, ascending: true, lhs: $0, rhs: $1) }
        case .priceDescending:
            result.sort { isOrdered($0.pricing.inputPerM, $1.pricing.inputPerM, ascending: false, lhs: $0, rhs: $1) }
        case .usageLimitAscending:
            result.sort { isOrdered($0.usageLimits?.requestsPerMonth, $1.usageLimits?.requestsPerMonth, ascending: true, lhs: $0, rhs: $1) }
        case .usageLimitDescending:
            result.sort { isOrdered($0.usageLimits?.requestsPerMonth, $1.usageLimits?.requestsPerMonth, ascending: false, lhs: $0, rhs: $1) }
        }

        return result
    }

    /// Orders two optional sort keys, keeping models without a published price
    /// or usage limit at the bottom of the list in both directions, and
    /// breaking ties (and the "no value" case) by name.
    private func isOrdered<T: Comparable>(
        _ lhsKey: T?,
        _ rhsKey: T?,
        ascending: Bool,
        lhs: CatalogModel,
        rhs: CatalogModel
    ) -> Bool {
        switch (lhsKey, rhsKey) {
        case let (l?, r?):
            guard l != r else { return nameComesFirst(lhs, rhs) }
            return ascending ? l < r : l > r
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return nameComesFirst(lhs, rhs)
        }
    }

    private func nameComesFirst(_ lhs: CatalogModel, _ rhs: CatalogModel) -> Bool {
        lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }

    func loadInitial() async {
        await refreshCatalog()
    }

    func refreshCatalog(forceRefresh: Bool = false) async {
        isLoadingCatalog = true
        defer { isLoadingCatalog = false }
        models = await catalogService.loadCatalog(forceRefresh: forceRefresh)
    }
}
