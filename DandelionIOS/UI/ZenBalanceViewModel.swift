//
//  ZenBalanceViewModel.swift
//  Dandelion
//
//  Drives ZenBalanceCard: reads the `__Host-console_session` cookie captured
//  by SessionAuthService's in-app sign-in and uses it against the OpenCode
//  console's billing JSON API, degrading gracefully when no cookie exists yet
//  or the endpoint fails.
//

import Foundation
import Observation

/// Load state for the live Zen balance widget.
enum ZenBalanceState: Equatable {
    case loading
    case loaded(ZenBalance)
    /// No session cookie has been captured yet - show "—" + a Sign In
    /// button instead of crashing or blocking the rest of the UI.
    case unavailable
    /// A cookie was found, but the console rejected it or its payload was
    /// unusable - most likely the console session has expired and needs a
    /// fresh sign-in.
    case sessionExpired
}

@MainActor
@Observable
final class ZenBalanceViewModel {
    private(set) var state: ZenBalanceState = .loading

    private let cookieStore: SessionCookieStore
    private let usageService: UsageService
    private let appSettings: AppSettings

    init(
        appSettings: AppSettings,
        cookieStore: SessionCookieStore = SessionCookieStore(),
        usageService: UsageService = UsageService()
    ) {
        self.appSettings = appSettings
        self.cookieStore = cookieStore
        self.usageService = usageService
    }

    func refresh() async {
        state = .loading

        guard let cookieValue = cookieStore.load() else {
            state = .unavailable
            return
        }
        let cookie = SessionCookie(value: cookieValue)

        do {
            let workspaceOverride = appSettings.manualWorkspaceID
            let balance = try await usageService.fetchZenBalance(
                cookie: cookie,
                workspaceIDOverride: workspaceOverride.isEmpty ? nil : workspaceOverride
            )
            state = .loaded(balance)
        } catch let error as UsageServiceError {
            switch error {
            case .workspaceNotFound, .balanceNotFound, .sessionExpired:
                // A cookie was found, but the console rejected it or its
                // payload was unusable - the most likely cause is that the
                // console session behind it has since expired.
                state = .sessionExpired
            case .goUsageNotFound, .missingGoAPIKey, .network:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }
}
