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
    #expect(MurmurStyle.allCases.count == 24)
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

@Test func eachFamilyHoldsSixStyles() {
    for family in MurmurFamily.allCases {
        #expect(family.styles.count == 6, "\(family.rawValue) style count")
    }
}

@Test func arcStylesAreFlagged() {
    let expected: Set<MurmurStyle> = [.confluence, .bloom, .strata, .oculus, .tuning]
    let flagged = Set(MurmurStyle.allCases.filter(\.hasArc))
    #expect(flagged == expected)
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
    }
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
