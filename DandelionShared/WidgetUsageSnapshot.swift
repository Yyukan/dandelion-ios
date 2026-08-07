//
//  WidgetUsageSnapshot.swift
//  Dandelion
//
//  Tiny, already-computed snapshot the main app writes after every refresh
//  (see RefreshCoordinator) and the Lock Screen widgets read back - no
//  cookie/PII, just percentages, so the widget extension never needs its
//  own network/Keychain access. Shared source, target-membership in both
//  DandelionIOS and DandelionWidgetExtension.
//

import Foundation

/// Written by the app after every refresh; read-only from the widget extension.
struct WidgetUsageSnapshot: Codable, Sendable, Equatable {
    /// `nil` means signed out / no data fetched yet - widgets render a 0% gauge.
    var balancePercent: Double?
    var hourPercent: Double?
    var weeklyPercent: Double?
    var monthlyPercent: Double?
    var isBalanceHealthy: Bool
    var isHourHealthy: Bool
    var isWeeklyHealthy: Bool
    var isMonthlyHealthy: Bool
    var fetchedAt: Date

    /// The "nothing to show yet" snapshot - signed out, or before first refresh.
    static let empty = WidgetUsageSnapshot(
        balancePercent: nil,
        hourPercent: nil,
        weeklyPercent: nil,
        monthlyPercent: nil,
        isBalanceHealthy: true,
        isHourHealthy: true,
        isWeeklyHealthy: true,
        isMonthlyHealthy: true,
        fetchedAt: .distantPast
    )
}
