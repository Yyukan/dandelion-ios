//
//  WeeklyLimitWidget.swift
//  DandelionWidget
//
//  Lock Screen complication showing Go's weekly usage window as a
//  percentage (GoUsageSummary.weekly.usedPercent). Tapping it opens
//  Dandelion.
//

import SwiftUI
import WidgetKit

struct WeeklyLimitWidget: Widget {
    let kind = "WeeklyLimitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PercentTimelineProvider(percentKeyPath: \.weeklyPercent, healthKeyPath: \.isWeeklyHealthy)
        ) { entry in
            LockScreenGaugeView(
                progress: entry.progress,
                tint: entry.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger
            )
            .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Weekly Limit")
        .description("Go's weekly usage window, as a percentage.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    WeeklyLimitWidget()
} timeline: {
    WidgetPercentEntry(date: .now, percent: 55, isHealthy: true)
}
