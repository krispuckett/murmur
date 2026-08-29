// One configuration, edited in place. The gallery reads it to tint every
// cell, the studio writes it, the export card serializes it. There is no
// second source of truth anywhere in the lab.

import SwiftUI
import Murmur

@MainActor
@Observable
final class LabModel {
    var config: MurmurConfiguration
    /// What the agent is doing. The package glides between states on its own,
    /// so this is set plainly and never inside a withAnimation.
    var state: MurmurState = .thinking
    var previewScheme: ColorScheme = .dark
    var pillLabel: String = "Thinking..."
    var exportSurface: MurmurExportSurface = .pill
    var isExporting: Bool = false

    init(style: MurmurStyle = .eddy) {
        config = MurmurConfiguration(style: style)
        // The lab opens in the warm room. The stage a field sits on IS its
        // ink, so warming the stage without warming this would put a cool
        // disc on a warm ground and show the circle's edge.
        config.ink = LabTheme.stageInk
    }

    // MARK: - Live signals

    /// Voice energy and typing cadence, as the host would feed them. These are
    /// not part of the saved design, so they live here rather than in the
    /// configuration.
    var level: Double = 0
    var activity: Double = 0

    /// Non-nil while the canned phrase is playing, and it wins over the dial.
    private(set) var demoLevel: Double?
    private var demoTask: Task<Void, Never>?

    /// What every preview renders from.
    var signals: MurmurSignals {
        MurmurSignals(level: demoLevel ?? level, activity: activity)
    }

    /// Gyro parallax, faked. Each axis runs -1...1, which is what the device's
    /// motion source would hand the view; the simulator has no motion hardware,
    /// so the pad stands in for tilting the phone.
    var tilt: CGPoint = .zero

    /// The advanced capabilities are glass-family designs. Showing their
    /// controls on an archive species would offer dials that do nothing.
    var isGlass: Bool { config.style.family == .glass }

    var isPlayingVoiceDemo: Bool { demoLevel != nil }

    /// Roughly one spoken sentence.
    static let voiceDemoDuration: Double = 6

    /// Auditioning a species as a voice presence without a microphone. The
    /// envelope is driven from a ticker rather than a TimelineView because the
    /// signals have to reach views that are already running their own
    /// timelines; only the value changing pulls them forward.
    func playVoiceDemo() {
        demoTask?.cancel()
        demoTask = Task { @MainActor [weak self] in
            let start = Date.now
            while !Task.isCancelled {
                let elapsed = Date.now.timeIntervalSince(start)
                guard elapsed < Self.voiceDemoDuration else { break }
                self?.demoLevel = Self.voiceEnvelope(at: elapsed)
                try? await Task.sleep(for: .milliseconds(33))
            }
            // Back to whatever the dial says.
            self?.demoLevel = nil
        }
    }

    /// A spoken phrase: fast attack, a sustained body that undulates at
    /// roughly syllable rate, two breath gaps where a speaker would pause, and
    /// a soft release. Shaped rather than random so it reads as speech instead
    /// of noise.
    static func voiceEnvelope(at t: Double) -> Double {
        let duration = voiceDemoDuration
        guard t > 0, t < duration else { return 0 }

        let attack = min(t / 0.22, 1)
        let release = min(max((duration - t) / 0.9, 0), 1)
        let syllables = 0.5 + 0.5 * sin(2 * .pi * 3.6 * t - .pi / 2)
        let inflection = 0.72 + 0.28 * sin(2 * .pi * 0.42 * t)
        let breath = (1 - 0.75 * bump(t, center: 2.05, width: 0.30))
            * (1 - 0.85 * bump(t, center: 4.25, width: 0.38))

        let value = attack * release * inflection * breath
            * (0.45 + 0.55 * pow(syllables, 1.6))
        return min(max(value, 0), 1)
    }

    private static func bump(_ t: Double, center: Double, width: Double) -> Double {
        let u = (t - center) / width
        return exp(-u * u)
    }

    /// Bumped to replay an entry envelope on the pinned preview. MurmurView
    /// runs an entry when the state changes or when it appears, so editing the
    /// entry on its own would show nothing until the next state change. Used
    /// as the preview's identity, which makes it appear again.
    var demoTick = 0

    func select(_ style: MurmurStyle) {
        guard config.style != style else { return }
        config = config.withStyle(style)
    }

    /// The entry envelope belonging to the state currently selected.
    var entry: MurmurEntry {
        config.entry(for: state)
    }

    func cycleEntry() {
        let all = MurmurEntry.allCases
        let next = all[((all.firstIndex(of: entry) ?? 0) + 1) % all.count]
        config.entries[state] = next
        demoTick += 1
    }

    // MARK: - The state being edited

    /// Every dial in the panel reads and writes through here, so selecting a
    /// state in the row above swaps the whole panel to that state's design.
    /// Writing back into the dictionary is the save point: there is no commit
    /// step and nothing to lose by switching away.
    var parameters: MurmurParameters {
        get { config.parameters(for: state) }
        set { config.states[state] = newValue }
    }

    /// The character array, always four long, for the state being edited.
    var character: [Double] {
        config.resolvedParameters(for: state).character
    }

    /// What this state was tuned at before anyone touched it. Tapping a dial's
    /// value returns it here, not to a global default: idle's rest speed is
    /// not thinking's.
    var seed: MurmurParameters {
        state.seedParameters(for: config.style)
    }

    /// A dial's binding into the selected state.
    func dial(_ keyPath: WritableKeyPath<MurmurParameters, Double>) -> Binding<Double> {
        Binding(
            get: { self.parameters[keyPath: keyPath] },
            set: { self.parameters[keyPath: keyPath] = $0 }
        )
    }

    /// One character knob's binding into the selected state.
    func knob(_ index: Int) -> Binding<Double> {
        Binding(
            get: { self.character[index] },
            set: { newValue in
                var updated = self.character
                updated[index] = newValue
                self.parameters.character = updated
            }
        )
    }

    /// The preview grounds the field in whatever the stage is, the same swap
    /// MurmurPill makes in light appearance. Without it the indicator reads as
    /// a dark disc dropped on paper instead of a field opening inside it.
    var previewConfig: MurmurConfiguration {
        var copy = config
        if previewScheme == .light { copy.ink = .paper }
        return copy
    }
}

enum LabTheme {
    /// The room. Warmer than the cool near-black the package ships as a
    /// neutral default, so the dark ground reads as the material's own room
    /// instead of a void behind it.
    ///
    /// These numbers were tuned by eye against the amber material, back when
    /// amber was the default. The default is violet now and this has not been
    /// re-tuned; that is a call for Kris's eye, not mine.
    static let stageInk = MurmurRGBA(r: 0.070, g: 0.058, b: 0.048)
    static let stage = stageInk.color

    /// Reserved for the one primary action per screen. Nothing in the chrome
    /// may spend it: the accent belongs to the material and to the Copy
    /// button, and that is the whole budget.
    static let tone = MurmurRGBA.tone.color

    /// The light stage sits a shade above the pill's paper chip so the chip
    /// still reads as an object on it.
    static let paperStage = Color(.sRGB, red: 0.972, green: 0.972, blue: 0.980, opacity: 1)

    /// The dark pill stage sits a shade above the room for the same reason.
    /// On the room itself the pill's chip is the same color as the ground and
    /// the preview shows nothing.
    static let inkStage = Color(.sRGB, red: 0.125, green: 0.108, blue: 0.094, opacity: 1)

    // Chrome is achromatic. These are the only values it draws with.
    static let label = Color.white.opacity(0.68)
    static let labelDim = Color.white.opacity(0.45)
    static let valueIdle = Color.white.opacity(0.45)
    static let valueLive = Color.white.opacity(0.92)
    static let trackFill = Color.white.opacity(0.78)
    static let trackBed = Color.white.opacity(0.10)
    /// Selection has to carry on its own now that no tint is doing it, so the
    /// edge is bright enough to find at a glance across a row of five.
    static let selectedEdge = Color.white.opacity(0.85)

    /// One hue family per configuration, so the curated row is six anchors,
    /// not a palette. The package default leads and amber follows it, both
    /// taken from the package presets so this row cannot drift from them.
    /// The hand-rolled violet that used to sit fourth is gone: it was within a
    /// few percent of the new default and read as the same swatch twice.
    static let tones: [MurmurRGBA] = [
        .tone,                                     // violet #6C63E8, the default
        .amber,                                    // amber  #E08B3C
        MurmurRGBA(r: 0.561, g: 0.435, b: 0.239),  // honey  #8F6F3D
        MurmurRGBA(r: 0.180, g: 0.490, b: 0.455),  // teal   #2E7D74
        MurmurRGBA(r: 0.831, g: 0.396, b: 0.478),  // rose   #D4657A
        MurmurRGBA(r: 0.725, g: 0.753, b: 0.800),  // silver #B9C0CC
    ]

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
