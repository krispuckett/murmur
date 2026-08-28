# Murmur — build contract

Murmur is a Swift package of parametric thinking indicators for AI products:
24 Metal shader "species", one uniform API, a lab app for designing a
configuration by hand, and a one-tap export that hands the exact configuration
to a coding agent for implementation. This document is the contract every
builder works to. Do not deviate from names, signatures, or file ownership
without updating this file.

## The lineage (read these files first, they are the assignment)

The genome comes from shipped, loved surfaces, not from rule lists:

- `/Users/kris/Developer/Aurelius/Aurelius/Aurelius/Core/Design/FieldPackPour.metal`
  The canonical pack file. Read its header comment in full. Copy its kit
  discipline: helpers copied VERBATIM under the pack's own prefix, comments
  carried with them, no cross-file Metal linkage.
- `/Users/kris/Developer/Aurelius/Aurelius/Aurelius/Core/Design/FieldLab.metal`
  The full kit: `fl_hash`, `fl_noised3`/`fl_noise3` (gradient noise with
  derivatives), `fl_fbmd3`/`fl_fbm3`, the sRGB/OKLAB rail, `fl_palette`,
  `fl_shade`, `fl_out` (triangular dither), `fl_edge`, `fl_knee`, `fl_clock`,
  `fl_filmic`, plus 1D noise (`fl_hash1`, `fl_vnoise1`, `fl_fbm1`).
- `/Users/kris/Developer/Aurelius/Aurelius/Aurelius/Core/Design/AtmosphereField.swift`
  The house mounting pattern: `TimelineView(.periodic)` at 30fps,
  `.visualEffect { content, proxy in content.colorEffect(ShaderLibrary...) }`.

The law (from the field-pack record): a variant family fails when briefed by
rules and rebuilt from noise primitives. Copy the kit from the source. Then
each style must be a NEW SPECIES IN THE SAME ECOSYSTEM: its own body and
physics, family blood. Family blood means: warm liquid light, ink, calm,
per-pixel generative fields. Never a clone of the pour and never a stranger.

## Hard taste rules (violations get killed on review)

- Per-pixel generative fields only. Never displace or tint a gradient.
- No dots, orbs, particles, or 3D dot spheres. The inspiration piece
  (a fibonacci dot sphere) is exactly what Murmur must NOT resemble.
  A DENSITY field of a mass (e.g. a flock as soft masses) is fine; discrete
  circles are not.
- The family verbs are FLOW and SETTLE. Breathing/pulsing luminance is not a
  default motif; a pulse is allowed only where the concept literally is a
  rhythm, and never as the whole idea.
- Calm. Broad forms, low octave counts, dim ceiling. "Stormy" is as wrong as
  flat. Motion the eye feels rather than watches.
- Organic forms never have hard edges. Everything fades.
- One hue family per configuration. The palette rail (below) enforces this;
  do not fight it.
- Time enters where coordinates are READ (advection, phase, domain), not as a
  brightness multiplier.
- Must read at 20 pt and at 300 pt. Test both. Small must stay legible
  (one clear gesture), large must stay interesting (structure, not blur).

## Repository layout and file ownership

```
murmur/
  Package.swift                     (done)
  SPEC.md                           (this file)
  Sources/Murmur/
    MurmurStyle.swift               owner: core
    MurmurConfiguration.swift       owner: core
    MurmurView.swift                owner: core
    MurmurPill.swift                owner: core
    AgentExport.swift               owner: core
    Shaders/
      MurmurLiquid.metal            owner: pack-liquid   prefix ml_
      MurmurInk.metal               owner: pack-ink      prefix mi_
      MurmurLight.metal             owner: pack-light    prefix mg_
      MurmurSignal.metal            owner: pack-signal   prefix ms_
  Tests/MurmurTests/
    MurmurTests.swift               owner: core
  Lab/
    project.yml                     owner: lab (xcodegen)
    MurmurLab/                      owner: lab (app sources)
```

Each pack file copies the kit it needs from FieldLab.metal / FieldPackPour.metal
verbatim under its own prefix (`ml_`, `mi_`, `mg_`, `ms_`), comments included.
Copy only what the pack actually calls; no dead helpers behind a prefix.

## The uniform shader signature

Every style is one `[[ stitchable ]]` function with EXACTLY this signature
(only the function name changes):

```metal
[[ stitchable ]] half4 ml_eddy(
    float2 position,      // pixel position from colorEffect
    half4  currentColor,  // ignored; the view mounts on an opaque rectangle
    float2 size,          // view size in points
    float  time,          // seconds; drives all motion
    float  pixelScale,    // display scale, for the dither
    half4  inkColor,      // the ground the field dissolves into
    half4  toneColor,     // the single hue family anchor
    float  hueShift,      // radians, walks the family, default 0
    float  formScale,     // 1 = designed scale; bigger = bigger forms
    float  speed,         // 1 = designed tempo
    float  depth,         // palette range dial, 0.3 ... 2, default 1
    float  glow,          // emission/presence dial, default 1
    float  c0,            // character knob 0 (per-style meaning)
    float  c1,            // character knob 1
    float  c2,            // character knob 2
    float  c3,            // character knob 3
    float  epoch          // restart hook for settle arcs; 0 otherwise
)
```

Conventions every function follows:

- Normalize with aspect preserved: `float2 uv = (position - 0.5 * size) /
  min(size.x, size.y);` so the field is centered and size-independent.
  A style may of course use other frames internally, but the composition must
  center and scale correctly in non-square views.
- OUTPUT IS OPAQUE, ink-grounded. The field composites over `inkColor` inside
  the shader (the pour pack pattern: `mix(inkLin, drawn, containment)`), and
  the final write is `xx_out(rgb, position * pixelScale)` — the triangular
  dither, always last, alpha 1. The VIEW clips to a circle; the SHADER must
  bring its light down to pure ink before the rim so the clip never cuts a
  form. Copy `fl_edge` (or write a radial equivalent) and make everything fade
  well inside `length(uv) = 0.5`.
- Palette: `xx_palette(inkColor, toneColor, hueShift, depth)` then
  `xx_shade(pal, t)` — the copied rail, unmodified. Accent behavior comes from
  walking the rail, never from a second hue.
- Knee before out where emission can run hot (copy `pv_knee`).
- `epoch`: styles whose concept has an arrival (settling, gathering,
  coalescing) measure `tau = max(time - epoch, 0.0)` and state the arc in
  closed form (the `pv_exhale_law` pattern: speed as a law, position as its
  exact integral). Styles with no arc ignore it. Every style must still be
  ALIVE at rest: settled is a whisper of drift, never a freeze.
- Performance: fixed-count loops only, fBm at 4 octaves or fewer at the
  default, no more than ~12 field taps per pixel (the pour's bloom budget).
  Target: full-screen 60 fps on an iPhone 15; an indicator at 46 pt must be
  negligible.
- Determinism: any `time` value renders the correct frame (screenshot rigs
  and scrubbing depend on it). No state between frames.

## The style roster

Character knobs c0..c3 are each 0...1 with the listed default; the Swift layer
passes them through untouched. "arc" marks styles that honor `epoch`.
The one-liners are species intents, not implementations: give each its own
body and physics. Bold character deltas are wanted; strangers and clones are
not.

### MurmurLiquid.metal (ml_) — molten weight, the pour's blood, none of its form

| case | fn | species | c0 | c1 | c2 | c3 |
|---|---|---|---|---|---|---|
| eddy | ml_eddy | thought circling a center: a slow rotational shear field, light caught in the turn | swirl 0.5 | drift 0.3 | grain 0.4 | shear 0.5 |
| well | ml_well | pulling inward: light and density drawn toward a deep center that never fills | pull 0.5 | depthGlow 0.5 | churn 0.3 | offset 0.5 |
| tide | ml_tide | a slow wash crossing the frame and returning, weight leaning with it | reach 0.5 | lean 0.4 | foam 0.3 | period 0.5 |
| undertow | ml_undertow | two layers sliding opposite ways, structure born where they shear | contrast 0.5 | slip 0.5 | veil 0.3 | bias 0.5 |
| meander | ml_meander | one bright channel wandering through dark mass, the path is the thought | width 0.4 | wander 0.5 | bank 0.4 | flow 0.5 |
| confluence (arc) | ml_confluence | two flows finding each other and joining; joined is the rest state | approach 0.5 | mingle 0.5 | shimmer 0.3 | angle 0.5 |

### MurmurInk.metal (mi_) — ink and paper physics, capillary time

| case | fn | species | c0 | c1 | c2 | c3 |
|---|---|---|---|---|---|---|
| bloom (arc) | mi_bloom | ink meeting water: a front advancing with a live fBm edge, settling saturated | spread 0.5 | edgeTear 0.5 | tail 0.4 | asymmetry 0.3 |
| marbling | mi_marbling | combed ink: layered laminar folds sliding past each other, suminagashi tempo | folds 0.5 | comb 0.4 | contrast 0.5 | drift 0.3 |
| wick | mi_wick | ink drawn upward through fiber: capillary creep, gravity in reverse, grain of the paper visible in the climb | climb 0.5 | fiber 0.5 | pooling 0.3 | dryEdge 0.4 |
| strata (arc) | mi_strata | sediment settling into layers: horizontal density bands finding their level | layers 0.5 | settle 0.5 | disturb 0.2 | tilt 0.5 |
| halation | mi_halation | a dark mass wearing its own light: soft halo shifting as the mass slowly reforms | mass 0.5 | corona 0.5 | morph 0.4 | offset 0.5 |
| pool | mi_pool | ink already at rest, meniscus alive: the stillest style in the set, surface tension doing the thinking | tension 0.5 | tremor 0.2 | sheen 0.5 | tilt 0.5 |

### MurmurLight.metal (mg_) — light through media

| case | fn | species | c0 | c1 | c2 | c3 |
|---|---|---|---|---|---|---|
| caustic | mg_caustic | light refracted through moving water onto a floor: the web, soft, never cellular | web 0.5 | depthWater 0.5 | swim 0.4 | focus 0.5 |
| aurora | mg_aurora | a curtain of light folding in slow air, horizontal grammar, nothing falls | fold 0.5 | height 0.5 | wander 0.4 | thin 0.5 |
| ember | mg_ember | heat above a warm floor: shimmer rising, light pooled low | heat 0.5 | shimmer 0.4 | floor 0.5 | updraft 0.4 |
| lantern | mg_lantern | one light behind moving fog: presence felt through a medium, never seen directly | fog 0.5 | reach 0.5 | drift 0.4 | offset 0.5 |
| mirage | mg_mirage | horizontal refraction bands bending a distant light, the desert-road shimmer | bands 0.5 | bend 0.5 | distance 0.5 | haze 0.4 |
| oculus (arc) | mg_oculus | a soft aperture admitting light, opening as thought completes; open is rest | aperture 0.5 | rim 0.4 | beam 0.5 | dust 0.3 |

### MurmurSignal.metal (ms_) — order emerging from noise (the thinking metaphors)

| case | fn | species | c0 | c1 | c2 | c3 |
|---|---|---|---|---|---|---|
| murmuration | ms_murmuration | the namesake: a flock as one soft mass, density turning and folding over itself, individuals never resolvable | flock 0.5 | turn 0.5 | cohesion 0.5 | sky 0.3 |
| loom | ms_loom | threads finding a weave: warp and weft interference resolving into cloth and relaxing again | threads 0.5 | tension 0.5 | sheen 0.4 | angle 0.5 |
| cipher | ms_cipher | meaning surfacing: latent structure in a dark field, revealed where a slow attention passes | reveal 0.5 | structure 0.5 | dwell 0.5 | scatter 0.3 |
| tuning (arc) | ms_tuning | static finding the station: broadband noise narrowing toward a coherent line; coherent is rest, noise never fully gone | band 0.5 | lock 0.5 | hiss 0.3 | drift 0.4 |
| current | ms_current | signal moving through a medium: impulses traveling a soft network, felt as moving light, never drawn as wires | pathways 0.5 | pulseRate 0.4 | glow 0.5 | branch 0.5 |
| veil | ms_veil | layers of translucency sliding: what is behind almost legible, parallax as depth of thought | layers 0.5 | parallax 0.5 | legibility 0.4 | drift 0.3 |

## Swift API (owner: core)

```swift
public enum MurmurFamily: String, CaseIterable, Sendable, Codable {
    case liquid, ink, light, signal
}

public enum MurmurStyle: String, CaseIterable, Identifiable, Sendable, Codable {
    case eddy, well, tide, undertow, meander, confluence
    case bloom, marbling, wick, strata, halation, pool
    case caustic, aurora, ember, lantern, mirage, oculus
    case murmuration, loom, cipher, tuning, current, veil
    // id, family, displayName, shaderName ("ml_eddy" etc.),
    // characterKnobs: [MurmurKnob] (label + default from the roster tables),
    // hasArc: Bool (the (arc) styles)
}

public struct MurmurKnob: Sendable, Hashable {
    public let label: String       // "swirl"
    public let defaultValue: Double
}

public struct MurmurRGBA: Sendable, Codable, Equatable {
    public var r, g, b, a: Double  // sRGB; Color bridge both directions
}

public struct MurmurConfiguration: Sendable, Codable, Equatable {
    public var style: MurmurStyle
    public var speed: Double        // 1
    public var formScale: Double    // 1
    public var depth: Double        // 1
    public var glow: Double         // 1
    public var hueShift: Double     // 0 (radians)
    public var character: [Double]  // 4 values, style defaults on init
    public var ink: MurmurRGBA      // default 0.039, 0.039, 0.043 (house ink)
    public var tone: MurmurRGBA     // default 0.878, 0.545, 0.235 (warm amber)
    public init(style: MurmurStyle) // fills character with style defaults
}

/// The indicator. A circle of living material.
public struct MurmurView: View {
    public init(
        _ configuration: MurmurConfiguration,
        animated: Bool = true,     // false renders the frame at stillTime
        stillTime: Double = 4.0,
        fps: Double = 30           // the house periodic cadence
    )
    // TimelineView(.periodic) -> visualEffect -> colorEffect, the
    // AtmosphereField.swift pattern. Rectangle base, .clipShape(Circle()).
    // ShaderLibrary.bundle(.module). Pass epoch via an @State birth Date so
    // arc styles restart when the view appears.
}

/// The drop-in chat pill, mirroring the ergonomics of the inspiration piece.
public struct MurmurPill: View {
    public init(
        _ configuration: MurmurConfiguration,
        label: String = "Thinking...",
        showsPill: Bool = true,
        showsLabel: Bool = true,
        indicatorSize: CGFloat = 46
    )
    // Chip ground = configuration.ink so the field dissolves into its pill.
    // Light scheme: derive a paper chip and dark label automatically unless
    // overridden; keep the API small.
}

extension MurmurConfiguration {
    /// The copy-for-agent export: a fenced Swift snippet with the exact
    /// MurmurView/MurmurPill call, the SPM dependency line, and a short prose
    /// spec (style species line, knob values with their labels, colors as hex)
    /// written so a coding agent with no other context can implement it.
    public func agentPrompt(as surface: MurmurExportSurface) -> String
}

public enum MurmurExportSurface: String, CaseIterable, Sendable {
    case pill        // MurmurPill drop-in
    case indicator   // bare MurmurView
    case swiftUIOnly // no package: emits the shader function + minimal host view, self-contained
}
```

`swiftUIOnly` export copies the style's actual Metal function (with its kit)
into the snippet so a buyer can paste one file into any app; the exporter
reads the .metal source from the module bundle at runtime. If bundling the
source proves fragile, emit the package-dependency form and note it; do not
ship a broken exporter.

## Lab app (owner: lab)

iOS app, deployment target 26.0, SDK current (Xcode 27), xcodegen project
(`Lab/project.yml`, bundle id `com.krispuckett.MurmurLab`, name "Murmur Lab"),
local package dependency on `../`. NEVER hand-edit the generated pbxproj;
regenerate.

Structure, three screens, house grammar throughout (Liquid Glass; glass card
overlays, never stock sheets with platters; no `.background()` before
`.glassEffect()`; mono for labels and values; sub-44pt tap targets banned):

1. **Gallery.** All 24 styles live, grouped by family, each a circle indicator
   on the ink ground with its mono name. Dark ground (this is a product
   stage). Tap opens the studio.
2. **Studio.** One style large (~300 pt) on top, a size row under it (20, 46,
   120 pt simultaneously, so scale-truth is always visible), then the panel:
   shared dials (speed, formScale, depth, glow, hueShift), the style's four
   character dials with their real labels, ink/tone color controls (a small
   curated tone row plus ColorPicker), light/dark preview toggle, pill
   preview with editable label. Every dial is a house glass-row, mono value
   readout, drag to set, tap value to reset to default.
3. **Export.** The copy-for-agent sheet: surface choice (pill / indicator /
   self-contained), the generated prompt in a mono scroll, one big Copy
   button. Copies via UIPasteboard.

No settings screen, no onboarding, no tab bar unless three screens truly need
it (a gallery that pushes to studio, studio presents export, is enough).

## Build verification

- Package: `cd /Users/kris/Developer/murmur && xcodebuild -scheme Murmur -destination 'generic/platform=iOS Simulator' build` (compiles the metallib; `swift build` alone does not).
- Lab: `cd Lab && xcodegen && xcodebuild -project MurmurLab.xcodeproj -scheme MurmurLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` (adjust to an available simulator).
- Tests: config init fills defaults; Codable round-trip; agentPrompt contains the style name, all four knob labels, and both hex colors; every MurmurStyle has exactly 4 knobs and a non-empty shaderName.

## What "done" means for a pack

The pack file compiles in the package build, every function honors the
signature and conventions above, and each style at DEFAULT knobs, default
colors, at 46 pt and at 300 pt, is something you would leave running in a
shipping chat UI: calm, legible, alive. The reviewing session will screenshot
every style and kill what reads as a stranger, a clone, or a screensaver.
Write generous header comments in the house voice: say why the numbers are
what they are.
