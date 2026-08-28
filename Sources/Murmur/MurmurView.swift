// The mount. This is the AtmosphereField.swift pattern with one change:
// the rectangle is filled with the ink before the effect runs, because
// colorEffect needs opaque pixels to work on and the shader composites over
// that same ink anyway.
//
// Time starts at zero when the view appears. That is deliberate: the arc
// styles measure `tau = max(time - epoch, 0)`, so with time zeroed at birth
// the epoch argument is always 0 and a settle arc runs once, from the top,
// every time the indicator comes on screen. That is what a thinking
// indicator should do; it is born when the thought starts.

import SwiftUI

/// The indicator. A circle of living material.
public struct MurmurView: View {
    private let configuration: MurmurConfiguration
    private let animated: Bool
    private let stillTime: Double
    private let fps: Double

    @Environment(\.displayScale) private var displayScale
    @State private var birth = Date.now

    public init(
        _ configuration: MurmurConfiguration,
        animated: Bool = true,
        stillTime: Double = 4.0,
        fps: Double = 30
    ) {
        self.configuration = configuration
        self.animated = animated
        self.stillTime = stillTime
        self.fps = fps
    }

    public var body: some View {
        Group {
            if animated {
                TimelineView(.periodic(from: birth, by: 1.0 / max(fps, 1))) { context in
                    field(time: birth.distance(to: context.date))
                }
            } else {
                // One deterministic frame. Screenshot rigs and the gallery's
                // still cells take this path; any time value renders the
                // correct frame, so 4 seconds in is a fair portrait of a
                // style that has settled but is still moving.
                field(time: stillTime)
            }
        }
        .clipShape(Circle())
        // Deliberately no accessibility treatment. A filled shape is not an
        // element, so this announces nothing on its own, and a caller who
        // wants it announced can label it from outside. Hiding it here would
        // silently beat their label.
    }

    private func field(time: Double) -> some View {
        // Hoisted out of the effect closure: it is @Sendable, so it captures
        // values, never the view.
        let name = configuration.style.shaderName
        let character = configuration.resolvedCharacter
        let ink = configuration.ink.color
        let tone = configuration.tone.color
        let hueShift = configuration.hueShift
        let formScale = configuration.formScale
        let speed = configuration.speed
        let depth = configuration.depth
        let glow = configuration.glow
        let scale = displayScale

        return Rectangle()
            .fill(ink)
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.bundle(.module)[dynamicMember: name](
                        .float2(proxy.size),
                        .float(time),
                        .float(scale),
                        .color(ink),
                        .color(tone),
                        .float(hueShift),
                        .float(formScale),
                        .float(speed),
                        .float(depth),
                        .float(glow),
                        .float(character[0]),
                        .float(character[1]),
                        .float(character[2]),
                        .float(character[3]),
                        // Time is already zeroed at birth, so the epoch is
                        // always the origin. See the file header.
                        .float(0)
                    )
                )
            }
    }
}
