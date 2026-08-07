//
//  ModelCatalogViewModel.swift
//  Dandelion
//
//  Drives ModelCatalogView: loads the merged Zen + Go pricing/limit catalog.
//  There's no local API key to discover/validate first - models.dev's
//  catalog is public data, so the catalog just loads directly on appearance.
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
            result.sort { $0.displayName < $1.displayName }
        case .priceAscending:
            result.sort { $0.pricing.inputPerM < $1.pricing.inputPerM }
        case .priceDescending:
            result.sort { $0.pricing.inputPerM > $1.pricing.inputPerM }
        case .usageLimitAscending:
            result.sort { ($0.usageLimits?.requestsPerMonth ?? 0) < ($1.usageLimits?.requestsPerMonth ?? 0) }
        case .usageLimitDescending:
            result.sort { ($0.usageLimits?.requestsPerMonth ?? 0) > ($1.usageLimits?.requestsPerMonth ?? 0) }
        }

        return result
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
