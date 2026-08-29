// The contract tests. These do not look at pixels; they guard the things a
// shader cannot guard for itself: that every style has four named knobs and
// a function to call, that a saved configuration comes back the way it went
// in, and that the export a designer hands to an agent actually carries the
// numbers.

import Foundation
import SwiftUI
import Testing
@testable import Murmur

@Test func versionExists() {
    #expect(!MurmurInfo.version.isEmpty)
}

// MARK: - Roster

@Test func rosterIsComplete() {
    #expect(MurmurStyle.allCases.count == 48)
    for style in MurmurStyle.allCases {
        #expect(style.characterKnobs.count == 4, "\(style.rawValue) knob count")
        #expect(!style.shaderName.isEmpty, "\(style.rawValue) shader name")
        #expect(!style.species.isEmpty, "\(style.rawValue) species line")
        #expect(style.id == style.rawValue)
        for knob in style.characterKnobs {
            #expect(!knob.label.isEmpty, "\(style.rawValue) knob label")
            #expect(knob.defaultValue >= 0 && knob.defaultValue <= 1, "\(style.rawValue) knob range")
        }
    }
}

@Test func shaderNamesCarryTheirFamilyPrefix() {
    for style in MurmurStyle.allCases {
        #expect(style.shaderName == style.family.shaderPrefix + style.rawValue)
    }
    #expect(MurmurStyle.eddy.shaderName == "ml_eddy")
    #expect(MurmurStyle.bloom.shaderName == "mi_bloom")
    #expect(MurmurStyle.caustic.shaderName == "mg_caustic")
    #expect(MurmurStyle.murmuration.shaderName == "ms_murmuration")
    #expect(MurmurStyle.breathe.shaderName == "mo_breathe")
    #expect(MurmurStyle.halo.shaderName == "mq_halo")
}

@Test func sixFamiliesOfEight() {
    #expect(MurmurFamily.allCases.count == 6)
    for family in MurmurFamily.allCases {
        #expect(family.styles.count == 8, "\(family.rawValue) style count")
    }
    // Every style lands in exactly one family, so the six sets partition
    // the roster rather than merely covering it.
    let grouped = MurmurFamily.allCases.flatMap(\.styles)
    #expect(Set(grouped) == Set(MurmurStyle.allCases))
    #expect(grouped.count == MurmurStyle.allCases.count)
}

@Test func familiesHaveDistinctPrefixesAndPackFiles() {
    #expect(Set(MurmurFamily.allCases.map(\.shaderPrefix)).count == 6)
    #expect(Set(MurmurFamily.allCases.map(\.packFileName)).count == 6)
    #expect(MurmurFamily.orb.shaderPrefix == "mo_")
    #expect(MurmurFamily.orb.packFileName == "MurmurOrb")
    #expect(MurmurFamily.presence.shaderPrefix == "mq_")
    #expect(MurmurFamily.presence.packFileName == "MurmurPresence")
}

@Test func arcStylesAreFlagged() {
    let expected: Set<MurmurStyle> = [
        .confluence, .bloom, .strata, .oculus, .tuning, .feather, .gather,
    ]
    let flagged = Set(MurmurStyle.allCases.filter(\.hasArc))
    #expect(flagged == expected)
}

@Test func newStylesCarryTheirRosterRow() {
    #expect(MurmurStyle.melt.family == .liquid)
    #expect(MurmurStyle.glaze.shaderName == "ml_glaze")
    #expect(MurmurStyle.feather.shaderName == "mi_feather")
    #expect(MurmurStyle.palimpsest.family == .ink)
    #expect(MurmurStyle.dapple.shaderName == "mg_dapple")
    #expect(MurmurStyle.eclipse.family == .light)
    #expect(MurmurStyle.echo.shaderName == "ms_echo")
    #expect(MurmurStyle.glyph.family == .signal)

    // The one knob default in the new rows that is not 0.5 or 0.4.
    #expect(MurmurStyle.melt.characterKnobs.map(\.label) == ["mass", "viscosity", "dripAbsorb", "heat"])
    #expect(MurmurStyle.melt.characterDefaults == [0.5, 0.6, 0.5, 0.4])
    #expect(MurmurStyle.glyph.characterKnobs.map(\.label) == ["marks", "formation", "dissolve", "ink"])
}

@Test func orbStylesCarryTheirRosterRow() {
    for style in MurmurFamily.orb.styles {
        #expect(style.family == .orb, "\(style.rawValue)")
        #expect(style.shaderName == "mo_" + style.rawValue, "\(style.rawValue)")
    }
    #expect(
        MurmurFamily.orb.styles
            == [.breathe, .orbit, .glimmer, .vortex, .gather, .stir, .daybreak, .skein]
    )
    // vortex is the only orb species whose first knob is not 0.5.
    #expect(MurmurStyle.vortex.characterDefaults == [0.6, 0.5, 0.5, 0.3])
    #expect(MurmurStyle.glimmer.characterDefaults == [0.5, 0.5, 0.5, 0.3])
    #expect(MurmurStyle.gather.hasArc)
}

@Test func everyOrbShapesTheSameLattice() {
    // The figure is always the sphere, so the family shares its last two
    // knobs. A pack author reading c2 or c3 as anything else would break the
    // one thing every orb species has in common.
    for style in MurmurFamily.orb.styles {
        let knobs = style.characterKnobs
        #expect(knobs[2].label == "dotSize", "\(style.rawValue) c2")
        #expect(knobs[3].label == "material", "\(style.rawValue) c3")
        // The material dial defaults the same everywhere: molten overshot,
        // so the family sits near the pale end out of the box.
        #expect(knobs[3].defaultValue == 0.3, "\(style.rawValue) material default")
    }
    // And no other family borrows those names.
    for style in MurmurStyle.allCases where style.family != .orb {
        let labels = style.characterKnobs.map(\.label)
        #expect(!labels.contains("dotSize"), "\(style.rawValue)")
        #expect(!labels.contains("material"), "\(style.rawValue)")
    }
}

@Test func presenceStylesCarryTheirRosterRow() {
    #expect(
        MurmurFamily.presence.styles
            == [.halo, .nucleus, .iris, .filament, .flare, .braid, .mote, .ripple]
    )
    for style in MurmurFamily.presence.styles {
        #expect(style.family == .presence, "\(style.rawValue)")
        #expect(style.shaderName == "mq_" + style.rawValue, "\(style.rawValue)")
        // The responsive cast is arc-free: their arrival is the signal
        // arriving, not a settle they run on their own.
        #expect(!style.hasArc, "\(style.rawValue) should not be an arc style")
    }
    #expect(MurmurStyle.halo.characterDefaults == [0.5, 0.4, 0.5, 0.4])
    #expect(MurmurStyle.mote.characterKnobs.map(\.label) == ["wander", "lean", "size", "tail"])
    #expect(MurmurStyle.mote.characterDefaults == [0.4, 0.5, 0.4, 0.3])
    #expect(MurmurStyle.flare.characterDefaults == [0.5, 0.5, 0.5, 0.3])
}

// MARK: - Live signals

@Test func signalsDefaultToNothingHappening() {
    let signals = MurmurSignals()
    #expect(signals.level == 0)
    #expect(signals.activity == 0)
    #expect(MurmurSignals.none == signals)
    #expect(MurmurSignals(level: 0.5).activity == 0)
    #expect(MurmurSignals(activity: 0.5).level == 0)
}

@Test func signalsClampRatherThanReject() {
    // A host feeding a hot mic must not push the shader out of range, and a
    // negative must not run the material backward.
    let hot = MurmurSignals(level: 3, activity: -2).clamped
    #expect(hot.level == 1)
    #expect(hot.activity == 0)
    // The stored value is left alone; only what reaches the shader is bounded.
    #expect(MurmurSignals(level: 3).level == 3)
}

@Test func theEnvelopeSnapsOnTheFirstFrameThenSmooths() {
    let envelope = MurmurSignalEnvelope()
    let start = Date(timeIntervalSinceReferenceDate: 0)

    // A host that opens with the mic already hot should not watch a fake ramp.
    let first = envelope.step(toward: MurmurSignals(level: 0.8), at: start, baseTempo: 1)
    #expect(first.level == 0.8)

    // Then it eases rather than cutting.
    let next = envelope.step(
        toward: MurmurSignals(level: 0), at: start.addingTimeInterval(0.02), baseTempo: 1
    )
    #expect(next.level < 0.8)
    #expect(next.level > 0.6, "a 20 ms step must not collapse a release")
}

@Test func theEnvelopeRisesFasterThanItFalls() {
    let step = 0.05
    func travel(from a: Double, to b: Double) -> Double {
        let envelope = MurmurSignalEnvelope()
        let start = Date(timeIntervalSinceReferenceDate: 0)
        _ = envelope.step(toward: MurmurSignals(level: a), at: start, baseTempo: 1)
        let moved = envelope.step(
            toward: MurmurSignals(level: b), at: start.addingTimeInterval(step), baseTempo: 1
        )
        return abs(moved.level - a)
    }
    // Same distance, same dt: the rise must cover more ground than the fall.
    // Asymmetry is what keeps gaps between words from reading as flicker.
    #expect(travel(from: 0, to: 1) > travel(from: 1, to: 0))
}

@Test func theEnvelopeConvergesAndIsIdempotentWithinAFrame() {
    let envelope = MurmurSignalEnvelope()
    var now = Date(timeIntervalSinceReferenceDate: 0)
    _ = envelope.step(toward: MurmurSignals(), at: now, baseTempo: 1)

    let target = MurmurSignals(level: 0.9, activity: 0.7)
    for _ in 0..<120 {
        now = now.addingTimeInterval(1.0 / 30.0)
        _ = envelope.step(toward: target, at: now, baseTempo: 1)
    }
    #expect(abs(envelope.current.level - 0.9) < 0.001)
    #expect(abs(envelope.current.activity - 0.7) < 0.001)

    // SwiftUI may evaluate body more than once per tick. A second call at the
    // same instant must not advance the envelope or double count the phase.
    let settled = envelope.current
    let phase = envelope.extraPhase
    let again = envelope.step(toward: MurmurSignals(level: 0), at: now, baseTempo: 1)
    #expect(again == settled)
    #expect(envelope.extraPhase == phase)
}

@Test func activityAccumulatesPhaseRatherThanScalingTheClock() {
    let envelope = MurmurSignalEnvelope()
    var now = Date(timeIntervalSinceReferenceDate: 0)
    _ = envelope.step(toward: MurmurSignals(activity: 1), at: now, baseTempo: 1)
    #expect(envelope.extraPhase == 0, "nothing accumulates before time passes")

    // One second at full activity and unit tempo adds the lift, once.
    for _ in 0..<60 {
        now = now.addingTimeInterval(1.0 / 60.0)
        _ = envelope.step(toward: MurmurSignals(activity: 1), at: now, baseTempo: 1)
    }
    #expect(abs(envelope.extraPhase - MurmurSignals.activitySpeedLift) < 0.01)

    // It only ever advances, so the field cannot be dragged backward when a
    // signal drops.
    let peak = envelope.extraPhase
    for _ in 0..<60 {
        now = now.addingTimeInterval(1.0 / 60.0)
        _ = envelope.step(toward: MurmurSignals(), at: now, baseTempo: 1)
    }
    #expect(envelope.extraPhase >= peak)

    envelope.resetPhase()
    #expect(envelope.extraPhase == 0)
}

@Test func theEnvelopeSurvivesABackgroundGap() {
    // Returning from background hands us one enormous dt. It must not arrive
    // as a lurch in the accumulated phase.
    let envelope = MurmurSignalEnvelope()
    let start = Date(timeIntervalSinceReferenceDate: 0)
    _ = envelope.step(toward: MurmurSignals(activity: 1), at: start, baseTempo: 1)
    _ = envelope.step(
        toward: MurmurSignals(activity: 1), at: start.addingTimeInterval(600), baseTempo: 1
    )
    #expect(envelope.extraPhase < 0.1, "a ten minute gap must be clamped")
}

// MARK: - States and treatments

@Test func everyStateSeedsAWholeDesign() {
    #expect(MurmurState.allCases.count == 6)
    for state in MurmurState.allCases {
        let p = state.seedParameters(for: .eddy)
        #expect(p.speed > 0, "\(state.rawValue) speed")
        #expect(p.glow > 0, "\(state.rawValue) glow")
        #expect(p.depth > 0, "\(state.rawValue) depth")
        #expect(p.formScale == 1, "\(state.rawValue) form scale")
        // Character always starts at the style's own tuning.
        #expect(p.character == MurmurStyle.eddy.characterDefaults, "\(state.rawValue) character")
    }
}

@Test func seedsFollowTheStyleTheyAreFor() {
    // The dials come from the state, the knobs from the style.
    for style in MurmurStyle.allCases {
        let p = MurmurState.idle.seedParameters(for: style)
        #expect(p.character == style.characterDefaults, "\(style.rawValue)")
        #expect(p.speed == MurmurState.idle.seedParameters(for: .eddy).speed)
    }
}

@Test func stateIndicesMatchTheShaderContract() {
    #expect(MurmurState.idle.shaderIndex == 0)
    #expect(MurmurState.listening.shaderIndex == 1)
    #expect(MurmurState.thinking.shaderIndex == 2)
    #expect(MurmurState.responding.shaderIndex == 3)
    #expect(MurmurState.success.shaderIndex == 4)
    #expect(MurmurState.error.shaderIndex == 5)

    // The index is the declaration order, and a pack branches on it, so the
    // two must not drift apart.
    for (offset, state) in MurmurState.allCases.enumerated() {
        #expect(state.shaderIndex == Double(offset), "\(state.rawValue)")
    }
    #expect(Set(MurmurState.allCases.map(\.shaderIndex)).count == 6)
}

@Test func entryDefaultsMatchTheBrief() {
    #expect(MurmurState.idle.defaultEntry == .none)
    #expect(MurmurState.listening.defaultEntry == .none)
    #expect(MurmurState.thinking.defaultEntry == .wake)
    #expect(MurmurState.responding.defaultEntry == .none)
    #expect(MurmurState.success.defaultEntry == .swell)
    #expect(MurmurState.error.defaultEntry == .stutter)

    // And a fresh configuration is seeded with exactly those.
    let config = MurmurConfiguration(style: .bloom)
    for state in MurmurState.allCases {
        #expect(config.entry(for: state) == state.defaultEntry, "\(state.rawValue)")
    }
}

@Test func errorWalksTheHueDownAndNothingElseMovesIt() {
    #expect(MurmurState.error.seedParameters(for: .eddy).hueShift < 0)
    for state in MurmurState.allCases where state != .error {
        #expect(state.seedParameters(for: .eddy).hueShift == 0, "\(state.rawValue) hue")
    }
}

@Test func tempoRisesFromIdleToResponding() {
    func speed(_ state: MurmurState) -> Double { state.seedParameters(for: .eddy).speed }
    // The ladder: resting, attentive, working, answering.
    #expect(speed(.idle) < speed(.listening))
    #expect(speed(.listening) < speed(.thinking))
    #expect(speed(.thinking) < speed(.responding))
    // Success is the settle after work, so it drops back below thinking.
    #expect(speed(.success) < speed(.thinking))
    // Error is slower than working but not as still as resting.
    #expect(speed(.idle) < speed(.error))
    #expect(speed(.error) < speed(.thinking))
}

@Test func idleAndThinkingAreObviouslyDifferent() {
    let idle = MurmurState.idle.seedParameters(for: .eddy)
    let thinking = MurmurState.thinking.seedParameters(for: .eddy)
    // Kris's bar: tell them apart from across a room. A narrow spread is
    // what the first table got wrong, so the gap is now a test.
    #expect(idle.speed <= thinking.speed * 0.35, "tempo spread too narrow")
    #expect(idle.glow <= thinking.glow * 0.6, "light spread too narrow")
    #expect(idle.depth < thinking.depth)
}

@Test func thinkingOpensTheMaterialUp() {
    // Thinking is the default state, so its design is the out-of-box look.
    // It has to do more than the raw material, not pass it through:
    // more motion, more light, more palette range.
    let thinking = MurmurState.thinking.seedParameters(for: .eddy)
    #expect(thinking.speed > 1, "more motion")
    #expect(thinking.glow > 1, "more light")
    #expect(thinking.depth > 1, "more color")

    // Idle is the other side of that: quieter than the raw material.
    let idle = MurmurState.idle.seedParameters(for: .eddy)
    #expect(idle.speed < 1)
    #expect(idle.glow < 1)
    #expect(idle.depth < 1)
}

@Test func respondingIsTheBrightestAndQuickest() {
    let responding = MurmurState.responding.seedParameters(for: .eddy)
    for state in MurmurState.allCases where state != .responding {
        let other = state.seedParameters(for: .eddy)
        #expect(responding.speed > other.speed, "quicker than \(state.rawValue)")
        #expect(responding.glow >= other.glow, "brighter than \(state.rawValue)")
    }
}

@Test func onlyThinkingAndSuccessRestartTheArc() {
    let restarting = Set(MurmurState.allCases.filter(\.restartsArc))
    #expect(restarting == [.thinking, .success])
}

@Test func blendLandsExactlyOnItsEndpointsAndCrossesEveryDial() {
    let a = MurmurState.idle.seedParameters(for: .eddy)
    var b = MurmurState.responding.seedParameters(for: .eddy)
    b.character = [0.9, 0.9, 0.9, 0.9]
    b.formScale = 1.6

    #expect(a.blended(toward: b, amount: 0) == a)
    #expect(a.blended(toward: b, amount: 1) == b)
    // Out of range clamps rather than overshooting.
    #expect(a.blended(toward: b, amount: -2) == a)
    #expect(a.blended(toward: b, amount: 5) == b)

    let mid = a.blended(toward: b, amount: 0.5)
    #expect(abs(mid.speed - (a.speed + b.speed) / 2) < 1e-12)
    #expect(abs(mid.glow - (a.glow + b.glow) / 2) < 1e-12)
    #expect(abs(mid.formScale - (a.formScale + b.formScale) / 2) < 1e-12)
    // The character knobs cross too. That is what makes a state change read
    // as one material rearranging rather than two materials swapped.
    for i in 0..<4 {
        #expect(abs(mid.character[i] - (a.character[i] + b.character[i]) / 2) < 1e-12, "knob \(i)")
    }
}

@Test func parametersResolveToFourKnobs() {
    var short = MurmurParameters(character: [0.9])
    #expect(short.resolvedCharacter(for: .eddy) == [0.9, 0.3, 0.4, 0.5])
    short.character = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]
    #expect(short.resolvedCharacter(for: .eddy) == [0.1, 0.2, 0.3, 0.4])
    #expect(short.resolved(for: .eddy).character.count == 4)
}

@Test func easeIsSmoothAndClamped() {
    let d = MurmurState.transitionDuration
    #expect(MurmurClock.ease(0) == 0)
    #expect(MurmurClock.ease(d) == 1)
    #expect(MurmurClock.ease(99) == 1)
    #expect(MurmurClock.ease(-1) == 0)
    #expect(abs(MurmurClock.ease(d / 2) - 0.5) < 1e-12)
    // Smoothstep starts slower than linear.
    #expect(MurmurClock.ease(d * 0.25) < 0.25)
}

@Test func stateCodableRoundTrip() throws {
    for state in MurmurState.allCases {
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(MurmurState.self, from: data) == state)
    }
}

// MARK: - Entry envelopes

@Test(arguments: MurmurEntry.allCases)
func entriesAreIdentityOutsideTheirWindow(entry: MurmurEntry) {
    // Before the change and after the envelope, an entry contributes nothing.
    for tau in [-1.0, 0.0, entry.duration, entry.duration + 1, 60.0] {
        #expect(entry.speedBoost(at: tau) == 1, "\(entry.rawValue) speed at \(tau)")
        #expect(entry.glowBoost(at: tau) == 1, "\(entry.rawValue) glow at \(tau)")
        #expect(entry.phaseOffset(at: tau) == 0, "\(entry.rawValue) phase at \(tau)")
    }
}

@Test func onlyOneEnvelopeMovesEachChannel() {
    // wake owns speed, swell owns glow, stutter owns phase. Crossing them
    // would make the entries read as each other.
    for entry in MurmurEntry.allCases {
        let mid = entry.duration / 2
        if entry != .wake { #expect(entry.speedBoost(at: mid) == 1, "\(entry.rawValue) speed") }
        if entry != .swell { #expect(entry.glowBoost(at: mid) == 1, "\(entry.rawValue) glow") }
        if entry != .stutter { #expect(entry.phaseOffset(at: mid) == 0, "\(entry.rawValue) phase") }
    }
}

@Test func wakeOvershootsThenDecays() {
    let wake = MurmurEntry.wake
    let early = wake.speedBoost(at: 0.01)
    #expect(early > 1.5, "the overshoot should be felt immediately")
    #expect(early < 1.7)
    // Monotonically decaying back toward the steady tempo.
    var previous = early
    for tau in stride(from: 0.1, through: 2.4, by: 0.1) {
        let value = wake.speedBoost(at: tau)
        #expect(value < previous, "wake should keep decaying at \(tau)")
        previous = value
    }
    #expect(previous < 1.01, "and be spent by the end of its window")
}

@Test func swellRisesToItsPeakAndGoesAway() {
    let swell = MurmurEntry.swell
    #expect(swell.glowBoost(at: 0.01) < 1.02, "starts from nothing, never pops")
    let peak = swell.glowBoost(at: 0.4)
    #expect(peak > 1.3 && peak < 1.4, "peaks near a third brighter")
    #expect(swell.glowBoost(at: 0.2) < peak)
    #expect(swell.glowBoost(at: 0.8) < peak)
    #expect(swell.glowBoost(at: 1.45) < 1.01, "and is gone by its duration")
}

@Test func stutterCatchesTwiceAndStaysReadable() {
    let stutter = MurmurEntry.stutter
    let samples = stride(from: 0.0, through: 0.5, by: 0.002).map {
        (tau: $0, offset: stutter.phaseOffset(at: $0))
    }
    // The clock lags, never runs ahead.
    #expect(samples.allSatisfy { $0.offset <= 0 })

    // Two distinct catches, both inside the first half second.
    let catches = samples.filter { $0.offset < -0.005 }
    #expect(!catches.isEmpty)
    #expect(catches.allSatisfy { $0.tau < 0.5 })
    let gap = zip(catches, catches.dropFirst()).contains { $1.tau - $0.tau > 0.02 }
    #expect(gap, "the two catches should be separated, not one long hold")

    // The rate never reverses or stalls: that is the line between a catch
    // and a glitch. The offset's slope must stay above minus one.
    let slopes = zip(samples, samples.dropFirst()).map { ($1.offset - $0.offset) / 0.002 }
    #expect(slopes.allSatisfy { $0 > -0.8 }, "a catch, never a freeze")
}

// MARK: - The phase clock

@Test func steadyTempoIntegratesToPlainElapsedTime() {
    // Nothing changing: the phase is just tau times the speed, which is
    // what keeps `time` equal to elapsed seconds in the common case.
    let p = MurmurState.responding.seedParameters(for: .eddy)
    for tau in [0.25, 1.0, 5.0, 30.0] {
        let phase = MurmurClock.phase(through: tau, from: p, to: p, entry: .none)
        #expect(abs(phase - tau * p.speed) < 1e-9, "at \(tau)")
    }
}

@Test func phaseIsContinuousAndMonotonicAcrossAChange() {
    let from = MurmurState.thinking.seedParameters(for: .eddy)
    let to = MurmurState.error.seedParameters(for: .eddy)
    let entry = MurmurState.error.defaultEntry

    #expect(MurmurClock.phase(through: 0, from: from, to: to, entry: entry) == 0)
    #expect(MurmurClock.phase(through: -1, from: from, to: to, entry: entry) == 0)

    // No step anywhere: consecutive samples advance by roughly the tempo,
    // never by a jump. This is the whole reason the clock integrates.
    var previous = 0.0
    for tau in stride(from: 0.01, through: 4.0, by: 0.01) {
        let phase = MurmurClock.phase(through: tau, from: from, to: to, entry: entry)
        let step = phase - previous
        #expect(step > 0, "phase must always advance, at \(tau)")
        #expect(step < 0.02, "and never jump, at \(tau)")
        previous = phase
    }
}

@Test func phaseMatchesTheClosedFormPastTheHorizon() {
    let from = MurmurState.idle.seedParameters(for: .eddy)
    let to = MurmurState.thinking.seedParameters(for: .eddy)
    let entry = MurmurEntry.wake
    let horizon = max(MurmurState.transitionDuration, entry.duration)
    let atHorizon = MurmurClock.phase(through: horizon, from: from, to: to, entry: entry)
    let later = MurmurClock.phase(through: horizon + 10, from: from, to: to, entry: entry)
    #expect(abs(later - (atHorizon + 10 * to.speed)) < 1e-9)
}

// MARK: - Configuration

@Test func initSeedsEveryState() {
    for style in MurmurStyle.allCases {
        let config = MurmurConfiguration(style: style)
        #expect(config.ink == .ink)
        #expect(config.tone == .tone)
        #expect(config.states.count == 6)
        #expect(config.entries.count == 6)
        #expect(config.customizedStates.isEmpty)
        for state in MurmurState.allCases {
            #expect(
                config.parameters(for: state) == state.seedParameters(for: style),
                "\(style.rawValue) \(state.rawValue)"
            )
        }
        // Spot check the shape the seeds are supposed to have.
        #expect(config.parameters(for: .idle).speed < config.parameters(for: .thinking).speed)
        #expect(config.parameters(for: .error).hueShift < 0)
    }
}

@Test func lookupSurvivesAMissingKey() {
    var config = MurmurConfiguration(style: .eddy)
    config.states.removeValue(forKey: .error)
    config.entries.removeValue(forKey: .error)
    // A dictionary that lost a key still answers with the seed, so a
    // partial decode can never hand the view a nil.
    #expect(config.parameters(for: .error) == MurmurState.error.seedParameters(for: .eddy))
    #expect(config.entry(for: .error) == .stutter)
    #expect(config.customizedStates.isEmpty)
}

@Test func editingOneStateLeavesTheOthersAlone() {
    // Kris's workflow: tune idle, save it, move on to thinking. Editing one
    // state must not disturb a design already finished elsewhere.
    var config = MurmurConfiguration(style: .melt)
    let thinkingBefore = config.parameters(for: .thinking)

    var idle = config.parameters(for: .idle)
    idle.speed = 0.12
    idle.character = [0.1, 0.2, 0.3, 0.4]
    config.states[.idle] = idle

    #expect(config.parameters(for: .thinking) == thinkingBefore)
    #expect(config.customizedStates == [.idle])
    #expect(config.parameters(for: .idle).speed == 0.12)
}

@Test func copyDesignCarriesOneStateOntoOthers() {
    var config = MurmurConfiguration(style: .glaze)
    var tuned = config.parameters(for: .thinking)
    tuned.glow = 1.9
    tuned.character = [0.7, 0.7, 0.7, 0.7]
    config.states[.thinking] = tuned

    config.copyDesign(from: .thinking, to: [.responding, .success])
    #expect(config.parameters(for: .responding) == tuned)
    #expect(config.parameters(for: .success) == tuned)
    // The entry is meaning, not look, so it does not travel.
    #expect(config.entry(for: .success) == .swell)
    #expect(config.entry(for: .responding) == .none)
    // And a state that was not a target is untouched.
    #expect(config.parameters(for: .idle) == MurmurState.idle.seedParameters(for: .glaze))
}

@Test func resetToSeedUndoesAState() {
    var config = MurmurConfiguration(style: .echo)
    config.states[.error] = MurmurParameters(speed: 9, glow: 9)
    config.entries[.error] = .wake
    #expect(config.customizedStates == [.error])

    config.resetToSeed(.error)
    #expect(config.customizedStates.isEmpty)
    #expect(config.entry(for: .error) == .stutter)
}

@Test func switchingStyleKeepsTheDialsAndTakesTheNewKnobs() {
    var config = MurmurConfiguration(style: .eddy)
    var thinking = config.parameters(for: .thinking)
    thinking.speed = 1.4
    config.states[.thinking] = thinking
    config.tone = MurmurRGBA(r: 0.2, g: 0.6, b: 0.9)

    let moved = config.withStyle(.tuning)
    #expect(moved.style == .tuning)
    #expect(moved.tone == config.tone)
    #expect(moved.parameters(for: .thinking).speed == 1.4, "tuned dials come across")
    for state in MurmurState.allCases {
        #expect(
            moved.parameters(for: state).character == MurmurStyle.tuning.characterDefaults,
            "\(state.rawValue) knobs reseed"
        )
    }
}

@Test func codableRoundTripWithTwoCustomStates() throws {
    var config = MurmurConfiguration(style: .murmuration)
    config.ink = MurmurRGBA(r: 0.02, g: 0.03, b: 0.05)
    config.tone = MurmurRGBA(r: 0.4, g: 0.7, b: 0.95, a: 0.9)
    config.states[.idle] = MurmurParameters(
        speed: 0.12, formScale: 1.4, depth: 0.6, glow: 0.4,
        hueShift: 0.1, character: [0.11, 0.22, 0.33, 0.44]
    )
    config.states[.success] = MurmurParameters(
        speed: 0.8, formScale: 0.9, depth: 1.6, glow: 1.5,
        hueShift: -0.2, character: [0.9, 0.8, 0.7, 0.6]
    )
    config.entries[.responding] = .swell

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(MurmurConfiguration.self, from: data)
    #expect(decoded == config)
    #expect(decoded.customizedStates == [.idle, .responding, .success])
    #expect(decoded.parameters(for: .idle).character == [0.11, 0.22, 0.33, 0.44])
    #expect(decoded.entry(for: .responding) == .swell)
    // Untouched states came back as seeds, not as nil.
    #expect(decoded.parameters(for: .error) == MurmurState.error.seedParameters(for: .murmuration))
}

@Test func aTrimmedConfigFillsItselfIn() throws {
    // Only the style and colors, no state dictionaries at all.
    let trimmed = """
    {"style":"eddy",
     "ink":{"r":0.039,"g":0.039,"b":0.043,"a":1},
     "tone":{"r":0.878,"g":0.545,"b":0.235,"a":1}}
    """
    let decoded = try JSONDecoder().decode(
        MurmurConfiguration.self, from: Data(trimmed.utf8)
    )
    #expect(decoded.style == .eddy)
    #expect(decoded.states.count == 6)
    #expect(decoded.customizedStates.isEmpty)
}

@Test func colorBridgeRoundTrips() {
    let original = MurmurRGBA(r: 0.42, g: 0.68, b: 0.91, a: 0.8)
    let back = MurmurRGBA(original.color)
    // Float precision in Color.Resolved, so this is a closeness check.
    #expect(abs(back.r - original.r) < 0.001)
    #expect(abs(back.g - original.g) < 0.001)
    #expect(abs(back.b - original.b) < 0.001)
    #expect(abs(back.a - original.a) < 0.001)
}

@Test func hexStrings() {
    #expect(MurmurRGBA.ink.hexString == "#0A0A0B")
    #expect(MurmurRGBA.tone.hexString == "#E08B3C")
    #expect(MurmurRGBA(r: 1, g: 1, b: 1, a: 0.5).hexString == "#FFFFFF80")
}

// MARK: - Agent export

@Test(arguments: MurmurExportSurface.allCases)
func agentPromptCarriesTheConfiguration(surface: MurmurExportSurface) {
    let config = MurmurConfiguration(style: .eddy)
    let prompt = config.agentPrompt(as: surface)

    #expect(prompt.contains("eddy"))
    #expect(prompt.contains("ml_eddy"))
    for knob in MurmurStyle.eddy.characterKnobs {
        #expect(prompt.contains(knob.label), "missing knob label \(knob.label)")
    }
    #expect(prompt.contains("#0A0A0B"))
    #expect(prompt.contains("#E08B3C"))
    #expect(prompt.contains("```swift"))
    #expect(!prose(of: prompt).contains("\u{2014}"), "em dash in generated prose")

    // The states have to reach whoever implements this, or the pill says
    // "thinking" while the answer is already streaming.
    #expect(prompt.contains("Driving the state"))
    for state in MurmurState.allCases {
        #expect(prompt.contains(state.rawValue), "missing state \(state.rawValue)")
    }
}

/// The prose and Swift the exporter writes, without the pack source it may
/// append. House rules apply to what Murmur generates, not to a shader file
/// another owner wrote.
private func prose(of prompt: String) -> String {
    guard let fence = prompt.range(of: "```metal") else { return prompt }
    return String(prompt[prompt.startIndex..<fence.lowerBound])
}

@Test func everyStyleExportsForEverySurface() {
    for style in MurmurStyle.allCases {
        let config = MurmurConfiguration(style: style)
        for surface in MurmurExportSurface.allCases {
            let prompt = config.agentPrompt(as: surface)
            #expect(prompt.contains(style.shaderName), "\(style.rawValue) \(surface.rawValue)")
            #expect(prompt.contains(style.species), "\(style.rawValue) \(surface.rawValue)")
            #expect(
                !prose(of: prompt).contains("\u{2014}"),
                "\(style.rawValue) \(surface.rawValue) em dash"
            )
        }
    }
}

@Test func aSeededConfigWritesNoMutations() {
    let prompt = MurmurConfiguration(style: .pool).agentPrompt(as: .pill)
    #expect(prompt.contains("static let murmur = MurmurConfiguration(style: .pool)"))
    #expect(!prompt.contains("c.states["))
    #expect(!prompt.contains("c.entries["))
    #expect(!prompt.contains("c.ink ="))
    #expect(!prompt.contains("customized"))
    // The five designs are still listed in prose, seeds and all.
    for state in MurmurState.allCases {
        #expect(prompt.contains("\(state.rawValue) (entry "), "missing \(state.rawValue) block")
    }
}

@Test func exportCarriesOnlyTheChangedStates() {
    var config = MurmurConfiguration(style: .glyph)
    config.states[.error] = MurmurParameters(
        speed: 0.25, formScale: 1.3, depth: 1.4, glow: 0.5,
        hueShift: -0.8, character: [0.81, 0.62, 0.43, 0.24]
    )
    config.entries[.idle] = .swell
    let prompt = config.agentPrompt(as: .pill)

    #expect(prompt.contains("c.states[.error] = MurmurParameters("))
    #expect(prompt.contains("speed: 0.25"))
    #expect(prompt.contains("hueShift: -0.8"))
    #expect(prompt.contains("character: [0.81, 0.62, 0.43, 0.24]"))
    // The knob labels ride along as a comment so the numbers mean something.
    #expect(prompt.contains("marks, formation, dissolve, ink"))
    #expect(prompt.contains("c.entries[.idle] = .swell"))
    #expect(prompt.contains("customized"))
    // Only what departed from the seed is written.
    #expect(!prompt.contains("c.states[.idle]"))
    #expect(!prompt.contains("c.states[.thinking]"))
    #expect(!prompt.contains("c.entries[.error]"))
    #expect(!prose(of: prompt).contains("\u{2014}"))
}

@Test func exportListsEveryDesignWithItsValues() {
    let config = MurmurConfiguration(style: .eddy)
    let prompt = config.agentPrompt(as: .indicator)
    for state in MurmurState.allCases {
        let p = config.resolvedParameters(for: state)
        #expect(
            prompt.contains("speed \(MurmurExport.number(p.speed)),"),
            "missing \(state.rawValue) speed"
        )
    }
    // Knob labels appear with each design.
    for knob in MurmurStyle.eddy.characterKnobs {
        #expect(prompt.contains(knob.label), "missing \(knob.label)")
    }
}

@Test func exportExplainsTheShaderStateUniforms() {
    let prompt = MurmurConfiguration(style: .eddy).agentPrompt(as: .swiftUIOnly)
    #expect(prompt.contains("stateIndex"))
    #expect(prompt.contains("stateTau"))
    #expect(prompt.contains("0 idle"))
    #expect(prompt.contains("1 listening"))
    #expect(prompt.contains("5 error"))
}

@Test(arguments: MurmurExportSurface.allCases)
func exportExplainsTheLiveSignals(surface: MurmurExportSurface) {
    // An agent that wires the states but not the signals has built half of
    // this, so the prompt has to carry both.
    let prompt = MurmurConfiguration(style: .halo).agentPrompt(as: surface)
    #expect(prompt.contains("level"))
    #expect(prompt.contains("activity"))
    #expect(prompt.contains("microphone"))
    #expect(!prose(of: prompt).contains("\u{2014}"))

    switch surface {
    case .pill:
        #expect(prompt.contains("MurmurPill(Self.murmur, state: state, signals: MurmurSignals("))
    case .indicator:
        #expect(prompt.contains("MurmurView(Self.murmur, state: state, signals: MurmurSignals("))
    case .swiftUIOnly:
        #expect(prompt.contains("last two shader arguments"))
    }
}

@Test func exportNamesEveryEntry() {
    let prompt = MurmurConfiguration(style: .eddy).agentPrompt(as: .indicator)
    for entry in MurmurEntry.allCases {
        #expect(prompt.contains("entry \(entry.rawValue)") || prompt.contains("- \(entry.rawValue):"),
                "missing entry \(entry.rawValue)")
    }
}

@Test func defaultConfigurationSnippetIsOneLine() {
    let prompt = MurmurConfiguration(style: .aurora).agentPrompt(as: .indicator)
    #expect(prompt.contains("static let murmur = MurmurConfiguration(style: .aurora)"))
    // The snippet takes a state, because a host that cannot change state has
    // bought a spinner with extra steps.
    #expect(prompt.contains("MurmurView(Self.murmur, state: state)"))
    #expect(prompt.contains("var state: MurmurState = .thinking"))
}

@Test func numberFormattingStaysDoubleLiteral() {
    #expect(MurmurExport.number(1) == "1.0")
    #expect(MurmurExport.number(0) == "0.0")
    #expect(MurmurExport.number(0.5) == "0.5")
    #expect(MurmurExport.number(1.25) == "1.25")
    #expect(MurmurExport.number(0.235) == "0.235")
}
