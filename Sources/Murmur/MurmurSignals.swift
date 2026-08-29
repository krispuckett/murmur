// Live signals. From Kris's responsive-presence reset: a presence that
// ignores its person is decoration.
//
// Two scalars, fed by the host every frame: `level` is voice energy off the
// mic, `activity` is typing cadence or token-stream rate. Both reach the
// shader as the last two uniforms, and the presence family builds a designed
// per-species response to them. Everything else gets a small generic lift
// applied here in Swift.
//
// Neither is Codable, because they are not part of a saved design. A
// configuration is what the thing looks like; signals are what is happening
// to it right now.

import Foundation

public struct MurmurSignals: Sendable, Equatable {
    /// Voice energy, 0 quiet to 1 loud. Values outside that range are
    /// clamped on the way to the shader rather than rejected here.
    public var level: Double
    /// Typing cadence or token-stream rate, 0 still to 1 fast.
    public var activity: Double

    public init(level: Double = 0, activity: Double = 0) {
        self.level = level
        self.activity = activity
    }

    /// Nothing happening. What a host that does not feed signals sends.
    public static let none = MurmurSignals()

    var clamped: MurmurSignals {
        MurmurSignals(
            level: min(max(level, 0), 1),
            activity: min(max(activity, 0), 1)
        )
    }

    // The generic response, applied to every species after the state design
    // has been interpolated. Deliberately small: this is the lift that keeps
    // the older families from ignoring the person, not their whole reaction.
    // A pack that wants more reads the raw uniforms and designs its own.

    /// Typing quickens the material by up to a quarter.
    static let activitySpeedLift = 0.25
    /// Voice lifts the light by up to a third.
    static let levelGlowLift = 0.35

    /// Rise time. Fast enough that a syllable lands, slow enough that the
    /// waveform's own jitter does not.
    static let attack = 0.05
    /// Fall time, five times the attack. Asymmetric on purpose: an envelope
    /// that decays as fast as it rises flickers on every gap between words.
    static let release = 0.25
}

/// Holds the smoothed signals between frames.
///
/// A reference type on purpose. The view steps it during body evaluation,
/// and mutating a class does not invalidate the view, which is what we want:
/// the TimelineView is already redrawing, and a state write mid-update would
/// be both illegal and a redraw loop. Stepping is idempotent within a frame,
/// so SwiftUI evaluating body more than once for the same tick cannot
/// double-advance the envelope.
///
/// Main-actor only in practice; the unchecked conformance is so a plain
/// `@State` property can hold it without dragging isolation through the view.
final class MurmurSignalEnvelope: @unchecked Sendable {
    private(set) var current = MurmurSignals.none
    /// The extra phase the activity lift has contributed. See the note in
    /// `step` for why this cannot be recomputed from a timestamp.
    private(set) var extraPhase: Double = 0
    private var lastTick: Date?

    /// Advance toward the host's latest values and return what to render.
    ///
    /// `baseTempo` is the tempo the state design alone asks for. The activity
    /// lift is integrated into `extraPhase` rather than multiplied onto the
    /// clock, for the same reason the state crossfade is integrated: the
    /// shaders use `time * speed` as their phase, so scaling speed against a
    /// large time would drag the whole field forward. Activity is a live
    /// signal that moves constantly, so doing that naively would be a
    /// continuous stream of jumps rather than one.
    func step(toward target: MurmurSignals, at date: Date, baseTempo: Double) -> MurmurSignals {
        let goal = target.clamped

        guard let last = lastTick else {
            // First frame: snap. A host that opens with the mic already hot
            // should not watch a quarter second of fake ramp.
            lastTick = date
            current = goal
            return current
        }
        guard date != last else { return current }

        // Clamped so a backgrounded view does not resume with one enormous
        // step that reads as a lurch.
        let dt = min(max(date.timeIntervalSince(last), 0), 0.25)
        lastTick = date

        current = MurmurSignals(
            level: Self.approach(current.level, goal.level, dt),
            activity: Self.approach(current.activity, goal.activity, dt)
        )
        extraPhase += dt * baseTempo * MurmurSignals.activitySpeedLift * current.activity
        return current
    }

    /// Reset alongside the shader clock, so a restarted arc does not inherit
    /// phase from before it.
    func resetPhase() {
        extraPhase = 0
    }

    /// Exponential approach with an asymmetric time constant. Written against
    /// dt rather than per frame so the envelope has the same shape at 30 fps
    /// and at 120.
    private static func approach(_ value: Double, _ target: Double, _ dt: Double) -> Double {
        let tau = target > value ? MurmurSignals.attack : MurmurSignals.release
        return value + (target - value) * (1 - exp(-dt / tau))
    }
}
