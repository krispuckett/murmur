// AI states. From Kris's device review: one indicator should be able to say
// what the agent is doing without becoming a different object, and it has to
// say it as MOTION. Someone who cannot read the label should still know idle
// from thinking from responding from success from error.
//
// A state is a full design. The configuration carries a MurmurParameters set
// per state, seeded here and then editable one dial at a time, plus an entry
// that says what the change itself looks like. Nothing in this file reaches
// the Metal as a special case: the shader gets the ordinary uniforms, plus
// stateIndex and stateTau so a pack can add its own expression for the two
// states that earn one.
//
// The seeds below are the starting design for every style. Tune here.

import Foundation

public enum MurmurState: String, CaseIterable, Codable, Sendable {
    /// Present, waiting, doing nothing. The material at its quietest.
    case idle
    /// Hearing a voice. Attentive and open rather than busy: this is where
    /// the live `level` signal does its deepest work, so the design leaves
    /// room for it to move rather than spending everything up front.
    case listening
    /// Working, and the state a MurmurView shows unless told otherwise.
    /// It opens the material up rather than passing it through.
    case thinking
    /// Streaming an answer out. The urgent one.
    case responding
    /// Arrival. Settles bright, and restarts the arc on styles that have one.
    case success
    /// Something went wrong. Dimmer, denser, walked down the hue family.
    case error

    public var displayName: String { rawValue.capitalized }

    /// What the shader is told. Fixed by the contract in SPEC.md; a pack
    /// branches on it, so these numbers are not free to move.
    public var shaderIndex: Double {
        switch self {
        case .idle: 0
        case .listening: 1
        case .thinking: 2
        case .responding: 3
        case .success: 4
        case .error: 5
        }
    }

    /// Entering these is an arrival, so the arc styles (confluence, bloom,
    /// strata, oculus, tuning, feather) run their approach again from that
    /// moment. Thinking is a thought starting; success is the completion.
    public var restartsArc: Bool {
        self == .thinking || self == .success
    }

    /// How long a state change takes to cross. A cut reads as a different
    /// indicator; this reads as a change of mind.
    public static let transitionDuration: Double = 0.6

    /// The starting design for a style: the style's own tuned character with
    /// this state's dials. A configuration is seeded from these and then
    /// diverges wherever the designer edits it.
    public func seedParameters(for style: MurmurStyle) -> MurmurParameters {
        let seed = self.seed
        return MurmurParameters(
            speed: seed.speed,
            formScale: 1,
            depth: seed.depth,
            glow: seed.glow,
            hueShift: seed.hueShift,
            character: style.characterDefaults
        )
    }

    /// What a state change looks like out of the box.
    public var defaultEntry: MurmurEntry { seed.entry }

    /// Retuned on Kris's second device pass: the first table was too narrow
    /// to read. Idle and thinking have to be distinguishable from across a
    /// room, so idle sits at about a quarter of thinking's tempo.
    var seed: MurmurStateSeed {
        switch self {
        // Nearly still, dim, unmistakably resting. Never actually stopped:
        // a frozen indicator reads as a broken shader, which is the lesson
        // the atmosphere field already taught us. Nothing announces idle,
        // so there is no entry.
        case .idle:
            MurmurStateSeed(speed: 0.30, glow: 0.65, depth: 0.75, hueShift: 0, entry: .none)
        // Attentive, not busy. Awake and open compared to idle, but well
        // under thinking, because the voice is what should move here: a
        // design that is already loud has nothing left to say when someone
        // speaks. No entry, since listening starts when the mic opens and
        // that is not an event the material should announce.
        case .listening:
            MurmurStateSeed(speed: 0.90, glow: 1.10, depth: 1.10, hueShift: 0, entry: .none)
        // The out-of-box look, because thinking is the default state. It
        // does MORE than the raw material rather than passing it through:
        // the palette opens, the light lifts, the motion picks up. A style
        // at rest is the ingredient; this is the ingredient turned on.
        case .thinking:
            MurmurStateSeed(speed: 1.15, glow: 1.20, depth: 1.25, hueShift: 0, entry: .wake)
        // The one state the eye should notice changing. Quicker and
        // brighter still, though the ceiling stays dim. No entry, because
        // streaming is a continuation of thinking rather than an event; the
        // packs give it a directional drive in the shader instead.
        case .responding:
            MurmurStateSeed(speed: 1.45, glow: 1.30, depth: 1.25, hueShift: 0, entry: .none)
        // The completion breath. Everything relaxes back toward the raw
        // material while the light holds, so arrival reads as settling
        // rather than as stopping. The swell is the Swift half of that; the
        // packs add the flash that travels through the field.
        case .success:
            MurmurStateSeed(speed: 0.55, glow: 1.05, depth: 1.00, hueShift: 0, entry: .swell)
        // Down the rail, not off it. The negative hue walk takes the amber
        // family toward dark ember; deeper palette range carries the weight
        // that the lost glow used to; the stutter is the material catching.
        case .error:
            MurmurStateSeed(speed: 0.65, glow: 0.80, depth: 1.20, hueShift: -0.35, entry: .stutter)
        }
    }
}

/// Dictionary keys encode as "idle", "thinking" and so on rather than as an
/// alternating array, which is what a Dictionary with a non-string key would
/// otherwise produce. The stdlib supplies the whole conformance for a string
/// raw value, so this is a one-line opt in.
extension MurmurState: CodingKeyRepresentable {}

/// The seed factors. Internal: a configuration exposes the parameters these
/// produce, and the designer edits those. Nobody outside needs the recipe.
struct MurmurStateSeed: Sendable {
    let speed: Double
    let glow: Double
    let depth: Double
    let hueShift: Double
    let entry: MurmurEntry
}

// MARK: - Entry envelopes

/// What a state change looks like in the instant it happens. Every envelope
/// is a pure function of tau, the seconds since the change, so any frame can
/// be rendered from the timestamp alone.
public enum MurmurEntry: String, CaseIterable, Codable, Sendable {
    /// Nothing. The parameters cross and that is the whole change.
    case none
    /// A brief speed overshoot that decays in. The material wakes up.
    case wake
    /// A glow envelope that rises and settles. The arrival breath.
    case swell
    /// Two quick catches of the clock, then a clean settle. The error catch.
    case stutter

    public var displayName: String { rawValue.capitalized }

    /// When the envelope is finished. Past this the steady design is all
    /// that is left, so the phase integral can stop working and just run out
    /// at a constant rate.
    public var duration: Double {
        switch self {
        case .none: 0
        case .wake: 2.5
        case .swell: 1.5
        case .stutter: 0.5
        }
    }

    /// Multiplier on the tempo at tau.
    func speedBoost(at tau: Double) -> Double {
        guard self == .wake, tau > 0, tau < duration else { return 1 }
        return 1 + Self.wakeOvershoot * exp(-tau / Self.wakeDecay)
    }

    /// Multiplier on the emission at tau.
    func glowBoost(at tau: Double) -> Double {
        guard self == .swell, tau > 0, tau < duration else { return 1 }
        // Gamma shape: exactly zero at the change, exactly 1 at the peak,
        // long soft tail. The taper takes the tail's last few percent to
        // zero at the duration so the envelope truly ends.
        let x = tau / Self.swellPeak
        let shape = pow(x, Self.swellPower) * exp(Self.swellPower * (1 - x))
        let taper = 1 - Self.smoothstep((tau - (duration - 0.4)) / 0.4)
        return 1 + Self.swellAmount * shape * taper
    }

    /// Additive offset on the phase, in seconds of shader time at the
    /// current tempo. Negative: the clock lags, then catches back up.
    ///
    /// Two arches rather than a square hold, because a hold has infinite
    /// acceleration at both ends and that is what reads as a glitch. The
    /// depths are picked so the instantaneous rate dips to about half and
    /// overshoots to about one and a half, which the eye reads as the
    /// material snagging on something. Deeper than this and it stops dead.
    func phaseOffset(at tau: Double) -> Double {
        guard self == .stutter, tau > 0, tau < duration else { return 0 }
        return -(Self.firstCatchDepth * Self.arch(tau, start: 0.05, width: 0.20)
            + Self.secondCatchDepth * Self.arch(tau, start: 0.28, width: 0.16))
    }

    // The tuned constants, all in one place.
    private static let wakeOvershoot = 0.6
    private static let wakeDecay = 0.4
    private static let swellPeak = 0.4
    private static let swellPower = 2.0
    private static let swellAmount = 0.35
    private static let firstCatchDepth = 0.030
    private static let secondCatchDepth = 0.018

    /// A single smooth bump: zero at both ends, 1 in the middle.
    private static func arch(_ tau: Double, start: Double, width: Double) -> Double {
        let u = (tau - start) / width
        guard u > 0, u < 1 else { return 0 }
        return sin(.pi * u)
    }

    private static func smoothstep(_ x: Double) -> Double {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - The clock

/// Turning a state change into a shader clock.
///
/// The reason this is more than a multiply: the shaders receive `time` and
/// `speed` separately and use the product as their phase. If speed changes
/// while time is large, the product jumps, and every past second is
/// retroactively rescaled. At twenty seconds in, thinking to responding
/// would shove the field forward by several seconds in one frame. That is
/// the exact cut the eased crossfade exists to avoid.
///
/// So the view integrates the tempo into a PHASE and hands the shader
/// `phase / speed`. The product is then the phase itself, which is
/// continuous by construction. When the tempo is steady, which is almost
/// always, the integral is just elapsed time and nothing changes.
enum MurmurClock {
    /// Smoothstep, so the parameter crossfade has no corners at either end.
    static func ease(_ elapsed: Double) -> Double {
        let t = min(max(elapsed / MurmurState.transitionDuration, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// The tempo at tau: the crossfading speed times the entry's overshoot.
    static func tempo(
        at tau: Double,
        from previous: MurmurParameters,
        to current: MurmurParameters,
        entry: MurmurEntry
    ) -> Double {
        let t = ease(tau)
        let level = previous.speed * (1 - t) + current.speed * t
        return level * entry.speedBoost(at: tau)
    }

    /// Where the phase has got to, tau seconds into a segment.
    ///
    /// Past the horizon the tempo is constant, so that part is exact. Inside
    /// it the integrand is a smoothstep times an exponential, and Simpson on
    /// a fixed number of steps is both cheaper and clearer than the closed
    /// form of that product. Fixed steps also keep it deterministic: the
    /// same tau always returns the same phase.
    static func phase(
        through tau: Double,
        from previous: MurmurParameters,
        to current: MurmurParameters,
        entry: MurmurEntry
    ) -> Double {
        guard tau > 0 else { return 0 }
        let horizon = max(MurmurState.transitionDuration, entry.duration)
        let inner = min(tau, horizon)
        var total = simpson(to: inner) { s in
            tempo(at: s, from: previous, to: current, entry: entry)
        }
        if tau > horizon {
            total += (tau - horizon) * current.speed
        }
        return total
    }

    /// Composite Simpson over [0, b]. Thirty-two steps on a smooth integrand
    /// that never runs longer than a few seconds: the error is far below
    /// anything a display can show.
    private static func simpson(to b: Double, steps: Int = 32, _ f: (Double) -> Double) -> Double {
        guard b > 0 else { return 0 }
        let h = b / Double(steps)
        var sum = f(0) + f(b)
        for i in 1..<steps {
            sum += f(Double(i) * h) * (i.isMultiple(of: 2) ? 2 : 4)
        }
        return sum * h / 3
    }
}
