//
//  DashboardView.swift
//  DandelionWidget
//
//  Layout for the `.systemSmall` Home Screen widget - four `RingGaugeView`s
//  packed into a 2x2 grid so all four metrics (Balance / 5h / Week / Month)
//  fit in a single small cell. Smaller value/label fonts via the
//  `valueFont` / `labelFont` overrides on `RingGaugeView` so the centre
//  text stays legible at the 62pt ring diameter.
//

import SwiftUI

struct DashboardView: View {
    let snapshot: WidgetUsageSnapshot

    private static let smallRingSize: CGFloat = 62
    private static let smallRingLineWidth: CGFloat = 3
    private static let columnGap: CGFloat = 22
    private static let smallValueFont: Font = .system(size: 12, weight: .bold, design: .monospaced)
    private static let smallLabelFont: Font = .system(size: 9, weight: .regular, design: .monospaced)

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Self.columnGap),
                      GridItem(.flexible(), spacing: Self.columnGap)],
            spacing: TerminalTheme.Spacing.sm
        ) {
            RingGaugeView(
                progress: (snapshot.balancePercent ?? 0) / 100,
                valueText: balanceText,
                label: "Balance",
                tint: snapshot.isBalanceHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.warning,
                size: Self.smallRingSize,
                lineWidth: Self.smallRingLineWidth,
                valueFont: Self.smallValueFont,
                labelFont: Self.smallLabelFont
            )
            RingGaugeView(
                progress: (snapshot.hourPercent ?? 0) / 100,
                valueText: percentText(snapshot.hourPercent),
                label: "5h",
                tint: snapshot.isHourHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger,
                size: Self.smallRingSize,
                lineWidth: Self.smallRingLineWidth,
                valueFont: Self.smallValueFont,
                labelFont: Self.smallLabelFont
            )
            RingGaugeView(
                progress: (snapshot.weeklyPercent ?? 0) / 100,
                valueText: percentText(snapshot.weeklyPercent),
                label: "Week",
                tint: snapshot.isWeeklyHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger,
                size: Self.smallRingSize,
                lineWidth: Self.smallRingLineWidth,
                valueFont: Self.smallValueFont,
                labelFont: Self.smallLabelFont
            )
            RingGaugeView(
                progress: (snapshot.monthlyPercent ?? 0) / 100,
                valueText: percentText(snapshot.monthlyPercent),
                label: "Month",
                tint: snapshot.isMonthlyHealthy ? TerminalTheme.Colors.accent : TerminalTheme.Colors.danger,
                size: Self.smallRingSize,
                lineWidth: Self.smallRingLineWidth,
                valueFont: Self.smallValueFont,
                labelFont: Self.smallLabelFont
            )
        }
        .padding(.horizontal, TerminalTheme.Spacing.xs)
        .padding(.vertical, TerminalTheme.Spacing.xs)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var balanceText: String {
        guard let usd = snapshot.balanceUSD else { return "—" }
        return String(format: "$%.2f", usd)
    }

    private func percentText(_ percent: Double?) -> String {
        guard let percent else { return "—" }
        return String(format: "%.1f%%", percent)
    }
}
