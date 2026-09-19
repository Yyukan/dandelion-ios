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
    let authService = SessionAuthService()
    let catalogViewModel = ModelCatalogViewModel()
    let zenBalanceViewModel: ZenBalanceViewModel
    let goUsageViewModel: GoUsageViewModel
    let refreshCoordinator: RefreshCoordinator

    init() {
        zenBalanceViewModel = ZenBalanceViewModel(appSettings: appSettings)
        goUsageViewModel = GoUsageViewModel()
        refreshCoordinator = RefreshCoordinator(
            appSettings: appSettings,
            catalogViewModel: catalogViewModel,
            zenBalanceViewModel: zenBalanceViewModel,
            goUsageViewModel: goUsageViewModel
        )
    }

    /// Called once `SignInWebView` observes the opencode.ai
    /// `__Host-console_session` cookie - persists it, then immediately
    /// refreshes every card so the newly-signed-in state shows live data
    /// without a second manual pull-to-refresh.
    func finishSignIn(cookieValue: String) async {
        authService.completeSignIn(cookieValue: cookieValue)
        await refreshCoordinator.refreshNow()
    }
}
