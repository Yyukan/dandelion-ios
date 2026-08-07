//
//  BalanceWidget.swift
//  DandelionWidget
//
//  Lock Screen complication showing the Zen pay-as-you-go balance as a
//  percentage of its reference ceiling (see ZenBalance.progressFraction).
//  Tapping it opens Dandelion.
//

import SwiftUI
import WidgetKit

struct BalanceWidget: Widget {
    let kind = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PercentTimelineProvider(percentKeyPath: \.balancePercent, healthKeyPath: \.isBalanceHealthy)
        ) { entry in
            LockScreenGaugeView(
                progress: entry.progress,
                tint: entry.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.warning
            )
            .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Balance")
        .description("Zen pay-as-you-go balance, as a percentage.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    BalanceWidget()
} timeline: {
    WidgetPercentEntry(date: .now, percent: 72, isHealthy: true)
}
