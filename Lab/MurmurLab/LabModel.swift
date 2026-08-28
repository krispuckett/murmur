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
        config.treatment(for: state).entry
    }

    func cycleEntry() {
        let all = MurmurEntry.allCases
        let next = all[((all.firstIndex(of: entry) ?? 0) + 1) % all.count]
        var treatment = config.treatment(for: state)
        treatment.entry = next
        config.treatments[state] = treatment
        demoTick += 1
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
    /// The room. Warm rather than the cool near-black the package ships as a
    /// neutral default, so the dark ground reads as the amber material's own
    /// room instead of a void behind it.
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
    /// not a palette. Amber first: it is the default the package ships.
    static let tones: [MurmurRGBA] = [
        MurmurRGBA(r: 0.878, g: 0.545, b: 0.235),  // amber  #E08B3C
        MurmurRGBA(r: 0.561, g: 0.435, b: 0.239),  // honey  #8F6F3D
        MurmurRGBA(r: 0.180, g: 0.490, b: 0.455),  // teal   #2E7D74
        MurmurRGBA(r: 0.435, g: 0.357, b: 0.816),  // violet #6F5BD0
        MurmurRGBA(r: 0.831, g: 0.396, b: 0.478),  // rose   #D4657A
        MurmurRGBA(r: 0.725, g: 0.753, b: 0.800),  // silver #B9C0CC
    ]

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
