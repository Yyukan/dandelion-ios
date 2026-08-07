//
//  WidgetSnapshotStore.swift
//  Dandelion
//
//  Encodes/decodes WidgetUsageSnapshot to the App Group's shared
//  UserDefaults container - the only channel the widget extension and the
//  main app communicate through, so the extension never needs its own
//  network/Keychain access. Shared source, target-membership in both
//  DandelionIOS and DandelionWidgetExtension.
//

import Foundation

struct WidgetSnapshotStore {
    static let appGroupID = "group.nl.ostconsultancy.Dandelion"

    private static let key = "widgetUsageSnapshot"

    private let defaults: UserDefaults?

    init(appGroupID: String = WidgetSnapshotStore.appGroupID) {
        self.defaults = UserDefaults(suiteName: appGroupID)
    }

    /// Returns `.empty` when signed out, before first refresh, or when the
    /// App Group container itself can't be opened - never throws/crashes.
    func load() -> WidgetUsageSnapshot {
        guard let data = defaults?.data(forKey: Self.key),
              let snapshot = try? JSONDecoder().decode(WidgetUsageSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }

    func save(_ snapshot: WidgetUsageSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: Self.key)
    }

    /// Called on sign-out so stale, pre-sign-out percentages never linger
    /// on the Lock Screen.
    func clear() {
        defaults?.removeObject(forKey: Self.key)
    }
}
