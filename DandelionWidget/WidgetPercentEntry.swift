//
//  WidgetPercentEntry.swift
//  DandelionWidget
//
//  Common Lock Screen widget entry - a single percentage + health flag,
//  read once per metric from the cached WidgetUsageSnapshot. No other
//  fields, since each gauge shows nothing but its own percentage.
//

import WidgetKit

struct WidgetPercentEntry: TimelineEntry {
    let date: Date
    /// 0...100; `nil` maps to an empty 0% gauge (signed out / no data yet).
    let percent: Double?
    let isHealthy: Bool
    /// Optional override for the centre label - the Balance widget uses
    /// this to show the raw USD balance instead of the percent. `nil`
    /// means fall back to formatting `progress` as a percentage.
    let valueLabel: String?

    var progress: Double { (percent ?? 0) / 100 }

    init(date: Date, percent: Double?, isHealthy: Bool, valueLabel: String? = nil) {
        self.date = date
        self.percent = percent
        self.isHealthy = isHealthy
        self.valueLabel = valueLabel
    }
}

/// One shared TimelineProvider implementation, parametrized per metric via
/// key paths into WidgetUsageSnapshot - avoids 4 near-identical provider
/// types. Never fetches network data or touches the Keychain: it only reads
/// whatever WidgetSnapshotStore has cached, and serves a single entry with
/// `.never` refresh policy - the app itself drives updates by calling
/// WidgetCenter.shared.reloadAllTimelines() after every refresh.
struct PercentTimelineProvider: TimelineProvider {
    typealias Entry = WidgetPercentEntry

    let percentKeyPath: KeyPath<WidgetUsageSnapshot, Double?>
    let healthKeyPath: KeyPath<WidgetUsageSnapshot, Bool>
    /// Optional closure to derive a custom centre label from the snapshot
    /// (e.g. format `balanceUSD` as a dollar string). Defaults to nil -
    /// other widgets use the default percent label.
    let valueLabel: ((WidgetUsageSnapshot) -> String?)?
    let store: WidgetSnapshotStore

    init(
        percentKeyPath: KeyPath<WidgetUsageSnapshot, Double?>,
        healthKeyPath: KeyPath<WidgetUsageSnapshot, Bool>,
        valueLabel: ((WidgetUsageSnapshot) -> String?)? = nil,
        store: WidgetSnapshotStore = WidgetSnapshotStore()
    ) {
        self.percentKeyPath = percentKeyPath
        self.healthKeyPath = healthKeyPath
        self.valueLabel = valueLabel
        self.store = store
    }

    /// Reads the same real cached snapshot as `currentEntry()` rather than a
    /// hardcoded generic value - otherwise every widget kind would render an
    /// identical placeholder percentage (e.g. while arranging widgets on the
    /// Lock Screen customization screen), instead of its own metric.
    func placeholder(in context: Context) -> WidgetPercentEntry {
        currentEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetPercentEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetPercentEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> WidgetPercentEntry {
        let snapshot = store.load()
        return WidgetPercentEntry(
            date: .now,
            percent: snapshot[keyPath: percentKeyPath],
            isHealthy: snapshot[keyPath: healthKeyPath],
            valueLabel: valueLabel?(snapshot)
        )
    }
}
