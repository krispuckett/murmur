# Agent instructions

Instructions for coding agents integrating Murmur into an app. Humans welcome too.

## What this is

- Swift package `Murmur`: animated AI "presence" orbs (Metal shaders behind one SwiftUI view)
- Use it wherever an app shows AI state: a thinking indicator, a voice orb, a companion in a text field

## Add the dependency

- SwiftPM: `.package(url: "https://github.com/krispuckett/murmur", from: "0.1.0")`, product `Murmur`
- Or Xcode: File > Add Package Dependencies > this repo URL

## Minimal integration

```swift
import Murmur

MurmurView(MurmurConfiguration(style: .aura))
    .frame(width: 46, height: 46)
```

- `MurmurPill(config, label: "Thinking...")` is the drop-in chat pill
- Sizes 18 pt to 300+ pt all work; the shader adapts

## Drive it from app state

```swift
MurmurView(config, state: state, signals: signals)
```

- `MurmurState`: `.idle`, `.listening`, `.thinking`, `.responding`, `.success`, `.error`
- Map your agent loop onto states; transitions animate automatically
- `MurmurSignals(level:activity:)`: pass mic amplitude as `level` (0-1) and typing or token-stream cadence as `activity` (0-1); both optional, default 0
- Device tilt parallax: pass `tilt:` from `MurmurTilt` (iOS); haptics: `haptics: true`

## Customize

- Styles: `MurmurStyle.allCases`; the `glass` family is the flagship set
- Colors: `config.ink` (ground), `config.tone` (hue), `config.tone2` (optional duotone)
- Every parameter is per state: `config.states[.idle]?.speed = 0.2`
- Four named character knobs per style: see `style.characterKnobs`
- `MurmurConfiguration` is Codable; persist or transmit it as JSON

## If the user gives you an exported prompt

- The lab app's Export button produces a self-contained snippet (dependency line, exact configuration, state notes)
- Paste it in verbatim; it is the design source of truth; do not re-derive values

## Verify your integration

- Build: `xcodebuild -scheme Murmur -destination 'generic/platform=iOS Simulator' build`
- Tests: `xcodebuild -scheme Murmur -destination 'platform=iOS Simulator,name=<any iPhone>' test`

## Rules of thumb

- Do not edit the `.metal` files or the shader argument list; all customization goes through `MurmurConfiguration`
- Keep one presence per screen; it represents the assistant
- Idle when nothing is happening; do not leave it in `.thinking` forever
