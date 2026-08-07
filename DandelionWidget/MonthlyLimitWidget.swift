//
//  MonthlyLimitWidget.swift
//  DandelionWidget
//
//  Lock Screen complication showing Go's monthly usage window as a
//  percentage (GoUsageSummary.monthly.usedPercent). Tapping it opens
//  Dandelion.
//

import SwiftUI
import WidgetKit

struct MonthlyLimitWidget: Widget {
    let kind = "MonthlyLimitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PercentTimelineProvider(percentKeyPath: \.monthlyPercent, healthKeyPath: \.isMonthlyHealthy)
        ) { entry in
            LockScreenGaugeView(
                progress: entry.progress,
                tint: entry.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger
            )
            .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Monthly Limit")
        .description("Go's monthly usage window, as a percentage.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    MonthlyLimitWidget()
} timeline: {
    WidgetPercentEntry(date: .now, percent: 30, isHealthy: true)
}
