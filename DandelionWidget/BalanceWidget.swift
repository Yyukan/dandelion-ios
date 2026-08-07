//
//  BalanceWidget.swift
//  DandelionWidget
//
//  Lock Screen complication showing the Zen pay-as-you-go balance. The ring
//  fill is `progressFraction` (currentUSD / reference ceiling) as a
//  quick at-a-glance ratio; the centre label is the raw USD balance -
//  not the percent - because that's what the user actually wants to read.
//  Tapping it opens Dandelion.
//

import SwiftUI
import WidgetKit

struct BalanceWidget: Widget {
    let kind = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PercentTimelineProvider(
                percentKeyPath: \.balancePercent,
                healthKeyPath: \.isBalanceHealthy,
                valueLabel: { snapshot in
                    snapshot.balanceUSD.map { formatBalance($0) }
                }
            )
        ) { entry in
            LockScreenGaugeView(
                progress: entry.progress,
                valueLabel: entry.valueLabel,
                tint: entry.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.warning
            )
            .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Balance")
        .description("Zen pay-as-you-go balance, in US dollars.")
        .supportedFamilies([.accessoryCircular])
    }
}

/// Short enough to fit inside the `accessoryCircular` Lock Screen ring
/// (~5-6 chars at the default complication size). Shows two decimals so
/// $0.42 / $1.05 are still readable, and renders "—" when no data has
/// been fetched yet (signed out, before first refresh).
private func formatBalance(_ usd: Double) -> String {
    guard usd.isFinite else { return "—" }
    let prefix = usd < 0 ? "-" : ""
    let abs = Swift.abs(usd)
    return "\(prefix)$\(String(format: "%.2f", abs))"
}

#Preview(as: .accessoryCircular) {
    BalanceWidget()
} timeline: {
    WidgetPercentEntry(date: .now, percent: 72, isHealthy: true, valueLabel: "$12.50")
    WidgetPercentEntry(date: .now, percent: 0, isHealthy: false, valueLabel: "$0.42")
}
