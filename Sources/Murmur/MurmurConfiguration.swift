// A configuration is the whole design decision: which species, how fast,
// how big its forms are, how deep the palette runs, and the two colors the
// rail is built from. It is Codable because the lab saves it and the agent
// export reads it back; it is Equatable because the studio diffs against
// the style's defaults to know what to write into a snippet.

import Foundation
import SwiftUI

/// sRGB, 0...1, with a Color bridge in both directions. Deliberately small:
/// the shader takes two colors and builds every other value on the rail.
public struct MurmurRGBA: Sendable, Codable, Equatable, Hashable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Reads a SwiftUI color back into components. Resolving against a fresh
    /// environment is enough for the literal and asset colors the lab picker
    /// produces; a dynamic color would resolve to its light appearance.
    public init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        self.init(
            r: Double(resolved.red),
            g: Double(resolved.green),
            b: Double(resolved.blue),
            a: Double(resolved.opacity)
        )
    }

    public var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// "#RRGGBB", or "#RRGGBBAA" when the color is not fully opaque. The
    /// export writes these into prose so a person can read a color without
    /// running anything.
    public var hexString: String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        let base = String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
        return a >= 1 ? base : base + String(format: "%02X", byte(a))
    }

    /// The house ink. Not black: black is a hole, this is a ground.
    public static let ink = MurmurRGBA(r: 0.039, g: 0.039, b: 0.043)
    /// The default hue family anchor. Warm amber, the pour's blood.
    public static let tone = MurmurRGBA(r: 0.878, g: 0.545, b: 0.235)
    /// The light-scheme chip. A paper neutral so the pill is not a slab of
    /// white, and the field has somewhere to dissolve into.
    public static let paper = MurmurRGBA(r: 0.925, g: 0.925, b: 0.937)
}

public struct MurmurConfiguration: Sendable, Codable, Equatable {
    public var style: MurmurStyle
    /// 1 is the designed tempo for every style.
    public var speed: Double
    /// 1 is the designed scale; larger makes broader forms.
    public var formScale: Double
    /// Palette range dial, 0.3 ... 2.
    public var depth: Double
    /// Emission and presence dial.
    public var glow: Double
    /// Radians. Walks the one hue family; it never introduces a second hue.
    public var hueShift: Double
    /// Four values, 0...1, meaning per style. Read through
    /// `resolvedCharacter` so a short or long array can never reach a shader.
    public var character: [Double]
    /// The ground the field dissolves into.
    public var ink: MurmurRGBA
    /// The single hue family anchor.
    public var tone: MurmurRGBA
    /// What each AI state does to the material. Prefilled with the stock
    /// table; override a state to give this configuration its own behavior,
    /// and the override travels with the saved config and the export.
    public var treatments: [MurmurState: MurmurStateTreatment]

    /// Passing only a style gives you the style exactly as it was tuned.
    public init(
        style: MurmurStyle,
        speed: Double = 1,
        formScale: Double = 1,
        depth: Double = 1,
        glow: Double = 1,
        hueShift: Double = 0,
        character: [Double]? = nil,
        ink: MurmurRGBA = .ink,
        tone: MurmurRGBA = .tone,
        treatments: [MurmurState: MurmurStateTreatment]? = nil
    ) {
        self.style = style
        self.speed = speed
        self.formScale = formScale
        self.depth = depth
        self.glow = glow
        self.hueShift = hueShift
        self.character = character ?? style.characterDefaults
        self.ink = ink
        self.tone = tone
        self.treatments = treatments ?? MurmurStateTreatment.defaults
    }

    /// Always answers, even for a state a decoded dictionary is missing.
    public func treatment(for state: MurmurState) -> MurmurStateTreatment {
        treatments[state] ?? state.defaultTreatment
    }

    /// The states this configuration has moved away from the stock table,
    /// in roster order. Empty means it uses the defaults throughout.
    public var customizedStates: [MurmurState] {
        MurmurState.allCases.filter { treatment(for: $0) != $0.defaultTreatment }
    }

    // Treatments arrived after the first configurations were written, so a
    // saved config without them decodes to the stock table rather than
    // failing. Everything else has been required since the beginning.
    private enum CodingKeys: String, CodingKey {
        case style, speed, formScale, depth, glow, hueShift, character, ink, tone, treatments
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        style = try container.decode(MurmurStyle.self, forKey: .style)
        speed = try container.decode(Double.self, forKey: .speed)
        formScale = try container.decode(Double.self, forKey: .formScale)
        depth = try container.decode(Double.self, forKey: .depth)
        glow = try container.decode(Double.self, forKey: .glow)
        hueShift = try container.decode(Double.self, forKey: .hueShift)
        character = try container.decode([Double].self, forKey: .character)
        ink = try container.decode(MurmurRGBA.self, forKey: .ink)
        tone = try container.decode(MurmurRGBA.self, forKey: .tone)
        treatments = try container.decodeIfPresent(
            [MurmurState: MurmurStateTreatment].self, forKey: .treatments
        ) ?? MurmurStateTreatment.defaults
    }

    /// Exactly four values, always. Missing entries fall back to the style's
    /// tuned default, extra entries are dropped. Decoded JSON and a style
    /// switch in the lab both go through here, so neither can hand the
    /// shader a short array.
    public var resolvedCharacter: [Double] {
        let defaults = style.characterDefaults
        return (0..<4).map { i in i < character.count ? character[i] : defaults[i] }
    }

    /// The style's four knobs paired with the values in this configuration.
    public var knobValues: [(knob: MurmurKnob, value: Double)] {
        let values = resolvedCharacter
        return zip(style.characterKnobs, values).map { (knob: $0, value: $1) }
    }

    /// Everything back to the tuned state, keeping the style.
    public mutating func resetCharacter() {
        character = style.characterDefaults
    }

    /// Switching style in the lab carries the shared dials and colors across
    /// but takes the new style's character defaults; the old knobs meant
    /// something else.
    public func withStyle(_ newStyle: MurmurStyle) -> MurmurConfiguration {
        MurmurConfiguration(
            style: newStyle,
            speed: speed,
            formScale: formScale,
            depth: depth,
            glow: glow,
            hueShift: hueShift,
            character: newStyle.characterDefaults,
            ink: ink,
            tone: tone,
            treatments: treatments
        )
    }
}
