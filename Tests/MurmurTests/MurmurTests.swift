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
    #expect(MurmurStyle.allCases.count == 32)
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
}

@Test func eachFamilyHoldsEightStyles() {
    for family in MurmurFamily.allCases {
        #expect(family.styles.count == 8, "\(family.rawValue) style count")
    }
    // Every style lands in exactly one family, so the four sets partition
    // the roster rather than merely covering it.
    let grouped = MurmurFamily.allCases.flatMap(\.styles)
    #expect(Set(grouped) == Set(MurmurStyle.allCases))
    #expect(grouped.count == MurmurStyle.allCases.count)
}

@Test func arcStylesAreFlagged() {
    let expected: Set<MurmurStyle> = [.confluence, .bloom, .strata, .oculus, .tuning, .feather]
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

// MARK: - States and treatments

@Test func everyStateHasADefaultTreatment() {
    #expect(MurmurState.allCases.count == 5)
    for state in MurmurState.allCases {
        let t = state.defaultTreatment
        #expect(t.speedFactor > 0, "\(state.rawValue) speed")
        #expect(t.glowFactor > 0, "\(state.rawValue) glow")
        #expect(t.depthFactor > 0, "\(state.rawValue) depth")
        // The stock table is what a fresh configuration is prefilled with.
        #expect(MurmurStateTreatment.defaults[state] == t, "\(state.rawValue) in defaults")
    }
    #expect(MurmurStateTreatment.defaults.count == 5)
}

@Test func entryDefaultsMatchTheBrief() {
    #expect(MurmurState.idle.defaultTreatment.entry == .none)
    #expect(MurmurState.thinking.defaultTreatment.entry == .wake)
    #expect(MurmurState.responding.defaultTreatment.entry == .none)
    #expect(MurmurState.success.defaultTreatment.entry == .swell)
    #expect(MurmurState.error.defaultTreatment.entry == .stutter)
}

@Test func errorWalksTheHueDownAndNothingElseMovesIt() {
    #expect(MurmurState.error.defaultTreatment.hueShiftDelta < 0)
    for state in MurmurState.allCases where state != .error {
        #expect(state.defaultTreatment.hueShiftDelta == 0, "\(state.rawValue) hue")
    }
}

@Test func tempoRisesFromIdleToResponding() {
    let idle = MurmurState.idle.defaultTreatment.speedFactor
    let thinking = MurmurState.thinking.defaultTreatment.speedFactor
    let responding = MurmurState.responding.defaultTreatment.speedFactor
    #expect(idle < thinking)
    #expect(thinking < responding)
    // Success is the settle after work, so it drops back below thinking.
    #expect(MurmurState.success.defaultTreatment.speedFactor < thinking)
}

@Test func onlyThinkingAndSuccessRestartTheArc() {
    let restarting = Set(MurmurState.allCases.filter(\.restartsArc))
    #expect(restarting == [.thinking, .success])
}

@Test func blendLandsExactlyOnItsEndpoints() {
    let a = MurmurState.idle.defaultTreatment
    let b = MurmurState.responding.defaultTreatment
    #expect(a.blended(toward: b, amount: 0) == a)
    #expect(a.blended(toward: b, amount: 1) == b)
    // Out of range clamps rather than overshooting.
    #expect(a.blended(toward: b, amount: -2) == a)
    #expect(a.blended(toward: b, amount: 5) == b)

    let mid = a.blended(toward: b, amount: 0.5)
    #expect(abs(mid.speedFactor - (a.speedFactor + b.speedFactor) / 2) < 1e-12)
    #expect(abs(mid.glowFactor - (a.glowFactor + b.glowFactor) / 2) < 1e-12)
    // The entry belongs to the state being entered; it never averages.
    #expect(mid.entry == b.entry)
}

@Test func easeIsSmoothAndClamped() {
    let d = MurmurStateTreatment.transitionDuration
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
    // Nothing changing: the phase is just tau times the factor, which is
    // what keeps `time` equal to elapsed seconds in the common case.
    let t = MurmurState.responding.defaultTreatment
    for tau in [0.25, 1.0, 5.0, 30.0] {
        let phase = MurmurClock.phase(through: tau, from: t, to: t, entry: .none)
        #expect(abs(phase - tau * t.speedFactor) < 1e-9, "at \(tau)")
    }
}

@Test func phaseIsContinuousAndMonotonicAcrossAChange() {
    let from = MurmurState.thinking.defaultTreatment
    let to = MurmurState.error.defaultTreatment
    let entry = to.entry

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
    let from = MurmurState.idle.defaultTreatment
    let to = MurmurState.thinking.defaultTreatment
    let entry = MurmurEntry.wake
    let horizon = max(MurmurStateTreatment.transitionDuration, entry.duration)
    let atHorizon = MurmurClock.phase(through: horizon, from: from, to: to, entry: entry)
    let later = MurmurClock.phase(through: horizon + 10, from: from, to: to, entry: entry)
    #expect(abs(later - (atHorizon + 10 * to.speedFactor)) < 1e-9)
}

// MARK: - Configuration

@Test func initFillsStyleDefaults() {
    for style in MurmurStyle.allCases {
        let config = MurmurConfiguration(style: style)
        #expect(config.character == style.characterDefaults)
        #expect(config.resolvedCharacter.count == 4)
        #expect(config.speed == 1)
        #expect(config.formScale == 1)
        #expect(config.depth == 1)
        #expect(config.glow == 1)
        #expect(config.hueShift == 0)
        #expect(config.ink == .ink)
        #expect(config.tone == .tone)
        #expect(config.treatments == MurmurStateTreatment.defaults)
        #expect(config.customizedStates.isEmpty)
    }
}

@Test func treatmentLookupSurvivesAMissingKey() {
    var config = MurmurConfiguration(style: .eddy)
    config.treatments.removeValue(forKey: .error)
    // A dictionary that lost a key still answers with the stock treatment,
    // so a partial decode can never hand the view a nil.
    #expect(config.treatment(for: .error) == MurmurState.error.defaultTreatment)
    #expect(config.customizedStates.isEmpty)
}

@Test func customTreatmentSurvivesACodableRoundTrip() throws {
    var config = MurmurConfiguration(style: .feather)
    let custom = MurmurStateTreatment(
        speedFactor: 1.8, glowFactor: 1.4, depthFactor: 0.9,
        hueShiftDelta: 0.2, entry: .swell
    )
    config.treatments[.responding] = custom

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(MurmurConfiguration.self, from: data)
    #expect(decoded == config)
    #expect(decoded.treatment(for: .responding) == custom)
    #expect(decoded.customizedStates == [.responding])
    // The untouched states came back as the defaults, not as nil.
    #expect(decoded.treatment(for: .idle) == MurmurState.idle.defaultTreatment)
}

@Test func aConfigSavedBeforeTreatmentsExistedStillDecodes() throws {
    let legacy = """
    {"style":"eddy","speed":1,"formScale":1,"depth":1,"glow":1,"hueShift":0,
     "character":[0.5,0.3,0.4,0.5],
     "ink":{"r":0.039,"g":0.039,"b":0.043,"a":1},
     "tone":{"r":0.878,"g":0.545,"b":0.235,"a":1}}
    """
    let decoded = try JSONDecoder().decode(
        MurmurConfiguration.self, from: Data(legacy.utf8)
    )
    #expect(decoded.treatments == MurmurStateTreatment.defaults)
    #expect(decoded.style == .eddy)
}

@Test func resolvedCharacterPadsAndTruncates() {
    var short = MurmurConfiguration(style: .eddy)
    short.character = [0.9]
    #expect(short.resolvedCharacter == [0.9, 0.3, 0.4, 0.5])

    var long = MurmurConfiguration(style: .eddy)
    long.character = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]
    #expect(long.resolvedCharacter == [0.1, 0.2, 0.3, 0.4])
}

@Test func switchingStyleTakesTheNewDefaults() {
    var config = MurmurConfiguration(style: .eddy)
    config.speed = 1.4
    config.tone = MurmurRGBA(r: 0.2, g: 0.6, b: 0.9)
    let moved = config.withStyle(.tuning)
    #expect(moved.style == .tuning)
    #expect(moved.character == MurmurStyle.tuning.characterDefaults)
    #expect(moved.speed == 1.4)
    #expect(moved.tone == config.tone)
}

@Test func codableRoundTrip() throws {
    var config = MurmurConfiguration(style: .murmuration)
    config.speed = 0.7
    config.formScale = 1.35
    config.depth = 1.8
    config.glow = 0.45
    config.hueShift = 0.62
    config.character = [0.11, 0.22, 0.33, 0.44]
    config.ink = MurmurRGBA(r: 0.02, g: 0.03, b: 0.05)
    config.tone = MurmurRGBA(r: 0.4, g: 0.7, b: 0.95, a: 0.9)

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(MurmurConfiguration.self, from: data)
    #expect(decoded == config)
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

@Test func packageSnippetWritesOnlyTheChangedValues() {
    var config = MurmurConfiguration(style: .pool)
    config.speed = 0.6
    config.character = [0.8, 0.2, 0.5, 0.5]
    let prompt = config.agentPrompt(as: .pill)

    #expect(prompt.contains("MurmurConfiguration(style: .pool)"))
    #expect(prompt.contains("c.speed = 0.6"))
    #expect(prompt.contains("c.character = [0.8, 0.2, 0.5, 0.5]"))
    // Untouched dials stay out of the snippet.
    #expect(!prompt.contains("c.glow ="))
    #expect(!prompt.contains("c.formScale ="))
    #expect(!prompt.contains("c.ink ="))
    // Stock treatments stay out of the snippet entirely.
    #expect(!prompt.contains("c.treatments["))
    #expect(!prompt.contains("(customized)"))
}

@Test func exportCarriesOnlyTheChangedTreatments() {
    var config = MurmurConfiguration(style: .glyph)
    config.treatments[.error] = MurmurStateTreatment(
        speedFactor: 0.25, glowFactor: 0.5, depthFactor: 1.4,
        hueShiftDelta: -0.8, entry: .stutter
    )
    let prompt = config.agentPrompt(as: .pill)

    #expect(prompt.contains("c.treatments[.error] = MurmurStateTreatment("))
    #expect(prompt.contains("speedFactor: 0.25"))
    #expect(prompt.contains("hueShiftDelta: -0.8"))
    #expect(prompt.contains("entry: .stutter"))
    #expect(prompt.contains("(customized)"))
    // Only the one state was changed, so only the one line is written.
    #expect(!prompt.contains("c.treatments[.idle]"))
    #expect(!prompt.contains("c.treatments[.thinking]"))
    #expect(!prose(of: prompt).contains("\u{2014}"))
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
    #expect(prompt.contains("MurmurView(Self.murmur)"))
}

@Test func numberFormattingStaysDoubleLiteral() {
    #expect(MurmurExport.number(1) == "1.0")
    #expect(MurmurExport.number(0) == "0.0")
    #expect(MurmurExport.number(0.5) == "0.5")
    #expect(MurmurExport.number(1.25) == "1.25")
    #expect(MurmurExport.number(0.235) == "0.235")
}
