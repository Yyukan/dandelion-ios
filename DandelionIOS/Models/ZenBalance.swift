//
//  ZenBalance.swift
//  Dandelion
//
//  Live Zen pay-as-you-go balance, as surfaced by the private workspace
//  billing page (no public REST API exposes this - see UsageService).
//

import Foundation

/// Current Zen account balance plus auto-reload/monthly-limit context, all
/// read straight from the OpenCode Zen web dashboard.
struct ZenBalance: Sendable, Equatable {
    /// Current pay-as-you-go credit balance, in US dollars.
    let currentUSD: Double
    /// Whether auto-reload is currently configured/enabled on the account.
    let autoReloadEnabled: Bool
    /// Balance level (in USD) that triggers an auto-reload, if enabled.
    let autoReloadThresholdUSD: Double
    /// Amount (in USD) added back to the balance on an auto-reload.
    let autoReloadAmountUSD: Double
    /// Optional monthly spend cap the user configured on the workspace.
    let monthlyLimitUSD: Double?
    /// Spend so far in the current calendar month, in US dollars.
    let monthlyUsageUSD: Double?

    /// Balance as a 0...1 fraction of its reference ceiling - the monthly
    /// limit if one is configured, else the auto-reload amount. Single
    /// source of truth shared by ZenBalanceCard and the Lock Screen widget
    /// snapshot, so both render the exact same percentage.
    var progressFraction: Double {
        if let monthlyLimit = monthlyLimitUSD, monthlyLimit > 0 {
            return currentUSD / monthlyLimit
        }
        // With no configured monthly limit, show progress toward the
        // auto-reload amount as a reasonable reference ceiling.
        guard autoReloadAmountUSD > 0 else { return 1 }
        return currentUSD / autoReloadAmountUSD
    }

    /// `false` once the balance has dropped to/below its auto-reload
    /// threshold - mirrors the warning tint shown in ZenBalanceCard.
    var isHealthy: Bool {
        currentUSD > autoReloadThresholdUSD
    }
}
