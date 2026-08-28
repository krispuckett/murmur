// One configuration, edited in place. The gallery reads it to tint every
// cell, the studio writes it, the export card serializes it. There is no
// second source of truth anywhere in the lab.

import SwiftUI
import Murmur

@MainActor
@Observable
final class LabModel {
    var config: MurmurConfiguration
    var previewScheme: ColorScheme = .dark
    var pillLabel: String = "Thinking..."
    var exportSurface: MurmurExportSurface = .pill
    var isExporting: Bool = false

    init(style: MurmurStyle = .eddy) {
        config = MurmurConfiguration(style: style)
    }

    func select(_ style: MurmurStyle) {
        guard config.style != style else { return }
        config = config.withStyle(style)
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
    static let ink = MurmurRGBA.ink.color
    static let tone = MurmurRGBA.tone.color

    /// The light stage sits a shade above the pill's paper chip so the chip
    /// still reads as an object on it.
    static let paperStage = Color(.sRGB, red: 0.972, green: 0.972, blue: 0.980, opacity: 1)

    /// The dark stage sits a shade above the ink for the same reason. On the
    /// page ground itself the pill's chip is the same color as the page and
    /// the preview shows nothing.
    static let inkStage = Color(.sRGB, red: 0.098, green: 0.098, blue: 0.106, opacity: 1)

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
