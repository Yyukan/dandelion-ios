//
//  ZenBalanceViewModel.swift
//  Dandelion
//
//  Drives ZenBalanceCard: reads the session cookie captured by
//  SessionAuthService's in-app sign-in and uses it to fetch the live Zen
//  balance, degrading gracefully when no cookie exists yet or the private
//  endpoint fails.
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
    /// A cookie was found, but the endpoint no longer recognizes it - most
    /// likely the OpenCode session has expired and needs a fresh sign-in.
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
            case .workspaceNotFound, .balanceNotFound:
                // A cookie was found, but the authenticated page couldn't be
                // parsed - the most likely cause is that the OpenCode
                // session behind it has since expired.
                state = .sessionExpired
            case .goUsageNotFound, .network:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }
}
