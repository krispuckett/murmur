// One complete dial set. Every state owns one of these, which is the whole
// point of the restructure: a state is a DESIGN, not a tint applied to a
// base. Idle is not "thinking, dimmer"; it is its own set of numbers that a
// designer tunes, saves, and can copy onto another state.
//
// The values here are absolute, not factors. speed 1 is the style's designed
// tempo, glow 1 its designed presence. A state that wants more says 1.25.

import Foundation

public struct MurmurParameters: Codable, Sendable, Equatable {
    /// 1 is the style's designed tempo.
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
    /// `resolvedCharacter(for:)` so a short or long array never reaches a
    /// shader.
    public var character: [Double]

    public init(
        speed: Double = 1,
        formScale: Double = 1,
        depth: Double = 1,
        glow: Double = 1,
        hueShift: Double = 0,
        character: [Double] = [0.5, 0.5, 0.5, 0.5]
    ) {
        self.speed = speed
        self.formScale = formScale
        self.depth = depth
        self.glow = glow
        self.hueShift = hueShift
        self.character = character
    }

    /// Exactly four values, always. Missing entries fall back to the style's
    /// tuned default, extra entries are dropped.
    public func resolvedCharacter(for style: MurmurStyle) -> [Double] {
        let defaults = style.characterDefaults
        return (0..<4).map { i in i < character.count ? character[i] : defaults[i] }
    }

    /// The same set with the character normalized to four. The view resolves
    /// once per frame and everything downstream can assume four values.
    public func resolved(for style: MurmurStyle) -> MurmurParameters {
        var copy = self
        copy.character = resolvedCharacter(for: style)
        return copy
    }

    /// Every dial crosses, character knobs included. That is what makes a
    /// state change read as one material rearranging itself rather than as
    /// two materials swapped.
    ///
    /// Written as `a * (1 - t) + b * t` rather than `a + (b - a) * t` so the
    /// ends land exactly on the endpoints instead of near them.
    public func blended(toward other: MurmurParameters, amount: Double) -> MurmurParameters {
        let t = min(max(amount, 0), 1)
        func mix(_ a: Double, _ b: Double) -> Double { a * (1 - t) + b * t }

        let count = max(character.count, other.character.count)
        let knobs = (0..<count).map { i -> Double in
            let a = i < character.count ? character[i] : 0.5
            let b = i < other.character.count ? other.character[i] : 0.5
            return mix(a, b)
        }

        return MurmurParameters(
            speed: mix(speed, other.speed),
            formScale: mix(formScale, other.formScale),
            depth: mix(depth, other.depth),
            glow: mix(glow, other.glow),
            hueShift: mix(hueShift, other.hueShift),
            character: knobs
        )
    }
}
