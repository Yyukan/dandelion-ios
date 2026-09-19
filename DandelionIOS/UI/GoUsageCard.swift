//
//  GoUsageCard.swift
//  Dandelion
//
//  Live 5h/weekly/monthly Go usage-window ring gauges with reset countdowns,
//  read from OpenCode's official usage API with the API key saved in Settings
//  (no browser session involved) - with the same graceful fallback state when
//  no key is saved or the endpoint fails.
//

import SwiftUI

struct GoUsageCard: View {
    @Bindable var viewModel: GoUsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TerminalTheme.Spacing.sm) {
            HStack {
                Text("Go Usage")
                    .font(TerminalTheme.Fonts.heading)
                Spacer()
                if case .loading = viewModel.state {
                    ProgressView().controlSize(.mini)
                }
            }

            switch viewModel.state {
            case .loading:
                loadingRings
            case .loaded(let summary):
                loadedContent(summary)
            case .unavailable:
                MissingKeyStateView()
            case .sessionExpired:
                SessionExpiredStateView()
            }
        }
        .task { await viewModel.refresh() }
    }

    private var loadingRings: some View {
        HStack(spacing: TerminalTheme.Spacing.lg) {
            RingGaugeView(progress: 0, valueText: "—", label: "5h", size: TerminalTheme.Metrics.primaryRingSize, lineWidth: 3)
            RingGaugeView(progress: 0, valueText: "—", label: "Weekly", size: TerminalTheme.Metrics.primaryRingSize, lineWidth: 3)
            RingGaugeView(progress: 0, valueText: "—", label: "Monthly", size: TerminalTheme.Metrics.primaryRingSize, lineWidth: 3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func loadedContent(_ summary: GoUsageSummary) -> some View {
        VStack(spacing: TerminalTheme.Spacing.sm) {
            HStack(spacing: TerminalTheme.Spacing.lg) {
                usageRing(summary.rolling5h)
                usageRing(summary.weekly)
                usageRing(summary.monthly)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if summary.isUsingZenBalance {
                Text("Go limits reached - now billing from Zen balance")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.warning)
            }
        }
    }

    private func usageRing(_ window: GoUsageWindow) -> some View {
        VStack(spacing: 2) {
            RingGaugeView(
                progress: window.usedPercent / 100,
                valueText: String(format: "%.1f%%", window.usedPercent),
                label: window.label,
                tint: window.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger,
                size: TerminalTheme.Metrics.primaryRingSize,
                lineWidth: 3,
                valueFont: TerminalTheme.Fonts.metricSmall
            )
            Text(Self.countdownText(window.resetsIn))
                .font(TerminalTheme.Fonts.caption)
                .foregroundStyle(TerminalTheme.Colors.textTertiary)
        }
    }

    private static func countdownText(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "resets soon" }
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 60 {
            return "resets \(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        if hours < 24 {
            return "resets \(hours)h"
        }
        return "resets \(hours / 24)d"
    }
}

/// Shown when no Go API key has been saved yet - never blocks the rest of
/// the dashboard, just points at where to create one and paste it.
private struct MissingKeyStateView: View {
    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(progress: 0, valueText: "—", label: "Usage", tint: TerminalTheme.Colors.textTertiary, size: TerminalTheme.Metrics.secondaryRingSize, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Usage unavailable")
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                Text("No OpenCode Go key found - add it in Settings, then refresh.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
                Link("Go setup", destination: URL(string: "https://opencode.ai/docs/go")!)
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.accent)
            }
        }
    }
}

/// Shown when a key was saved but the endpoint rejected it - the key was
/// revoked or rotated and OpenCode Go needs reconnecting.
private struct SessionExpiredStateView: View {
    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(progress: 0, valueText: "—", label: "Usage", tint: TerminalTheme.Colors.textTertiary, size: TerminalTheme.Metrics.secondaryRingSize, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Session expired")
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                Text("Go API key rejected - reconnect OpenCode Go, then refresh.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
                Link("Go setup", destination: URL(string: "https://opencode.ai/docs/go")!)
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.accent)
            }
        }
    }
}

#Preview {
    GoUsageCard(viewModel: GoUsageViewModel())
        .padding()
        .background(TerminalTheme.Colors.background)
}
