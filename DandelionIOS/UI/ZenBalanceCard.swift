//
//  ZenBalanceCard.swift
//  Dandelion
//
//  Live Zen balance ring, auto-reload threshold and monthly limit info, fed
//  by the session cookie captured through the in-app OpenCode sign-in - with
//  a graceful fallback state (with a Sign In button) when no cookie exists
//  yet or the private endpoint fails.
//

import SwiftUI

struct ZenBalanceCard: View {
    @Bindable var viewModel: ZenBalanceViewModel
    var onSignIn: () -> Void = {}

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
            case .unavailable:
                SignInPromptView(title: "Balance unavailable", onSignIn: onSignIn)
            case .sessionExpired:
                SessionExpiredStateView(onSignIn: onSignIn)
            }
        }
        .task { await viewModel.refresh() }
    }

    private func loadedContent(_ balance: ZenBalance) -> some View {
        VStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(
                progress: progress(for: balance),
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

    private func progress(for balance: ZenBalance) -> Double {
        if let monthlyLimit = balance.monthlyLimitUSD, monthlyLimit > 0 {
            return balance.currentUSD / monthlyLimit
        }
        // With no configured monthly limit, show progress toward the
        // auto-reload amount as a reasonable reference ceiling.
        guard balance.autoReloadAmountUSD > 0 else { return 1 }
        return balance.currentUSD / balance.autoReloadAmountUSD
    }

    private func ringTint(for balance: ZenBalance) -> Color {
        balance.currentUSD <= balance.autoReloadThresholdUSD
            ? TerminalTheme.Colors.warning
            : TerminalTheme.Colors.accent
    }

    private static func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

/// Shown when no session cookie has been captured yet - never blocks the
/// rest of the dashboard, just offers the in-app sign-in.
struct SignInPromptView: View {
    var title: String
    var onSignIn: () -> Void

    var body: some View {
        HStack(spacing: TerminalTheme.Spacing.sm) {
            RingGaugeView(progress: 0, valueText: "—", label: "—", tint: TerminalTheme.Colors.textTertiary, size: TerminalTheme.Metrics.secondaryRingSize, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TerminalTheme.Fonts.body.weight(.semibold))
                Text("Sign in to your OpenCode account to see live data.")
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
                Button("Sign In", action: onSignIn)
                    .font(TerminalTheme.Fonts.caption)
                    .foregroundStyle(TerminalTheme.Colors.accent)
            }
        }
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
    ZenBalanceCard(viewModel: ZenBalanceViewModel(appSettings: AppSettings()))
        .padding()
        .background(TerminalTheme.Colors.background)
}
