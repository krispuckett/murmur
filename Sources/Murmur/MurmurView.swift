// The mount. This is the AtmosphereField.swift pattern with one change:
// the rectangle is filled with the ink before the effect runs, because
// colorEffect needs opaque pixels to work on and the shader composites over
// that same ink anyway.
//
// The clock is the interesting part. `time` is not wall time; it is the
// integrated phase divided by the current tempo, so that `time * speed`,
// which is what every shader actually uses for its motion, stays continuous
// while the tempo changes underneath it. See MurmurClock for why that
// matters. With a steady tempo, which is almost always, it reduces to
// elapsed seconds exactly.
//
// Zero is when the view appears. That is deliberate: the arc styles measure
// `tau = max(time - epoch, 0)`, so with time zeroed at birth the epoch
// argument is always 0 and a settle arc runs once, from the top, every time
// the indicator comes on screen. Entering thinking or success rezeroes it,
// which is how those states replay an arrival.

import SwiftUI

/// The indicator. A circle of living material.
public struct MurmurView: View {
    private let configuration: MurmurConfiguration
    private let state: MurmurState
    private let animated: Bool
    private let stillTime: Double
    private let fps: Double

    @Environment(\.displayScale) private var displayScale
    /// The zero point for `time`, and therefore for every arc.
    @State private var birth: Date
    /// The current segment: what we are gliding away from, when it started,
    /// and the phase every segment before it produced.
    @State private var previousState: MurmurState
    @State private var stateChangedAt: Date
    @State private var phaseAtChange: Double = 0

    public init(
        _ configuration: MurmurConfiguration,
        state: MurmurState = .thinking,
        animated: Bool = true,
        stillTime: Double = 4.0,
        fps: Double = 30
    ) {
        self.configuration = configuration
        self.state = state
        self.animated = animated
        self.stillTime = stillTime
        self.fps = fps
        // One instant for both, so the first frame is exactly tau zero.
        let now = Date.now
        self._birth = State(initialValue: now)
        self._stateChangedAt = State(initialValue: now)
        // Nothing to glide from on the first frame, so the levels start
        // already arrived. The entry still runs: appearing IS an arrival.
        self._previousState = State(initialValue: state)
    }

    public var body: some View {
        Group {
            if animated {
                TimelineView(.periodic(from: birth, by: 1.0 / max(fps, 1))) { context in
                    frame(at: context.date)
                }
            } else {
                // One deterministic frame, state fully arrived and no entry
                // running. Screenshot rigs and the gallery's still cells take
                // this path; any time value renders the correct frame, so 4
                // seconds in is a fair portrait of a style that has settled
                // but is still moving.
                let treatment = configuration.treatment(for: state)
                field(
                    time: stillTime,
                    speed: configuration.speed * treatment.speedFactor,
                    glow: configuration.glow * treatment.glowFactor,
                    depth: configuration.depth * treatment.depthFactor,
                    hueShift: configuration.hueShift + treatment.hueShiftDelta
                )
            }
        }
        .clipShape(Circle())
        .onChange(of: state) { oldState, newState in
            let now = Date.now
            let ending = configuration.treatment(for: oldState)
            // Bank what the segment that is ending produced, so the phase
            // carries across the change instead of restarting.
            phaseAtChange += configuration.speed * MurmurClock.phase(
                through: stateChangedAt.distance(to: now),
                from: configuration.treatment(for: previousState),
                to: ending,
                entry: ending.entry
            )
            previousState = oldState
            stateChangedAt = now
            // Thinking and success are arrivals. Restarting the clock is what
            // makes an arc style run its approach again, so it is limited to
            // the styles that have one: for everyone else, moving time
            // backward would snap a field that is mid-advection.
            if newState.restartsArc, configuration.style.hasArc {
                birth = now
                phaseAtChange = 0
            }
        }
        // Deliberately no accessibility treatment. A filled shape is not an
        // element, so this announces nothing on its own, and a caller who
        // wants it announced can label it from outside. Hiding it here would
        // silently beat their label.
    }

    /// One frame: levels crossfading, entry running on top, phase integrated.
    private func frame(at now: Date) -> some View {
        let tau = stateChangedAt.distance(to: now)
        let from = configuration.treatment(for: previousState)
        let to = configuration.treatment(for: state)
        let entry = to.entry

        // The levels ease across. The entry belongs to the state being
        // entered, so it does not average with anything.
        let levels = from.blended(toward: to, amount: MurmurClock.ease(tau))

        // What the shader is told the tempo is, and what the phase is
        // divided by. The two cancel, which is the whole trick.
        let tempo = configuration.speed * levels.speedFactor * entry.speedBoost(at: tau)

        // Everything banked, plus this segment so far, plus the stutter's
        // lag. The lag scales with the steady tempo so a catch feels the
        // same size whatever speed the designer set.
        let run = phaseAtChange + configuration.speed * MurmurClock.phase(
            through: tau, from: from, to: to, entry: entry
        )
        let lag = entry.phaseOffset(at: tau) * configuration.speed * to.speedFactor
        let phase = max(run + lag, 0)

        return field(
            time: phase / max(tempo, 1e-6),
            speed: tempo,
            glow: configuration.glow * levels.glowFactor * entry.glowBoost(at: tau),
            depth: configuration.depth * levels.depthFactor,
            hueShift: configuration.hueShift + levels.hueShiftDelta
        )
    }

    private func field(
        time: Double,
        speed: Double,
        glow: Double,
        depth: Double,
        hueShift: Double
    ) -> some View {
        // Hoisted out of the effect closure: it is @Sendable, so it captures
        // values, never the view.
        let name = configuration.style.shaderName
        let character = configuration.resolvedCharacter
        let ink = configuration.ink.color
        let tone = configuration.tone.color
        let formScale = configuration.formScale
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
                        // Time is already zeroed at birth, and a state that
                        // restarts an arc rezeroes it. See the file header.
                        .float(0)
                    )
                )
            }
    }
}
