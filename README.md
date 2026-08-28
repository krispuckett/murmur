# Murmur

Thinking indicators for AI products, built as living material. Murmur is a
Swift package with 24 Metal shader species behind one SwiftUI view, a lab app
for designing a configuration by hand, and an export that writes the
implementation prompt for a coding agent.

Every style is generated per pixel in a fragment shader. There are no videos,
no particle systems, no sprite sheets, and nothing that pulses for attention.
The family verbs are flow and settle: motion you feel rather than watch, calm
enough to sit beside someone's words while a model thinks.

## Quick start

Add the package:

```swift
.package(url: "https://github.com/krispuckett/murmur", from: "0.1.0")
```

Drop the pill into a chat UI:

```swift
import Murmur

MurmurPill(MurmurConfiguration(style: .murmuration))
```

Or mount the bare indicator anywhere, at any size:

```swift
MurmurView(MurmurConfiguration(style: .eddy))
    .frame(width: 46, height: 46)
```

Both views adapt to light and dark. A configuration is Codable, so a design
can be saved, versioned, or sent across a wire.

## The lab

`Lab/MurmurLab.xcodeproj` is an iOS app for designing a configuration by
hand: a gallery of all 24 species running live, a studio with the style at
300 pt over a size-truth row (20, 46, 120 pt at once), dials for the shared
parameters and the style's four character knobs, curated tones plus full
color pickers, and pill previews on both stages.

The Export button writes the whole design as a prompt: the dependency line,
the exact configuration call with every value you changed, and a short spec.
Copy it, paste it to your coding agent, and the agent has everything it needs
without ever seeing the app.

The project file is generated; edit `Lab/project.yml` and rerun `xcodegen`
rather than touching the pbxproj. `-openStyle <case>` as a launch argument
jumps straight to any studio, which is how agents drive it for screenshots.

## The roster

Four families, six species each. Names are `MurmurStyle` cases.

| Family | Species |
|---|---|
| liquid | eddy, well, tide, undertow, meander, confluence |
| ink | bloom, marbling, wick, strata, halation, pool |
| light | caustic, aurora, ember, lantern, mirage, oculus |
| signal | murmuration, loom, cipher, tuning, current, veil |

Five species (confluence, bloom, strata, oculus, tuning) have an arrival arc:
they run once from birth toward a settled state when the view appears, and
settled is still alive, a whisper of drift rather than a freeze. The arcs are
closed-form, so any time value renders the correct frame.

## Parameters

Shared across every style: `speed`, `formScale`, `depth` (how far the palette
opens), `glow`, `hueShift`, plus `ink` and `tone` colors. Each style adds
four character knobs with real names (eddy has swirl, drift, grain, shear)
that you can read off `style.characterKnobs`.

Color is two anchors, ink and tone, walked through an OKLAB rail into a four
stop palette: the ink the field dissolves into, a warm shadow that keeps its
chroma, the tone itself, and a pale specular a few degrees warmer. One hue
family per configuration; the rail keeps the dark end out of the mud and the
bright end out of white.

## How it is drawn

Each species is one `[[stitchable]]` Metal function driven by time, mounted
with `TimelineView` and `colorEffect` at 30 fps. The craft underneath is
shared: quintic-interpolated gradient noise and fBm for the bodies,
triangular-PDF dither on the final write so eight-bit darks stay smooth, a
soft knee where emission runs hot so peaks compress instead of clipping, and
a radial containment that brings every form down to ink before the circle's
edge. Deterministic in time, no state between frames, four octaves or fewer
at default.

## Requirements

The package needs iOS 17 or macOS 14 (the SwiftUI shader API). The lab app
targets iOS 26.
