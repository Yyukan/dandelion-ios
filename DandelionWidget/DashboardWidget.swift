//
//  DashboardWidget.swift
//  DandelionWidget
//
//  Home Screen (`.systemSmall`) widget showing all four metrics - Zen
//  balance + the three Go usage windows - in a 2x2 grid of ring gauges.
//  Reuses `RingGaugeView` from DandelionShared so it matches the in-app
//  cards. Reads the same `WidgetUsageSnapshot` as the Lock Screen
//  widgets, never fetches.
//

import SwiftUI
import WidgetKit

/// Reads the full `WidgetUsageSnapshot` rather than one metric - needed
/// because the dashboard renders all four. One entry, `.never` policy,
/// app drives updates via `WidgetCenter.shared.reloadAllTimelines()`.
struct WidgetSnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetUsageSnapshot
}

struct WidgetSnapshotProvider: TimelineProvider {
    typealias Entry = WidgetSnapshotEntry

    let store: WidgetSnapshotStore

    init(store: WidgetSnapshotStore = WidgetSnapshotStore()) {
        self.store = store
    }

    func placeholder(in context: Context) -> WidgetSnapshotEntry {
        WidgetSnapshotEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetSnapshotEntry) -> Void) {
        completion(WidgetSnapshotEntry(date: .now, snapshot: store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetSnapshotEntry>) -> Void) {
        completion(Timeline(entries: [WidgetSnapshotEntry(date: .now, snapshot: store.load())], policy: .never))
    }
}

struct DashboardWidget: Widget {
    let kind = "DashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WidgetSnapshotProvider()
        ) { entry in
            DashboardView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { TerminalTheme.Colors.background }
                .widgetURL(URL(string: "dandelion://open"))
        }
        .configurationDisplayName("Dandelion")
        .description("Zen balance and Go usage, all in one view.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    DashboardWidget()
} timeline: {
    WidgetSnapshotEntry(date: .now, snapshot: .empty)
    WidgetSnapshotEntry(
        date: .now,
        snapshot: {
            var s = WidgetUsageSnapshot.empty
            s.balanceUSD = 9.09
            s.balancePercent = 45
            s.hourPercent = 1
            s.weeklyPercent = 36
            s.monthlyPercent = 32
            s.isBalanceHealthy = true
            s.isHourHealthy = true
            s.isWeeklyHealthy = true
            s.isMonthlyHealthy = true
            return s
        }()
    )
}
