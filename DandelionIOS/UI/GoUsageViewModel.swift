//
//  GoUsageViewModel.swift
//  Dandelion
//
//  Drives GoUsageCard: reuses the same session-cookie storage as the Zen
//  balance widget to fetch the live 5h/weekly/monthly usage windows.
//

import Foundation
import Observation

/// Load state for the live Go usage widget.
enum GoUsageState: Equatable {
    case loading
    case loaded(GoUsageSummary)
    /// No session cookie has been captured yet - show "—" + a Sign In
    /// button instead of crashing or blocking the rest of the UI.
    case unavailable
    /// A cookie was found, but the endpoint no longer recognizes it - most
    /// likely the OpenCode session has expired and needs a fresh sign-in.
    case sessionExpired
}

@MainActor
@Observable
final class GoUsageViewModel {
    private(set) var state: GoUsageState = .loading

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
            let usage = try await usageService.fetchGoUsage(
                cookie: cookie,
                workspaceIDOverride: workspaceOverride.isEmpty ? nil : workspaceOverride
            )
            state = .loaded(usage)
        } catch let error as UsageServiceError {
            switch error {
            case .workspaceNotFound, .goUsageNotFound:
                // A cookie was found, but the authenticated page couldn't be
                // parsed - the most likely cause is that the OpenCode
                // session behind it has since expired.
                state = .sessionExpired
            case .balanceNotFound, .network:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }
}
