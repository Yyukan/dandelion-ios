//
//  AppModel.swift
//  Dandelion
//
//  Owns the shared settings/services/view models for the whole app lifetime.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let appSettings = AppSettings()
    let catalogViewModel = ModelCatalogViewModel()
    let zenBalanceViewModel: ZenBalanceViewModel
    let goUsageViewModel: GoUsageViewModel
    let refreshCoordinator: RefreshCoordinator

    init() {
        zenBalanceViewModel = ZenBalanceViewModel()
        goUsageViewModel = GoUsageViewModel()
        refreshCoordinator = RefreshCoordinator(
            appSettings: appSettings,
            catalogViewModel: catalogViewModel,
            zenBalanceViewModel: zenBalanceViewModel,
            goUsageViewModel: goUsageViewModel
        )
    }
}
