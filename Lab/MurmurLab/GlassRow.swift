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
    /// Where the pan already was when it began. Subtracting it is what makes
    /// the drag relative: the value moves from where it is, by how far the
    /// finger travels, and never jumps to meet the touch.
    @State private var dragOrigin: CGFloat?

    private static let height: CGFloat = 54
    private static let inset: CGFloat = 16
    /// The trailing strip the value button owns, left out of the dial surface.
    private static let valueWidth: CGFloat = 80

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
                    .foregroundStyle(isDefault ? LabTheme.valueIdle : LabTheme.valueLive)
                    .frame(minWidth: 64, maxHeight: .infinity, alignment: .trailing)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Self.inset)
        .frame(maxWidth: .infinity, minHeight: Self.height)
        // Not wrapped in a GlassEffectContainer by its section, and not
        // interactive: both were tried and both fold this row's 2pt value
        // track into the glass, which comes out blurred and dim. The track is
        // the one thing the row exists to show, so it wins over the grouping.
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .overlay(alignment: .bottomLeading) { track(width: width) }
        .contentShape(.rect(cornerRadius: 16))
        // The dial surface. It stops short of the value so the readout stays
        // a plain button and keeps its tap-to-reset.
        .overlay(alignment: .leading) {
            HorizontalDrag(
                onChange: { dx in
                    if dragStart == nil {
                        dragStart = value
                        dragOrigin = dx
                    }
                    guard let start = dragStart, let origin = dragOrigin else { return }
                    // One row width of travel covers the whole range, so a
                    // small movement is a small change anywhere on the row.
                    let span = range.upperBound - range.lowerBound
                    let travel = max(width - Self.inset * 2, 1)
                    let next = start + Double((dx - origin) / travel) * span
                    value = min(max(next, range.lowerBound), range.upperBound)
                },
                onEnd: {
                    dragStart = nil
                    dragOrigin = nil
                }
            )
            .padding(.trailing, Self.valueWidth)
        }
    }

    /// The track carries position and nothing else: no thumb, no handle. The
    /// fill ends where the value is. A range that spans zero fills from its
    /// zero point outward, so hueShift reads as a departure from centre in one
    /// direction or the other rather than as a bar that happens to be half
    /// full at rest.
    private func track(width: CGFloat) -> some View {
        let usable = max(width - Self.inset * 2, 1)
        let span = range.upperBound - range.lowerBound
        let fraction = span > 0 ? min(max((value - range.lowerBound) / span, 0), 1) : 0
        let origin = isCentered && span > 0
            ? min(max((0 - range.lowerBound) / span, 0), 1)
            : 0
        let lead = min(origin, fraction)
        return ZStack(alignment: .leading) {
            Capsule().fill(LabTheme.trackBed)
            Capsule().fill(LabTheme.trackFill)
                // At exactly zero this leaves a small nub sitting on the
                // centre, which is the honest reading of "no shift".
                .frame(width: max(3, usable * abs(fraction - origin)))
                .offset(x: usable * lead)
        }
        .frame(height: 2)
        .padding(.horizontal, Self.inset)
        .padding(.bottom, 9)
    }

    private var isDefault: Bool { abs(value - defaultValue) < 0.005 }

    /// A range with zero inside it reads from the centre out.
    private var isCentered: Bool { range.lowerBound < 0 && range.upperBound > 0 }

    private var formatted: String {
        String(format: signed ? "%+.2f" : "%.2f", value)
    }
}

/// Two-axis tilt, dragged. The simulator has no gyro, so this stands in for
/// tilting the phone: touch anywhere in the pad and the point under the finger
/// is the tilt. Absolute rather than relative, unlike the dial rows, because a
/// pad that models a physical attitude should go where you put it.
struct TiltPad: View {
    @Binding var value: CGPoint

    private static let side: CGFloat = 120

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("tilt")
                    .font(LabTheme.mono(13))
                    .foregroundStyle(LabTheme.label)

                Spacer(minLength: 8)

                // Tapping the value recentres, the same reset every other row
                // in the panel has. Double tapping the pad does it too, but
                // this is the affordance the rest of the app already taught.
                Button {
                    withAnimation(.snappy(duration: 0.2)) { value = .zero }
                } label: {
                    Text(String(format: "%+.2f %+.2f", value.x, value.y))
                        .font(LabTheme.mono(13, .medium))
                        .monospacedDigit()
                        .foregroundStyle(isCentered ? LabTheme.valueIdle : LabTheme.valueLive)
                        .frame(minHeight: 44, alignment: .trailing)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            pad
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var pad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)

            // Centre crosshair, so rest is legible without a label.
            Rectangle().fill(.white.opacity(0.10)).frame(width: 1, height: 14)
            Rectangle().fill(.white.opacity(0.10)).frame(width: 14, height: 1)

            // The marker. A 2D attitude has no honest reading without one, so
            // this is the one place a position dot earns its place.
            Circle()
                .fill(LabTheme.trackFill)
                .frame(width: 10, height: 10)
                .offset(
                    x: CGFloat(value.x) * (Self.side / 2 - 10),
                    y: CGFloat(value.y) * (Self.side / 2 - 10)
                )
        }
        .frame(width: Self.side, height: Self.side)
        .contentShape(.rect(cornerRadius: 14))
        .overlay {
            PadDrag(
                onMove: { point in
                    let half = Self.side / 2
                    value = CGPoint(
                        x: min(max((point.x - half) / half, -1), 1),
                        y: min(max((point.y - half) / half, -1), 1)
                    )
                },
                onReset: { value = .zero }
            )
        }
    }

    private var isCentered: Bool { abs(value.x) < 0.005 && abs(value.y) < 0.005 }
}

/// The pad's input: absolute location for the drag, double tap to recentre.
private struct PadDrag: UIViewRepresentable {
    let onMove: (CGPoint) -> Void
    let onReset: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.pan(_:))
        )
        view.addGestureRecognizer(pan)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.doubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject {
        var parent: PadDrag

        init(_ parent: PadDrag) { self.parent = parent }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            switch gesture.state {
            case .began, .changed, .ended:
                parent.onMove(gesture.location(in: view))
            default:
                break
            }
        }

        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            parent.onReset()
        }
    }
}

/// The second hue anchor, with a way back to one. Same swatches as the tone
/// row plus Clear, which returns the configuration to a single-anchor rail.
struct Tone2Row: View {
    @Binding var selection: MurmurRGBA?
    let swatches: [MurmurRGBA]

    var body: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { selection = nil }
            } label: {
                ZStack {
                    Circle().strokeBorder(.white.opacity(selection == nil ? 0.9 : 0.18),
                                          lineWidth: selection == nil ? 2 : 1)
                    Image(systemName: "slash.circle")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(selection == nil ? 0.9 : 0.35))
                }
                .frame(width: 32, height: 32)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

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
        guard let selection else { return false }
        return abs(swatch.r - selection.r) < 0.004
            && abs(swatch.g - selection.g) < 0.004
            && abs(swatch.b - selection.b) < 0.004
    }
}

/// A pan that only claims the touch when the finger is already moving
/// sideways.
///
/// This is UIKit because a SwiftUI DragGesture cannot do it. Attached to a row
/// inside a ScrollView, a DragGesture blocks the scroll outright no matter its
/// minimumDistance, and no matter whether it is attached with gesture() or
/// simultaneousGesture(): a vertical drag begun on a dial row simply never
/// scrolled the panel. A UIPanGestureRecognizer can refuse to begin, so a
/// vertical flick stays the scroll view's and only a sideways one moves a dial.
private struct HorizontalDrag: UIViewRepresentable {
    let onChange: (CGFloat) -> Void
    let onEnd: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: HorizontalDrag

        init(_ parent: HorizontalDrag) { self.parent = parent }

        @objc func handle(_ pan: UIPanGestureRecognizer) {
            switch pan.state {
            case .changed:
                parent.onChange(pan.translation(in: pan.view).x)
            case .ended, .cancelled, .failed:
                parent.onEnd()
            default:
                break
            }
        }

        /// The whole point: begin only for a sideways start.
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
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
                .foregroundStyle(isSelected ? .white : LabTheme.labelDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 10)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // Glass IS the selection, the same rule the state selector uses: the
        // chosen chip wears it and the rest are outlines. The accent is spent
        // on the material and on the one primary action, nowhere else, and a
        // bright stroke on top of glass everyone is wearing reads as nothing.
        .modifier(SelectionGlass(isSelected: isSelected))
    }
}

/// Selected wears glass and a bright edge; unselected is a hairline outline.
private struct SelectionGlass: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay { Capsule().strokeBorder(LabTheme.selectedEdge, lineWidth: 2) }
        } else {
            content
                .overlay { Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1) }
        }
    }
}

/// The small mono heading that separates panel sections. It wears the same
/// glass as everything under it so a section reads as one material from its
/// name down, rather than type floating above a stack of glass.
struct SectionHeading: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LabTheme.mono(11, .medium))
            .foregroundStyle(.white.opacity(0.62))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
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
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}
