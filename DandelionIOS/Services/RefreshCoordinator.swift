//
//  RefreshCoordinator.swift
//  Dandelion
//
//  Orchestrates catalog/balance/usage fetches in parallel via a TaskGroup,
//  exposing manual pull-to-refresh and a configurable Auto-Refresh timer
//  backed by AppSettings. There's no credential discovery/validation step
//  here - the model catalog needs no API key at all (see
//  ModelCatalogViewModel). After every refresh it also writes a
//  WidgetUsageSnapshot to the shared App Group container and reloads the
//  Lock Screen widgets' timelines - they never fetch data on their own.
//

import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class RefreshCoordinator {
    private(set) var isRefreshing = false
    private(set) var lastRefreshDate: Date?

    private let appSettings: AppSettings
    private let catalogViewModel: ModelCatalogViewModel
    private let zenBalanceViewModel: ZenBalanceViewModel
    private let goUsageViewModel: GoUsageViewModel
    private let widgetSnapshotStore: WidgetSnapshotStore

    private var autoRefreshTask: Task<Void, Never>?
    private var runningRefreshTask: Task<Void, Never>?
    private var refreshRequestedAgain = false

    init(
        appSettings: AppSettings,
        catalogViewModel: ModelCatalogViewModel,
        zenBalanceViewModel: ZenBalanceViewModel,
        goUsageViewModel: GoUsageViewModel,
        widgetSnapshotStore: WidgetSnapshotStore = WidgetSnapshotStore()
    ) {
        self.appSettings = appSettings
        self.catalogViewModel = catalogViewModel
        self.zenBalanceViewModel = zenBalanceViewModel
        self.goUsageViewModel = goUsageViewModel
        self.widgetSnapshotStore = widgetSnapshotStore

        if appSettings.autoRefreshEnabled {
            scheduleAutoRefresh()
        }
    }

    /// Runs the (cache-respecting) catalog refresh, the live Zen balance and
    /// the live Go usage fetch all in parallel. A call made while a refresh
    /// is already in flight never triggers a second, overlapping fetch - but
    /// it's never silently dropped either: it schedules exactly one more
    /// pass right after the current one finishes, so state that changed
    /// mid-flight (e.g. a session cookie captured by sign-in) is always
    /// picked up by the very next completed refresh.
    func refreshNow() async {
        if let runningRefreshTask {
            refreshRequestedAgain = true
            await runningRefreshTask.value
            return
        }

        repeat {
            refreshRequestedAgain = false
            let task = Task { await performRefresh() }
            runningRefreshTask = task
            await task.value
        } while refreshRequestedAgain
        runningRefreshTask = nil
    }

    private func performRefresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [catalogViewModel] in await catalogViewModel.refreshCatalog() }
            group.addTask { [zenBalanceViewModel] in await zenBalanceViewModel.refresh() }
            group.addTask { [goUsageViewModel] in await goUsageViewModel.refresh() }
        }

        lastRefreshDate = Date()

        widgetSnapshotStore.save(buildWidgetSnapshot())
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Builds the Lock Screen widgets' cached snapshot from whatever the two
    /// view models just settled on - `nil` percentages (the `.empty` default)
    /// stick around for `.unavailable`/`.sessionExpired`/`.loading`, so the
    /// widgets fall back to an empty gauge instead of showing stale numbers.
    private func buildWidgetSnapshot() -> WidgetUsageSnapshot {
        var snapshot = WidgetUsageSnapshot.empty
        snapshot.fetchedAt = Date()

        if case .loaded(let balance) = zenBalanceViewModel.state {
            snapshot.balancePercent = balance.progressFraction * 100
            snapshot.balanceUSD = balance.currentUSD
            snapshot.isBalanceHealthy = balance.isHealthy
        }

        if case .loaded(let summary) = goUsageViewModel.state {
            snapshot.hourPercent = summary.rolling5h.usedPercent
            snapshot.isHourHealthy = summary.rolling5h.isHealthy
            snapshot.weeklyPercent = summary.weekly.usedPercent
            snapshot.isWeeklyHealthy = summary.weekly.isHealthy
            snapshot.monthlyPercent = summary.monthly.usedPercent
            snapshot.isMonthlyHealthy = summary.monthly.isHealthy
        }

        return snapshot
    }

    func setAutoRefreshEnabled(_ enabled: Bool) {
        appSettings.autoRefreshEnabled = enabled
        if enabled {
            scheduleAutoRefresh()
        } else {
            autoRefreshTask?.cancel()
            autoRefreshTask = nil
        }
    }

    func setAutoRefreshInterval(_ interval: TimeInterval) {
        appSettings.autoRefreshInterval = interval
        if appSettings.autoRefreshEnabled {
            scheduleAutoRefresh()
        }
    }

    private func scheduleAutoRefresh() {
        autoRefreshTask?.cancel()
        let interval = appSettings.autoRefreshInterval
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.refreshNow()
            }
        }
    }
}
