//
//  LockScreenGaugeView.swift
//  DandelionWidget
//
//  Native accessoryCircular ring gauge - the correct primitive on the Lock
//  Screen, since WidgetKit renders complications through its own
//  tinted/monochrome pipeline rather than a custom Canvas (unlike
//  RingGaugeView in the main app). Shows only the percentage - no other
//  labels/captions - via the Gauge's currentValueLabel, since
//  accessoryCircularCapacity never renders a value on its own unless one is
//  explicitly supplied.
//

import SwiftUI
import WidgetKit

struct LockScreenGaugeView: View {
    /// 0...1
    let progress: Double
    /// Optional override for the centre label. When non-nil it's shown as-is
    /// instead of `progress` formatted as a percent - used by the Balance
    /// widget to display the raw USD balance.
    var valueLabel: String? = nil
    var tint: Color = TerminalTheme.Colors.accent

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        Gauge(value: clampedProgress) {
            EmptyView()
        } currentValueLabel: {
            if let valueLabel {
                Text(valueLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            } else {
                Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .widgetAccentable()
        .containerBackground(for: .widget) { Color.clear }
    }
}
