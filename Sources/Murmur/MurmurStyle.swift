// The roster. Every fact a style carries that is not pixels lives here:
// which pack file holds its body, what its four character knobs are called,
// whether it honors the settle arc, and the one line that says what species
// it is. SPEC.md's roster tables are the source; this file is their
// transcription. If a table changes, change it here in the same commit.

import Foundation

/// The four pack files. A family is a shared physics, not a color scheme:
/// liquid has weight, ink has capillary time, light passes through media,
/// signal finds order in noise.
public enum MurmurFamily: String, CaseIterable, Sendable, Codable {
    case liquid, ink, light, signal, orb, presence, glass

    public var displayName: String { rawValue.capitalized }

    /// The Metal namespace prefix. Every function and helper in a pack file
    /// wears it; there is no cross-file linkage in Metal, so the prefix is
    /// what keeps four copies of the same kit from colliding.
    public var shaderPrefix: String {
        switch self {
        case .liquid: "ml_"
        case .ink: "mi_"
        case .light: "mg_"
        case .signal: "ms_"
        case .orb: "mo_"
        case .presence: "mq_"
        case .glass: "mh_"
        }
    }

    /// The pack file's base name, without the .metal extension. Used by the
    /// self-contained export to read the source back out of the bundle.
    public var packFileName: String {
        switch self {
        case .liquid: "MurmurLiquid"
        case .ink: "MurmurInk"
        case .light: "MurmurLight"
        case .signal: "MurmurSignal"
        case .orb: "MurmurOrb"
        case .presence: "MurmurPresence"
        case .glass: "MurmurGlass"
        }
    }

    /// The family's styles in roster order, for gallery grouping.
    public var styles: [MurmurStyle] {
        MurmurStyle.allCases.filter { $0.family == self }
    }
}

/// One character dial: the name the designer sees and the value the style
/// was tuned at. Knobs are always 0...1; the Swift layer passes them to the
/// shader untouched, so meaning lives entirely in the Metal.
public struct MurmurKnob: Sendable, Hashable, Codable {
    public let label: String
    public let defaultValue: Double

    public init(label: String, defaultValue: Double) {
        self.label = label
        self.defaultValue = defaultValue
    }
}

/// The 24 species.
public enum MurmurStyle: String, CaseIterable, Identifiable, Sendable, Codable {
    case eddy, well, tide, undertow, meander, confluence, melt, glaze
    case bloom, marbling, wick, strata, halation, pool, feather, palimpsest
    case caustic, aurora, ember, lantern, mirage, oculus, dapple, eclipse
    case murmuration, loom, cipher, tuning, current, veil, echo, glyph
    case breathe, orbit, glimmer, vortex, gather, stir, daybreak, skein
    case halo, nucleus, iris, filament, flare, braid, mote, ripple
    // The hero collection. One iconic glass body; all identity lives inside it.
    case aura, droplet, nebula, prism, limn, duet
    case fathom, arc, opal, comet, still, flux
    case tempest, helix, geode, sol, abyss, chorus

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }

    public var family: MurmurFamily {
        switch self {
        case .eddy, .well, .tide, .undertow, .meander, .confluence, .melt, .glaze:
            .liquid
        case .bloom, .marbling, .wick, .strata, .halation, .pool, .feather, .palimpsest:
            .ink
        case .caustic, .aurora, .ember, .lantern, .mirage, .oculus, .dapple, .eclipse:
            .light
        case .murmuration, .loom, .cipher, .tuning, .current, .veil, .echo, .glyph:
            .signal
        case .breathe, .orbit, .glimmer, .vortex, .gather, .stir, .daybreak, .skein:
            .orb
        case .halo, .nucleus, .iris, .filament, .flare, .braid, .mote, .ripple:
            .presence
        case .aura, .droplet, .nebula, .prism, .limn, .duet,
            .fathom, .arc, .opal, .comet, .still, .flux,
            .tempest, .helix, .geode, .sol, .abyss, .chorus:
            .glass
        }
    }

    /// The `[[ stitchable ]]` function name, e.g. "ml_eddy".
    public var shaderName: String { family.shaderPrefix + rawValue }

    /// Styles whose concept has an arrival read `epoch` and run a settle arc.
    /// The rest ignore it. Settled is never frozen: a whisper of drift stays.
    public var hasArc: Bool {
        switch self {
        case .confluence, .bloom, .strata, .oculus, .tuning, .feather, .gather: true
        default: false
        }
    }

    /// The species intent, one line, as written in the roster. This is the
    /// sentence the agent export hands to whoever implements the indicator,
    /// so it says what the thing IS, not how it is built.
    public var species: String {
        switch self {
        case .eddy:
            "thought circling a center: a slow rotational shear field, light caught in the turn"
        case .well:
            "pulling inward: light and density drawn toward a deep center that never fills"
        case .tide:
            "a slow wash crossing the frame and returning, weight leaning with it"
        case .undertow:
            "two layers sliding opposite ways, structure born where they shear"
        case .meander:
            "one bright channel wandering through dark mass, the path is the thought"
        case .confluence:
            "two flows finding each other and joining; joined is the rest state"
        case .melt:
            "a heavy molten mass slowly melting and reforming, viscous, drips absorbed back into the body"
        case .glaze:
            "a thin bright sheet of liquid sliding over a dark form, light traveling in the film"
        case .bloom:
            "ink meeting water: a front advancing with a live fBm edge, settling saturated"
        case .marbling:
            "combed ink: layered laminar folds sliding past each other, suminagashi tempo"
        case .wick:
            "ink drawn upward through fiber: capillary creep, gravity in reverse, grain of the paper visible in the climb"
        case .strata:
            "sediment settling into layers: horizontal density bands finding their level"
        case .halation:
            "a dark mass wearing its own light: soft halo shifting as the mass slowly reforms"
        case .pool:
            "ink already at rest, meniscus alive: the stillest style in the set, surface tension doing the thinking"
        case .feather:
            "ink feathering along paper fibers: a directional bleed advancing hair by hair, then resting saturated"
        case .palimpsest:
            "older writing ghosting up through the surface, almost legible, reabsorbed before it resolves"
        case .caustic:
            "light refracted through moving water onto a floor: the web, soft, never cellular"
        case .aurora:
            "a curtain of light folding in slow air, horizontal grammar, nothing falls"
        case .ember:
            "heat above a warm floor: shimmer rising, light pooled low"
        case .lantern:
            "one light behind moving fog: presence felt through a medium, never seen directly"
        case .mirage:
            "horizontal refraction bands bending a distant light, the desert-road shimmer"
        case .oculus:
            "a soft aperture admitting light, opening as thought completes; open is rest"
        case .dapple:
            "canopy light: soft patches through moving leaves, the shade breathing across the floor"
        case .eclipse:
            "a slow occluder drifting across a light, the corona doing the talking at the edge"
        case .murmuration:
            "the namesake: a flock as one soft mass, density turning and folding over itself, individuals never resolvable"
        case .loom:
            "threads finding a weave: warp and weft interference resolving into cloth and relaxing again"
        case .cipher:
            "meaning surfacing: latent structure in a dark field, revealed where a slow attention passes"
        case .tuning:
            "static finding the station: broadband noise narrowing toward a coherent line; coherent is rest, noise never fully gone"
        case .current:
            "signal moving through a medium: impulses traveling a soft network, felt as moving light, never drawn as wires"
        case .veil:
            "layers of translucency sliding: what is behind almost legible, parallax as depth of thought"
        case .echo:
            "a soft form answered by its own fading repetitions, each displaced and softer than the last, never rings"
        case .glyph:
            "almost-writing: marks forming out of ink and dissolving before they resolve into letters"
        case .breathe:
            "the resting orb: the whole lattice inhaling and exhaling slowly, depth carrying the breath"
        case .orbit:
            "latitude bands of dots streaming around the sphere at neighboring speeds"
        case .glimmer:
            "scattered dots catching light in sequence, a constellation being counted"
        case .vortex:
            "the lattice swirling toward a pole, drawn and released"
        case .gather:
            "dots converging from dispersion into one bright ring; ringed is the rest state"
        case .stir:
            "dots jostled from their lattice seats and settling back, the sphere thinking with its hands"
        case .daybreak:
            "a terminator of light sweeping the sphere, dawn crossing a small planet"
        case .skein:
            "dots strung along a winding thread wrapping the sphere, wound and unwound"
        case .halo:
            "a thin luminous ring tilting in 3D like a coin's edge; voice travels its circumference as a wave, never bars"
        case .nucleus:
            "a steady bright core wearing a shell of circulating mist; voice swells the shell, success collapses it into the core"
        case .iris:
            "an aperture of soft light petals; voice opens it, silence closes it to a slit glow"
        case .filament:
            "one continuous thread of light: knotting loosely while thinking, taut while responding, coiled at rest"
        case .flare:
            "a soft solar disc whose edge sprouts short organic licks with voice level; a sun, never an EQ"
        case .braid:
            "two strands orbiting a common center: loose at idle, braided tight while responding; the conversation itself"
        case .mote:
            "the minimal presence: one soft light wandering a small path, leaning toward typing, stretching slightly with voice; designed at 18 pt first"
        case .ripple:
            "a still face-on liquid disc where input lands: each impulse of activity drops one soft propagating ring"
        case .aura:
            "ribbons of colored light swirling slowly inside the glass"
        case .droplet:
            "the body itself deforms: a zero-g liquid sphere wobbling organically, breathing with voice"
        case .nebula:
            "volumetric mist folding inside, stirred by thinking"
        case .prism:
            "light entering and softly splitting inside the sphere"
        case .limn:
            "near-dark glass whose edge is alive: a traveling rim of light thickening with voice"
        case .duet:
            "two lights orbiting each other inside: the conversation"
        case .fathom:
            "layered translucent depths, parallax inside the glass"
        case .arc:
            "one soft bright filament arcing gently within"
        case .opal:
            "internal play-of-color: soft opalescent flashes drifting through"
        case .comet:
            "a bright point orbiting inside, leaving a fading trail; parseable at 18 pt"
        case .still:
            "the minimal hero: a quiet glass sphere, one slow internal glint"
        case .flux:
            "an aurora streaming inside the glass"
        case .tempest:
            "a contained storm: weather churning in the glass, lightning-soft flickers buried deep in the cloud, never at the surface"
        case .helix:
            "a double strand of light slowly climbing and rotating inside"
        case .geode:
            "crystalline facets inside the glass catching light as the body turns"
        case .sol:
            "a miniature sun: soft prominences lifting and falling inside"
        case .abyss:
            "deep-sea dark glass: rare bioluminescent glows passing through, mostly night"
        case .chorus:
            "many faint lights breathing loosely, falling into alignment while responding"
        }
    }

    /// Exactly four, always, in c0...c3 order.
    public var characterKnobs: [MurmurKnob] {
        switch self {
        // Liquid
        case .eddy:
            [k("swirl", 0.5), k("drift", 0.3), k("grain", 0.4), k("shear", 0.5)]
        case .well:
            [k("pull", 0.5), k("depthGlow", 0.5), k("churn", 0.3), k("offset", 0.5)]
        case .tide:
            [k("reach", 0.5), k("lean", 0.4), k("foam", 0.3), k("period", 0.5)]
        case .undertow:
            [k("contrast", 0.5), k("slip", 0.5), k("veil", 0.3), k("bias", 0.5)]
        case .meander:
            [k("width", 0.4), k("wander", 0.5), k("bank", 0.4), k("flow", 0.5)]
        case .confluence:
            [k("approach", 0.5), k("mingle", 0.5), k("shimmer", 0.3), k("angle", 0.5)]
        case .melt:
            [k("mass", 0.5), k("viscosity", 0.6), k("dripAbsorb", 0.5), k("heat", 0.4)]
        case .glaze:
            [k("sheet", 0.5), k("slide", 0.5), k("sheen", 0.5), k("tilt", 0.5)]
        // Ink
        case .bloom:
            [k("spread", 0.5), k("edgeTear", 0.5), k("tail", 0.4), k("asymmetry", 0.3)]
        case .marbling:
            [k("folds", 0.5), k("comb", 0.4), k("contrast", 0.5), k("drift", 0.3)]
        case .wick:
            [k("climb", 0.5), k("fiber", 0.5), k("pooling", 0.3), k("dryEdge", 0.4)]
        case .strata:
            [k("layers", 0.5), k("settle", 0.5), k("disturb", 0.2), k("tilt", 0.5)]
        case .halation:
            [k("mass", 0.5), k("corona", 0.5), k("morph", 0.4), k("offset", 0.5)]
        case .pool:
            [k("tension", 0.5), k("tremor", 0.2), k("sheen", 0.5), k("tilt", 0.5)]
        case .feather:
            [k("bleed", 0.5), k("fiber", 0.5), k("direction", 0.5), k("dryness", 0.4)]
        case .palimpsest:
            [k("layers", 0.5), k("legibility", 0.4), k("surfacing", 0.5), k("age", 0.5)]
        // Light
        case .caustic:
            [k("web", 0.5), k("depthWater", 0.5), k("swim", 0.4), k("focus", 0.5)]
        case .aurora:
            [k("fold", 0.5), k("height", 0.5), k("wander", 0.4), k("thin", 0.5)]
        case .ember:
            [k("heat", 0.5), k("shimmer", 0.4), k("floor", 0.5), k("updraft", 0.4)]
        case .lantern:
            [k("fog", 0.5), k("reach", 0.5), k("drift", 0.4), k("offset", 0.5)]
        case .mirage:
            [k("bands", 0.5), k("bend", 0.5), k("distance", 0.5), k("haze", 0.4)]
        case .oculus:
            [k("aperture", 0.5), k("rim", 0.4), k("beam", 0.5), k("dust", 0.3)]
        case .dapple:
            [k("canopy", 0.5), k("breeze", 0.5), k("patch", 0.5), k("depthLight", 0.5)]
        case .eclipse:
            [k("occlude", 0.5), k("corona", 0.5), k("drift", 0.4), k("softness", 0.5)]
        // Signal
        case .murmuration:
            [k("flock", 0.5), k("turn", 0.5), k("cohesion", 0.5), k("sky", 0.3)]
        case .loom:
            [k("threads", 0.5), k("tension", 0.5), k("sheen", 0.4), k("angle", 0.5)]
        case .cipher:
            [k("reveal", 0.5), k("structure", 0.5), k("dwell", 0.5), k("scatter", 0.3)]
        case .tuning:
            [k("band", 0.5), k("lock", 0.5), k("hiss", 0.3), k("drift", 0.4)]
        case .current:
            [k("pathways", 0.5), k("pulseRate", 0.4), k("glow", 0.5), k("branch", 0.5)]
        case .veil:
            [k("layers", 0.5), k("parallax", 0.5), k("legibility", 0.4), k("drift", 0.3)]
        case .echo:
            [k("repeats", 0.5), k("decay", 0.5), k("offset", 0.5), k("blur", 0.4)]
        case .glyph:
            [k("marks", 0.5), k("formation", 0.5), k("dissolve", 0.5), k("ink", 0.5)]
        // Orb. The family shares its last two knobs: c2 is always dotSize and
        // c3 always material, because the figure is always the same lattice
        // and only its behavior changes. The material dial runs 0 pale and
        // restrained, the reference register, through 1 molten; accent
        // density and warmth both ride it. Default 0.3 everywhere: molten
        // overshot on device.
        case .breathe:
            [k("breath", 0.5), k("depthFade", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .orbit:
            [k("bands", 0.5), k("flow", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .glimmer:
            [k("sparkle", 0.5), k("spread", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .vortex:
            [k("swirl", 0.6), k("pole", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .gather:
            [k("pull", 0.5), k("ring", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .stir:
            [k("jitter", 0.5), k("settle", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .daybreak:
            [k("sweep", 0.5), k("softness", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        case .skein:
            [k("winding", 0.5), k("trail", 0.5), k("dotSize", 0.5), k("material", 0.3)]
        // Presence. Designed reactive-first: these eight are built for the live
        // signals and for the 18 pt mount, so their knobs shape a gesture that
        // has to survive being tiny.
        case .halo:
            [k("tilt", 0.5), k("thickness", 0.4), k("waviness", 0.5), k("shimmer", 0.4)]
        case .nucleus:
            [k("coreSize", 0.5), k("shell", 0.5), k("circulate", 0.5), k("swellRange", 0.5)]
        case .iris:
            [k("petals", 0.5), k("openness", 0.5), k("softness", 0.5), k("twist", 0.4)]
        case .filament:
            [k("length", 0.5), k("knot", 0.5), k("brightness", 0.5), k("sway", 0.4)]
        case .flare:
            [k("discSize", 0.5), k("licks", 0.5), k("reach", 0.5), k("flicker", 0.3)]
        case .braid:
            [k("strands", 0.5), k("twist", 0.5), k("separation", 0.5), k("glowBalance", 0.5)]
        case .mote:
            [k("wander", 0.4), k("lean", 0.5), k("size", 0.4), k("tail", 0.3)]
        case .ripple:
            [k("stillness", 0.5), k("ringSpeed", 0.5), k("decay", 0.5), k("sheen", 0.5)]
        // Glass. One shared body, so the species are all interior: what lives
        // inside the sphere and how it moves. Every hero carries a spread
        // knob, the chroma-spread dial that lets the rail's neighboring hues
        // interplay inside the volume, and its default is where that species
        // sits on the scale. It is c3 everywhere except aura, which spends
        // its last knob on depth3d instead: per the roster table.
        case .aura:
            [k("ribbons", 0.5), k("swirl", 0.5), k("spread", 0.5), k("depth3d", 0.5)]
        case .droplet:
            [k("wobble", 0.5), k("tension", 0.5), k("sheen", 0.5), k("spread", 0.3)]
        case .nebula:
            [k("density", 0.5), k("fold", 0.5), k("glintRate", 0.4), k("spread", 0.4)]
        case .prism:
            [k("beams", 0.4), k("split", 0.5), k("drift", 0.5), k("spread", 0.6)]
        case .limn:
            [k("rimWidth", 0.4), k("travel", 0.5), k("innerHint", 0.3), k("spread", 0.4)]
        case .duet:
            [k("separation", 0.5), k("orbit", 0.5), k("sizeRatio", 0.5), k("spread", 0.6)]
        case .fathom:
            [k("layers", 0.5), k("parallax", 0.5), k("murk", 0.4), k("spread", 0.4)]
        case .arc:
            [k("arcLength", 0.5), k("sway", 0.5), k("corePin", 0.5), k("spread", 0.3)]
        case .opal:
            [k("flashes", 0.5), k("drift", 0.4), k("softness", 0.6), k("spread", 0.7)]
        case .comet:
            [k("orbitTilt", 0.5), k("trail", 0.5), k("pointSize", 0.4), k("spread", 0.3)]
        case .still:
            [k("glintRate", 0.3), k("clarity", 0.6), k("presence", 0.5), k("spread", 0.2)]
        case .flux:
            [k("stream", 0.5), k("bend", 0.5), k("height", 0.5), k("spread", 0.6)]
        case .tempest:
            [k("storm", 0.5), k("churn", 0.5), k("flicker", 0.3), k("spread", 0.5)]
        case .helix:
            [k("turns", 0.5), k("rise", 0.4), k("strandGlow", 0.5), k("spread", 0.6)]
        case .geode:
            [k("facets", 0.5), k("glimmer", 0.4), k("depthCrystal", 0.5), k("spread", 0.5)]
        case .sol:
            [k("coronaSize", 0.5), k("prominence", 0.5), k("simmer", 0.4), k("spread", 0.4)]
        case .abyss:
            [k("creatures", 0.4), k("rarity", 0.6), k("drift", 0.5), k("spread", 0.4)]
        case .chorus:
            [k("voices", 0.5), k("sync", 0.5), k("breatheDepth", 0.4), k("spread", 0.5)]
        }
    }

    /// The four tuned values, in order.
    public var characterDefaults: [Double] { characterKnobs.map(\.defaultValue) }
}

private func k(_ label: String, _ value: Double) -> MurmurKnob {
    MurmurKnob(label: label, defaultValue: value)
}
