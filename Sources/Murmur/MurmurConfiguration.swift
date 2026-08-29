// A configuration is the whole design decision: which species, the two
// colors the palette rail is built from, and a complete dial set for each of
// the six states.
//
// Kris's shape, in his words: go to idle, make all the changes you want to
// idle, and have it kind of have a save point. Then go to thinking, make any
// changes there. Then copy those over. So the states are six independent
// designs that happen to share a style and a palette, not one design with a
// state multiplier on top.

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
    /// The default hue family anchor. Violet-indigo, in the reference class.
    /// It replaced the amber on Kris's call: amber sat too close to the paper
    /// chip in light appearance, and the whole rail went muddy with it.
    public static let tone = MurmurRGBA(r: 0.424, g: 0.388, b: 0.910)
    /// The founding tone. Kept because a good deal of the archive was tuned
    /// against it, and because it is still the right anchor for a warm app.
    public static let amber = MurmurRGBA(r: 0.878, g: 0.545, b: 0.235)
    /// The light-scheme chip. A paper neutral so the pill is not a slab of
    /// white, and the field has somewhere to dissolve into.
    public static let paper = MurmurRGBA(r: 0.925, g: 0.925, b: 0.937)
}

public struct MurmurConfiguration: Sendable, Codable, Equatable {
    public var style: MurmurStyle
    /// The ground the field dissolves into. Shared by every state: a state
    /// change is the material moving, never the room changing color.
    public var ink: MurmurRGBA
    /// The hue family anchor, likewise shared.
    public var tone: MurmurRGBA
    /// The second duotone anchor, glass family only. Nil is the classic
    /// single-anchor rail and is what the shader sees as "tone2 equals
    /// tone": identical behavior. Set it and the interior palette
    /// interpolates between the two anchors through OKLAB instead of
    /// deriving that side from the spread knob.
    public var tone2: MurmurRGBA?
    /// One complete design per state.
    public var states: [MurmurState: MurmurParameters]
    /// What each state's arrival looks like.
    public var entries: [MurmurState: MurmurEntry]

    /// Passing only a style seeds all six states from that style's own
    /// tuning, which is the out-of-box design.
    public init(
        style: MurmurStyle,
        ink: MurmurRGBA = .ink,
        tone: MurmurRGBA = .tone,
        tone2: MurmurRGBA? = nil,
        states: [MurmurState: MurmurParameters]? = nil,
        entries: [MurmurState: MurmurEntry]? = nil
    ) {
        self.style = style
        self.ink = ink
        self.tone = tone
        self.tone2 = tone2
        self.states = Self.completed(states ?? [:], for: style)
        self.entries = Self.completed(entries ?? [:])
    }

    // MARK: Reading

    /// The stored design, or the seed for a state the dictionary is missing.
    /// Always answers, so nothing downstream deals in optionals.
    public func parameters(for state: MurmurState) -> MurmurParameters {
        states[state] ?? state.seedParameters(for: style)
    }

    /// The same design with the character normalized to exactly four values.
    /// This is what the view renders from.
    public func resolvedParameters(for state: MurmurState) -> MurmurParameters {
        parameters(for: state).resolved(for: style)
    }

    /// What the second anchor resolves to. Nil folds back onto `tone`, so
    /// the shader always has a value and classic reads as a duotone whose
    /// two anchors happen to match.
    public var resolvedTone2: MurmurRGBA { tone2 ?? tone }

    public func entry(for state: MurmurState) -> MurmurEntry {
        entries[state] ?? state.defaultEntry
    }

    /// The states whose design or entry has been moved off its seed, in
    /// roster order. The export prints exactly these.
    public var customizedStates: [MurmurState] {
        MurmurState.allCases.filter {
            parameters(for: $0) != $0.seedParameters(for: style)
                || entry(for: $0) != $0.defaultEntry
        }
    }

    // MARK: Editing

    /// Back to the seed for one state, design and entry both.
    public mutating func resetToSeed(_ state: MurmurState) {
        states[state] = state.seedParameters(for: style)
        entries[state] = state.defaultEntry
    }

    /// Kris's "then I can copy all those over": take one state's finished
    /// design and put it on the others. The entry is not copied, because it
    /// is the state's meaning rather than its look, and a success swell on
    /// idle would be a lie.
    public mutating func copyDesign(from source: MurmurState, to targets: [MurmurState]) {
        let design = parameters(for: source)
        for target in targets where target != source {
            states[target] = design
        }
    }

    /// Switching style keeps every dial the designer set and takes the new
    /// style's character defaults, because the old knobs meant something
    /// else entirely. Colors and entries come across untouched.
    public func withStyle(_ newStyle: MurmurStyle) -> MurmurConfiguration {
        var moved = states
        for state in MurmurState.allCases {
            var design = parameters(for: state)
            design.character = newStyle.characterDefaults
            moved[state] = design
        }
        return MurmurConfiguration(
            style: newStyle,
            ink: ink,
            tone: tone,
            tone2: tone2,
            states: moved,
            entries: entries
        )
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case style, ink, tone, tone2, states, entries
    }

    /// A partial dictionary decodes to a complete one, filled from the
    /// seeds. That keeps a hand-written or trimmed JSON usable and means the
    /// view can never be handed a state with no design.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        style = try container.decode(MurmurStyle.self, forKey: .style)
        ink = try container.decode(MurmurRGBA.self, forKey: .ink)
        tone = try container.decode(MurmurRGBA.self, forKey: .tone)
        // Absent and null both mean classic. The key only appears once a
        // designer has actually set a second anchor.
        tone2 = try container.decodeIfPresent(MurmurRGBA.self, forKey: .tone2)
        states = Self.completed(
            try container.decodeIfPresent(
                [MurmurState: MurmurParameters].self, forKey: .states
            ) ?? [:],
            for: style
        )
        entries = Self.completed(
            try container.decodeIfPresent(
                [MurmurState: MurmurEntry].self, forKey: .entries
            ) ?? [:]
        )
    }

    private static func completed(
        _ partial: [MurmurState: MurmurParameters],
        for style: MurmurStyle
    ) -> [MurmurState: MurmurParameters] {
        var full = partial
        for state in MurmurState.allCases where full[state] == nil {
            full[state] = state.seedParameters(for: style)
        }
        return full
    }

    private static func completed(
        _ partial: [MurmurState: MurmurEntry]
    ) -> [MurmurState: MurmurEntry] {
        var full = partial
        for state in MurmurState.allCases where full[state] == nil {
            full[state] = state.defaultEntry
        }
        return full
    }
}
