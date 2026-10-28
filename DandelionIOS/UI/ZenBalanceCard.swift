//
//  ZenBalanceCard.swift
//  Dandelion
//
//  Live Zen balance ring, auto-reload threshold and monthly limit info, fed
//  by the console's billing API with the API key saved in Settings - with a
//  graceful fallback state when no key exists yet, the key is rejected, or the
//  request fails.
//

import SwiftUI

struct ZenBalanceCard: View {
    @Bindable var viewModel: ZenBalanceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TerminalTheme.Spacing.sm) {
            HStack {
                Text("Zen Balance")
                    .font(TerminalTheme.Fonts.heading)
                Spacer()
                if case .loading = viewModel.state {
                    ProgressView().controlSize(.mini)
                }
            }

            switch viewModel.state {
            case .loading:
                RingGaugeView(progress: 0, valueText: "—", label: "Balance", size: TerminalTheme.Metrics.primaryRingSize, lineWidth: 3)
                    .frame(maxWidth: .infinity, alignment: .center)
            case .loaded(let balance):
                loadedContent(balance)
            case .needsKey:
                FallbackStateView(
                    title: "Balance unavailable",
                    detail: "No API key saved. Tap this card to open Settings and paste one."
                )
            case .unauthorized:
                FallbackStateView(
                    title: "API key rejected",
                    detail: "OpenCode refused the saved key. Replace it in Settings, then refresh."
                )
            case .unavailable:
                FallbackStateView(
                    title: "Balance unavailable",
                    detail: "Couldn't reach the console. Pull to refresh to try again."
                )
            }
        }
        .task { await viewModel.refresh() }
    }

    private func loadedContent(_ balance: ZenBalance) -> some View {
        VStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(
                progress: balance.progressFraction,
                valueText: "$" + String(format: "%.2f", balance.currentUSD),
                label: "Balance",
                tint: ringTint(for: balance),
                size: TerminalTheme.Metrics.primaryRingSize,
                lineWidth: 3
            )
            .frame(maxWidth: .infinity, alignment: .center)

            if let monthlyLimit = balance.monthlyLimitUSD {
                Text("Monthly limit: $\(Self.formatted(monthlyLimit))"
                    + (balance.monthlyUsageUSD.map { " · used $\(Self.formatted($0))" } ?? ""))
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
            }
        }
    }

    private func ringTint(for balance: ZenBalance) -> Color {
        balance.isHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.warning
    }

    private static func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

/// Shared fallback for the balance card: an empty gauge plus a one-line reason
/// and what to do about it. Never blocks the rest of the dashboard.
private struct FallbackStateView: View {
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(progress: 0, valueText: "—", label: "—", tint: TerminalTheme.Colors.textTertiary, size: TerminalTheme.Metrics.secondaryRingSize, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                Text(detail)
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    ZenBalanceCard(viewModel: ZenBalanceViewModel())
        .padding()
        .background(TerminalTheme.Colors.background)
}
