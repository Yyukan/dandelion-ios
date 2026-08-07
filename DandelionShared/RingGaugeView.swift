//
//  RingGaugeView.swift
//  DandelionShared
//
//  Canvas-drawn circular progress ring with a value/label pair in the
//  centre. Shared by the in-app Zen balance + Go usage cards and the
//  home-screen Dashboard widget.
//

import SwiftUI

/// A circular progress ring gauge showing `progress` (0...1) with a value/label pair in the center.
struct RingGaugeView: View {
    /// Progress in the 0...1 range. Values outside are clamped.
    let progress: Double
    /// Large value shown in the center of the ring (e.g. "$12.40" or "42%").
    let valueText: String
    /// Small caption shown below the value (e.g. "Balance" or "5h window").
    let label: String
    /// Ring stroke color; defaults to the theme accent.
    var tint: Color = TerminalTheme.Colors.accent
    /// Ring diameter.
    var size: CGFloat = 96
    /// Ring stroke width.
    var lineWidth: CGFloat = 8
    /// Font used for the value text in the centre of the ring. Defaults
    /// to the theme's primary metric size; override to a smaller font
    /// when the ring is rendered at a small diameter (e.g. inside a
    /// `.systemSmall` widget where 4 rings must fit in 2x2).
    var valueFont: Font = TerminalTheme.Fonts.metric
    /// Font used for the label below the value. Same rationale as
    /// `valueFont` - small widget overrides need a smaller size.
    var labelFont: Font = TerminalTheme.Fonts.caption

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: canvasSize)
                    .insetBy(dx: lineWidth / 2, dy: lineWidth / 2)

                // Track
                var track = Path()
                track.addArc(
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360),
                    clockwise: false
                )
                context.stroke(
                    track,
                    with: .color(TerminalTheme.Colors.border),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                // Progress arc, starting at 12 o'clock, clockwise.
                var arc = Path()
                let startAngle = Angle.degrees(-90)
                let endAngle = Angle.degrees(-90 + clampedProgress * 360)
                arc.addArc(
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                context.stroke(
                    arc,
                    with: .color(tint),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
            .frame(width: size, height: size)

            VStack(spacing: 2) {
                Text(valueText)
                    .font(valueFont)
                    .foregroundStyle(TerminalTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(labelFont)
                    .foregroundStyle(TerminalTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, lineWidth * 2)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText)")
    }
}

#Preview {
    RingGaugeView(progress: 0.42, valueText: "42%", label: "5h window")
        .padding()
        .background(TerminalTheme.Colors.background)
}
