// AI states and their treatments. From Kris's device review: one indicator
// should be able to say what the agent is doing without becoming a different
// object, and it has to say it as MOTION. Someone who cannot read the label
// should still know idle from thinking from error.
//
// The mechanism is deliberately Swift-side. Nothing here reaches the Metal;
// a state scales the uniforms the shaders already take, so every one of the
// 32 species gets all five states for free and a pack author never has to
// think about them. That also keeps the taste rule intact: error walks the
// existing hue family toward dark ember rather than introducing a second
// hue, because a red alarm dot next to warm amber is two materials.
//
// A treatment has two halves. The LEVELS (speed, glow, depth, hue) are where
// the state rests, and they crossfade over transitionDuration. The ENTRY is
// what the change itself looks like, a one-shot envelope measured from the
// instant of the change. Levels tell you where you are; the entry tells you
// that you just arrived.
//
// This file is the single place these numbers live. Tune here.

import Foundation

public enum MurmurState: String, CaseIterable, Codable, Sendable {
    /// Present, waiting, doing nothing. The material at its quietest.
    case idle
    /// Working. The designed tempo of every style.
    case thinking
    /// Streaming an answer out. Quicker and brighter.
    case responding
    /// Arrival. Slows and settles, and restarts the arc on styles that have one.
    case success
    /// Something went wrong. Dimmer, denser, and walked down the hue family.
    case error

    public var displayName: String { rawValue.capitalized }

    /// The tuned numbers. Starting points from the device review.
    public var defaultTreatment: MurmurStateTreatment {
        switch self {
        // Slow and dim, but never stopped. A frozen indicator reads as a
        // broken shader, which is the lesson the atmosphere field already
        // taught us. Nothing announces idle, so there is no entry.
        case .idle:
            MurmurStateTreatment(
                speedFactor: 0.45, glowFactor: 0.70, depthFactor: 0.85,
                hueShiftDelta: 0, entry: .none
            )
        // Waking is the point: a thought starting should look like something
        // took a breath in, not like a loop that was already running.
        case .thinking:
            MurmurStateTreatment(
                speedFactor: 1.00, glowFactor: 1.00, depthFactor: 1.00,
                hueShiftDelta: 0, entry: .wake
            )
        // The one state the eye should notice changing. Faster and a little
        // brighter, not louder: the ceiling stays dim. No entry, because
        // streaming is a continuation of thinking rather than an event.
        case .responding:
            MurmurStateTreatment(
                speedFactor: 1.35, glowFactor: 1.15, depthFactor: 1.00,
                hueShiftDelta: 0, entry: .none
            )
        // The completion breath. Brightness holds while the motion drops,
        // so arrival reads as settling rather than as stopping, and the
        // swell is the moment of arrival itself.
        case .success:
            MurmurStateTreatment(
                speedFactor: 0.60, glowFactor: 1.05, depthFactor: 1.00,
                hueShiftDelta: 0, entry: .swell
            )
        // Down the rail, not off it. The negative hue walk takes the amber
        // family toward dark ember; deeper palette range carries the weight
        // that the lost glow used to; the stutter is the material catching.
        case .error:
            MurmurStateTreatment(
                speedFactor: 0.70, glowFactor: 0.85, depthFactor: 1.15,
                hueShiftDelta: -0.35, entry: .stutter
            )
        }
    }

    /// Entering these is an arrival, so the arc styles (confluence, bloom,
    /// strata, oculus, tuning, feather) run their approach again from that
    /// moment. Thinking is a thought starting; success is the completion.
    public var restartsArc: Bool {
        self == .thinking || self == .success
    }
}

/// Dictionary keys encode as "idle", "thinking" and so on rather than as an
/// alternating array, which is what a Dictionary with a non-string key would
/// otherwise produce. The stdlib supplies the whole conformance for a string
/// raw value, so this is a one-line opt in.
extension MurmurState: CodingKeyRepresentable {}

// MARK: - Entry envelopes

/// What a state change looks like in the instant it happens. Every envelope
/// is a pure function of tau, the seconds since the change, so any frame can
/// be rendered from the timestamp alone.
public enum MurmurEntry: String, CaseIterable, Codable, Sendable {
    /// Nothing. The levels crossfade and that is the whole change.
    case none
    /// A brief speed overshoot that decays in. The material wakes up.
    case wake
    /// A glow envelope that rises and settles. The arrival breath.
    case swell
    /// Two quick catches of the clock, then a clean settle. The error catch.
    case stutter

    public var displayName: String { rawValue.capitalized }

    /// When the envelope is finished. Past this the steady treatment is all
    /// that is left, so the phase integral below can stop working and just
    /// run out at a constant rate.
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

// MARK: - Treatments

/// What a state does to the uniforms, and how it announces itself.
/// Factors multiply, the hue delta adds, the entry runs once on arrival.
public struct MurmurStateTreatment: Codable, Sendable, Equatable {
    public var speedFactor: Double
    public var glowFactor: Double
    public var depthFactor: Double
    public var hueShiftDelta: Double
    public var entry: MurmurEntry

    public init(
        speedFactor: Double,
        glowFactor: Double,
        depthFactor: Double,
        hueShiftDelta: Double = 0,
        entry: MurmurEntry = .none
    ) {
        self.speedFactor = speedFactor
        self.glowFactor = glowFactor
        self.depthFactor = depthFactor
        self.hueShiftDelta = hueShiftDelta
        self.entry = entry
    }

    /// The stock table, keyed by state. A configuration starts here.
    public static let defaults: [MurmurState: MurmurStateTreatment] = Dictionary(
        uniqueKeysWithValues: MurmurState.allCases.map { ($0, $0.defaultTreatment) }
    )

    /// How long the levels take to cross. A cut reads as a different
    /// indicator; this reads as a change of mind.
    public static let transitionDuration: Double = 0.6

    /// Levels only. The entry belongs to the state being entered and does
    /// not average with anything.
    ///
    /// Written as `a * (1 - t) + b * t` rather than `a + (b - a) * t` so the
    /// ends land exactly on the endpoints instead of near them.
    public func blended(toward other: MurmurStateTreatment, amount: Double) -> MurmurStateTreatment {
        let t = min(max(amount, 0), 1)
        func mix(_ a: Double, _ b: Double) -> Double { a * (1 - t) + b * t }
        return MurmurStateTreatment(
            speedFactor: mix(speedFactor, other.speedFactor),
            glowFactor: mix(glowFactor, other.glowFactor),
            depthFactor: mix(depthFactor, other.depthFactor),
            hueShiftDelta: mix(hueShiftDelta, other.hueShiftDelta),
            entry: other.entry
        )
    }
}

// MARK: - The clock

/// Turning a state change into a shader clock.
///
/// The reason this is more than a multiply: the shaders receive `time` and
/// `speed` separately and use the product as their phase. If speed changes
/// while time is large, the product jumps, and every past second is
/// retroactively rescaled. At twenty seconds in, thinking to responding
/// would shove the field forward by seven seconds in one frame. That is the
/// exact cut the eased crossfade exists to avoid.
///
/// So the view integrates the tempo into a PHASE and hands the shader
/// `phase / speed`. The product is then the phase itself, which is
/// continuous by construction. When the tempo is steady, which is almost
/// always, the integral is just elapsed time and nothing changes.
enum MurmurClock {
    /// Smoothstep, so the level crossfade has no corners at either end.
    static func ease(_ elapsed: Double) -> Double {
        let t = min(max(elapsed / MurmurStateTreatment.transitionDuration, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// The tempo multiplier at tau: the crossfading level times the entry.
    static func tempo(
        at tau: Double,
        from previous: MurmurStateTreatment,
        to current: MurmurStateTreatment,
        entry: MurmurEntry
    ) -> Double {
        let level = previous.blended(toward: current, amount: ease(tau))
        return level.speedFactor * entry.speedBoost(at: tau)
    }

    /// Where the phase has got to, tau seconds into a segment, for a
    /// configuration speed of 1.
    ///
    /// Past the horizon the tempo is constant, so that part is exact. Inside
    /// it the integrand is a smoothstep times an exponential, and Simpson on
    /// a fixed number of steps is both cheaper and clearer than the closed
    /// form of that product. Fixed steps also keep it deterministic: the
    /// same tau always returns the same phase.
    static func phase(
        through tau: Double,
        from previous: MurmurStateTreatment,
        to current: MurmurStateTreatment,
        entry: MurmurEntry
    ) -> Double {
        guard tau > 0 else { return 0 }
        let horizon = max(MurmurStateTreatment.transitionDuration, entry.duration)
        let inner = min(tau, horizon)
        var total = simpson(to: inner) { s in
            tempo(at: s, from: previous, to: current, entry: entry)
        }
        if tau > horizon {
            total += (tau - horizon) * current.speedFactor
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
