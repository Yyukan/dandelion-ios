//
//  ZenBalanceViewModel.swift
//  Dandelion
//
//  Drives ZenBalanceCard from the console's billing JSON API, authenticated
//  with the API key saved in Settings - no browser session, no cookie -
//  degrading gracefully when no key exists yet or the endpoint fails.
//

import Foundation
import Observation

/// Load state for the live Zen balance widget.
enum ZenBalanceState: Equatable {
    case loading
    case loaded(ZenBalance)
    /// No API key has been saved yet - show "—" and point at Settings.
    case needsKey
    /// A key was found, but the console rejected it - revoked or rotated.
    case unauthorized
    /// No credential problem: the request failed or the payload was unusable.
    case unavailable
}

@MainActor
@Observable
final class ZenBalanceViewModel {
    private(set) var state: ZenBalanceState = .loading

    private let usageService: UsageService

    init(usageService: UsageService = UsageService()) {
        self.usageService = usageService
    }

    func refresh() async {
        state = .loading

        do {
            state = .loaded(try await usageService.fetchZenBalance())
        } catch let error as UsageServiceError {
            switch error {
            case .missingAPIKey:
                state = .needsKey
            case .unauthorized:
                state = .unauthorized
            case .balanceNotFound, .usageNotFound, .network:
                state = .unavailable
            }
        } catch {
            state = .unavailable
        }
    }
}
