//
//  GoUsageCard.swift
//  Dandelion
//
//  Live 5h/weekly/monthly Go usage-window ring gauges with reset countdowns,
//  reusing the same session-cookie storage as ZenBalanceCard - with the same
//  graceful fallback state (with a Sign In button) when no cookie exists yet
//  or the private endpoint fails.
//

import SwiftUI

struct GoUsageCard: View {
    @Bindable var viewModel: GoUsageViewModel
    var onSignIn: () -> Void = {}

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
                SignInPromptView(title: "Usage unavailable", onSignIn: onSignIn)
            case .sessionExpired:
                SessionExpiredStateView(onSignIn: onSignIn)
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
                valueText: "\(Int(window.usedPercent))%",
                label: window.label,
                tint: window.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger,
                size: TerminalTheme.Metrics.primaryRingSize,
                lineWidth: 3
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

/// Shown when a cookie was found but the endpoint no longer recognizes it -
/// most likely the OpenCode session has expired and needs a fresh sign-in.
private struct SessionExpiredStateView: View {
    var onSignIn: () -> Void

    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(progress: 0, valueText: "—", label: "—", tint: TerminalTheme.Colors.textTertiary, size: TerminalTheme.Metrics.secondaryRingSize, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Session expired")
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                Text("Please sign in again to refresh live data.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
                Button("Sign In", action: onSignIn)
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.accent)
            }
        }
    }
}

#Preview {
    GoUsageCard(viewModel: GoUsageViewModel(appSettings: AppSettings()))
        .padding()
        .background(TerminalTheme.Colors.background)
}
