//
//  GoUsageWindow.swift
//  Dandelion
//
//  Live OpenCode Go subscription usage windows, surfaced by OpenCode's
//  official API-key-authenticated usage endpoint (see UsageService).
//

import Foundation

/// One Go usage-window reading (5h rolling / weekly / monthly).
struct GoUsageWindow: Sendable, Equatable {
    let label: String
    /// Already a 0...100 percentage, as reported by the endpoint.
    let usedPercent: Double
    let resetsIn: TimeInterval
    /// `false` when the window itself reports a non-"ok" status (e.g. exceeded).
    let isHealthy: Bool
}

/// The full set of Go usage windows for an account.
struct GoUsageSummary: Sendable, Equatable {
    let rolling5h: GoUsageWindow
    let weekly: GoUsageWindow
    let monthly: GoUsageWindow
}
