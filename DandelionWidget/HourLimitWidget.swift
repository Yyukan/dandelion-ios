//
//  HourLimitWidget.swift
//  DandelionWidget
//
//  Lock Screen complication showing Go's rolling 5h usage window as a
//  percentage (GoUsageSummary.rolling5h.usedPercent). Tapping it opens
//  Dandelion.
//

import SwiftUI
import WidgetKit

struct HourLimitWidget: Widget {
    let kind = "HourLimitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PercentTimelineProvider(percentKeyPath: \.hourPercent, healthKeyPath: \.isHourHealthy)
        ) { entry in
            LockScreenGaugeView(
                progress: entry.progress,
                tint: entry.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger
            )
            .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Hour Limit")
        .description("Go's rolling 5h usage window, as a percentage.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    HourLimitWidget()
} timeline: {
    WidgetPercentEntry(date: .now, percent: 40, isHealthy: true)
}
