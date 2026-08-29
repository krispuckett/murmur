// The mount. This is the AtmosphereField.swift pattern with one change:
// the rectangle is filled with the ink before the effect runs, because
// colorEffect needs opaque pixels to work on and the shader composites over
// that same ink anyway.
//
// A state change crosses the WHOLE design, character knobs included, over
// MurmurState.transitionDuration. That is what makes it read as one material
// rearranging itself rather than two materials swapped.
//
// The clock is the subtle part. `time` is not wall time; it is the
// integrated phase divided by the current tempo, so that `time * speed`,
// which is what every shader uses for its motion, stays continuous while the
// tempo changes underneath it. See MurmurClock for why that matters. With a
// steady tempo, which is almost always, it reduces to elapsed seconds.
//
// Zero is when the view appears. The arc styles measure
// `tau = max(time - epoch, 0)`, so with time zeroed at birth the epoch
// argument is always 0 and a settle arc runs once, from the top, every time
// the indicator comes on screen. Entering thinking or success rezeroes it,
// which is how those states replay an arrival.

import SwiftUI

/// The indicator. A circle of living material.
public struct MurmurView: View {
    private let configuration: MurmurConfiguration
    private let state: MurmurState
    private let signals: MurmurSignals
    private let tilt: CGPoint
    private let haptics: Bool
    private let animated: Bool
    private let stillTime: Double
    private let fps: Double

    @Environment(\.displayScale) private var displayScale
    /// The zero point for `time`, and therefore for every arc.
    @State private var birth: Date
    /// The current segment: what we are crossing from, when it started, and
    /// the phase every segment before it produced.
    @State private var previousState: MurmurState
    @State private var stateChangedAt: Date
    @State private var phaseAtChange: Double = 0
    /// Smoothed live signals. A reference type so stepping it per frame does
    /// not write view state mid-update. See MurmurSignalEnvelope.
    @State private var envelope = MurmurSignalEnvelope()

    public init(
        _ configuration: MurmurConfiguration,
        state: MurmurState = .thinking,
        signals: MurmurSignals = .none,
        tilt: CGPoint = .zero,
        haptics: Bool = false,
        animated: Bool = true,
        stillTime: Double = 4.0,
        fps: Double = 30
    ) {
        self.configuration = configuration
        self.state = state
        self.signals = signals
        self.tilt = tilt
        self.haptics = haptics
        self.animated = animated
        self.stillTime = stillTime
        self.fps = fps
        // One instant for both, so the first frame is exactly tau zero.
        let now = Date.now
        self._birth = State(initialValue: now)
        self._stateChangedAt = State(initialValue: now)
        // Nothing to cross from on the first frame, so the design starts
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
                // One deterministic frame, design fully arrived and no entry
                // running. stillTime doubles as the state age, so a still can
                // be taken half a second in to catch a success flash or four
                // seconds in to show the settled look.
                let design = configuration.resolvedParameters(for: state)
                // Raw, unsmoothed: a still frame has no previous frame to
                // smooth from, and a screenshot rig wants exactly what it
                // asked for.
                let live = signals.clamped
                field(
                    time: stillTime,
                    speed: design.speed * (1 + MurmurSignals.activitySpeedLift * live.activity),
                    glow: design.glow * (1 + MurmurSignals.levelGlowLift * live.level),
                    depth: design.depth,
                    hueShift: design.hueShift,
                    formScale: design.formScale,
                    character: design.character,
                    stateTau: stillTime,
                    signals: live
                )
            }
        }
        .clipShape(Circle())
        .onChange(of: state) { oldState, newState in
            let now = Date.now
            // Bank what the segment that is ending produced, so the phase
            // carries across the change instead of restarting.
            phaseAtChange += MurmurClock.phase(
                through: stateChangedAt.distance(to: now),
                from: configuration.resolvedParameters(for: previousState),
                to: configuration.resolvedParameters(for: oldState),
                entry: configuration.entry(for: oldState)
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
                envelope.resetPhase()
            }
            // Once, on entry. The crossfade that follows is continuous and a
            // haptic is not, so there is nothing to play during it.
            if haptics {
                MurmurHaptics.play(entering: newState)
            }
        }
        // Deliberately no accessibility treatment. A filled shape is not an
        // element, so this announces nothing on its own, and a caller who
        // wants it announced can label it from outside. Hiding it here would
        // silently beat their label.
    }

    /// One frame: the designs crossing, the entry running on top, the phase
    /// integrated so the shader's own clock never jumps.
    private func frame(at now: Date) -> some View {
        let tau = stateChangedAt.distance(to: now)
        let from = configuration.resolvedParameters(for: previousState)
        let to = configuration.resolvedParameters(for: state)
        // The entry belongs to the state being entered, so it does not
        // average with anything.
        let entry = configuration.entry(for: state)
        let design = from.blended(toward: to, amount: MurmurClock.ease(tau))

        // What the shader is told the tempo is, and what the phase is
        // divided by. The two cancel, which is the whole trick.
        let tempo = design.speed * entry.speedBoost(at: tau)

        // Everything banked, plus this segment so far, plus the stutter's
        // lag. The lag scales with the state's own tempo so a catch feels the
        // same size whatever speed the designer set.
        let run = phaseAtChange + MurmurClock.phase(
            through: tau, from: from, to: to, entry: entry
        )
        let base = max(run + entry.phaseOffset(at: tau) * to.speed, 0)

        // The live signals ride on top of the finished state design. Activity
        // quickens, level lifts the light. Both are small on purpose: this is
        // the generic response every species gets, and the presence family
        // builds its real reaction from the raw uniforms in the shader.
        let live = envelope.step(toward: signals, at: now, baseTempo: tempo)
        let quickened = tempo * (1 + MurmurSignals.activitySpeedLift * live.activity)

        return field(
            // The activity lift is integrated, not multiplied onto the clock,
            // so a moving signal cannot drag the field forward. See the note
            // on MurmurSignalEnvelope.step.
            time: (base + envelope.extraPhase) / max(quickened, 1e-6),
            speed: quickened,
            glow: design.glow * entry.glowBoost(at: tau)
                * (1 + MurmurSignals.levelGlowLift * live.level),
            depth: design.depth,
            hueShift: design.hueShift,
            formScale: design.formScale,
            character: design.character,
            stateTau: max(tau, 0),
            signals: live
        )
    }

    private func field(
        time: Double,
        speed: Double,
        glow: Double,
        depth: Double,
        hueShift: Double,
        formScale: Double,
        character: [Double],
        stateTau: Double,
        signals: MurmurSignals
    ) -> some View {
        // Hoisted out of the effect closure: it is @Sendable, so it captures
        // values, never the view.
        let name = configuration.style.shaderName
        let ink = configuration.ink.color
        let tone = configuration.tone.color
        let scale = displayScale
        // During a crossfade the shader is told where it is GOING. A pack
        // branches on this, and half a branch is worse than either side.
        let stateIndex = state.shaderIndex
        let level = signals.level
        let activity = signals.activity
        // Only the heroes take the two extra uniforms. The archive families
        // keep the call they were written against, argument for argument.
        let glass: MurmurGlassArguments? = configuration.style.family == .glass
            ? MurmurGlassArguments(tilt: tilt, tone2: configuration.resolvedTone2.color)
            : nil

        return Rectangle()
            .fill(ink)
            .visualEffect { content, proxy in
                content.colorEffect(
                    Shader(
                        function: ShaderLibrary.bundle(.module)[dynamicMember: name],
                        arguments: murmurShaderArguments(
                            size: proxy.size,
                            time: time,
                            pixelScale: scale,
                            ink: ink,
                            tone: tone,
                            hueShift: hueShift,
                            formScale: formScale,
                            speed: speed,
                            depth: depth,
                            glow: glow,
                            character: character,
                            stateIndex: stateIndex,
                            stateTau: stateTau,
                            level: level,
                            activity: activity,
                            glass: glass
                        )
                    )
                )
            }
    }
}

/// The glass family's signature extension: the two arguments only the heroes
/// take, kept together so the call site cannot supply one without the other.
struct MurmurGlassArguments: Equatable, Sendable {
    /// Device attitude, roughly -1...1 per axis. Zero when unavailable.
    var tilt: CGPoint
    /// The second duotone anchor. Equal to tone means classic.
    var tone2: Color
}

/// One place that knows the argument order, so the view and the tests agree
/// about it. Nineteen for the archive families, twenty-one for the heroes;
/// colorEffect supplies position and currentColor on top of these.
func murmurShaderArguments(
    size: CGSize,
    time: Double,
    pixelScale: Double,
    ink: Color,
    tone: Color,
    hueShift: Double,
    formScale: Double,
    speed: Double,
    depth: Double,
    glow: Double,
    character: [Double],
    stateIndex: Double,
    stateTau: Double,
    level: Double,
    activity: Double,
    glass: MurmurGlassArguments?
) -> [Shader.Argument] {
    var arguments: [Shader.Argument] = [
        .float2(size),
        .float(time),
        .float(pixelScale),
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
        // Time is already zeroed at birth, and a state that restarts an arc
        // rezeroes it. See the file header.
        .float(0),
        .float(stateIndex),
        .float(stateTau),
        .float(level),
        .float(activity),
    ]
    if let glass {
        arguments.append(.float2(glass.tilt))
        arguments.append(.color(glass.tone2))
    }
    return arguments
}
