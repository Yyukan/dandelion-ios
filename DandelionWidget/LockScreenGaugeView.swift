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
    var tint: Color = TerminalTheme.Colors.accent

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    var body: some View {
        Gauge(value: clampedProgress) {
            EmptyView()
        } currentValueLabel: {
            Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .widgetAccentable()
    }
}
