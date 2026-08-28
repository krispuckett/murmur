// The house dial. Not a slider in a form: a glass row you drag anywhere on,
// with the number on the right doubling as the reset. The value track is a
// hairline at the bottom so the row stays a row and never becomes a widget.

import SwiftUI
import Murmur

/// A parameter row. Drag horizontally anywhere on it to set, tap the value to
/// return it to the tuned default.
struct DialRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    var signed: Bool = false

    @State private var dragStart: Double?
    @State private var horizontal: Bool?

    private static let height: CGFloat = 54
    private static let inset: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            row(width: proxy.size.width)
        }
        .frame(height: Self.height)
    }

    private func row(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(LabTheme.mono(13))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)

            Spacer(minLength: 8)

            Button {
                withAnimation(.snappy(duration: 0.2)) { value = defaultValue }
            } label: {
                Text(formatted)
                    .font(LabTheme.mono(13, .medium))
                    .monospacedDigit()
                    .foregroundStyle(isDefault ? .white.opacity(0.5) : LabTheme.tone)
                    .frame(minWidth: 64, maxHeight: .infinity, alignment: .trailing)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Self.inset)
        .frame(maxWidth: .infinity, minHeight: Self.height)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .overlay(alignment: .bottomLeading) { track(width: width) }
        .contentShape(.rect(cornerRadius: 16))
        // Simultaneous, with an axis lock on the first movement, so the row
        // never steals a vertical scroll from the panel it lives in.
        .simultaneousGesture(
            DragGesture(minimumDistance: 3)
                .onChanged { gesture in
                    if horizontal == nil {
                        horizontal = abs(gesture.translation.width) > abs(gesture.translation.height)
                        dragStart = value
                    }
                    guard horizontal == true, let start = dragStart else { return }
                    let span = range.upperBound - range.lowerBound
                    let travel = max(width - Self.inset * 2, 1)
                    let next = start + Double(gesture.translation.width / travel) * span
                    value = min(max(next, range.lowerBound), range.upperBound)
                }
                .onEnded { _ in
                    horizontal = nil
                    dragStart = nil
                }
        )
    }

    private func track(width: CGFloat) -> some View {
        let usable = max(width - Self.inset * 2, 1)
        let span = range.upperBound - range.lowerBound
        let fraction = span > 0 ? min(max((value - range.lowerBound) / span, 0), 1) : 0
        return ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.12))
            Capsule().fill(LabTheme.tone.opacity(0.9))
                .frame(width: max(2, usable * fraction))
        }
        .frame(height: 2)
        .padding(.horizontal, Self.inset)
        .padding(.bottom, 9)
    }

    private var isDefault: Bool { abs(value - defaultValue) < 0.005 }

    private var formatted: String {
        String(format: signed ? "%+.2f" : "%.2f", value)
    }
}

/// A selectable glass chip. The segmented controls in this app are rows of
/// these, never a UISegmentedControl.
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LabTheme.mono(12, isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 10)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected
                ? .regular.tint(LabTheme.tone.opacity(0.45)).interactive()
                : .regular.interactive(),
            in: .capsule
        )
    }
}

/// The small mono heading that separates panel sections.
struct SectionHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LabTheme.mono(11, .medium))
            .foregroundStyle(.white.opacity(0.42))
            .padding(.leading, 4)
    }
}

/// The curated tone anchors. One hue family per configuration, so this is a
/// short row of starting points rather than a full palette.
struct SwatchRow: View {
    @Binding var selection: MurmurRGBA
    let swatches: [MurmurRGBA]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(swatches.enumerated()), id: \.offset) { _, swatch in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = swatch }
                } label: {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle().strokeBorder(
                                .white.opacity(isSelected(swatch) ? 0.9 : 0.12),
                                lineWidth: isSelected(swatch) ? 2 : 1
                            )
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private func isSelected(_ swatch: MurmurRGBA) -> Bool {
        abs(swatch.r - selection.r) < 0.004
            && abs(swatch.g - selection.g) < 0.004
            && abs(swatch.b - selection.b) < 0.004
    }
}

/// A glass row that hosts an arbitrary trailing control (a color well, a text
/// field). Same grammar as DialRow so the panel reads as one system.
struct ControlRow<Trailing: View>: View {
    let label: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(LabTheme.mono(13))
                .foregroundStyle(.white.opacity(0.68))
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 54)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
