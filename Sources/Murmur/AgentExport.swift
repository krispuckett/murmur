// Copy for agent. The lab's whole point is that a designer tunes a species
// by hand and then hands the result to whoever implements it, with nothing
// lost in the handoff. So the export is written for a coding agent that has
// never seen this package: what the thing is, how to get it, the exact call,
// and every number spelled out in prose underneath in case the snippet has
// to be adapted.
//
// Since a state is a full design, the export has to carry six dial sets, not
// one. It prints the construction for every state that departs from its seed
// and lists them all in prose, so nothing depends on a reader knowing what
// the seeds are. The live signals ride alongside them.
//
// House voice throughout: plain sentences, no em dashes, no adjectives that
// sell. The agent reading this needs facts, not a pitch.

import Foundation

public enum MurmurExportSurface: String, CaseIterable, Sendable {
    /// The drop-in chat pill.
    case pill
    /// The bare circle, sized by the caller.
    case indicator
    /// No package: the Metal source plus a host view, one file to paste.
    case swiftUIOnly

    public var displayName: String {
        switch self {
        case .pill: "Pill"
        case .indicator: "Indicator"
        case .swiftUIOnly: "Self-contained"
        }
    }
}

extension MurmurConfiguration {
    /// The copy-for-agent export.
    public func agentPrompt(as surface: MurmurExportSurface) -> String {
        var out: [String] = []

        // Read once. Whether the pack source is readable decides three things
        // below (the install note, which snippet, whether the file is
        // appended), and it is the only part of this that touches disk.
        let packSource = surface == .swiftUIOnly
            ? MurmurExport.packSource(for: style.family)
            : nil

        out.append(
            "Murmur thinking indicator: \(style.displayName) "
                + "(style .\(style.rawValue), family \(style.family.rawValue))."
        )
        out.append("")
        out.append("What it is: \(style.species).")
        out.append("")
        out.append(
            "It renders as one circle of living material, generated per pixel "
                + "in Metal. The shader function is \(style.shaderName)."
        )
        out.append(
            style.hasArc
                ? "It runs a settle arc from the moment it appears and keeps drifting once it arrives."
                : "It has no arrival arc. It is the same weather whenever you look at it."
        )
        out.append("")

        // Install
        out.append("## Install")
        out.append("")
        switch surface {
        case .pill, .indicator:
            out.append(contentsOf: Self.packageInstallLines)
        case .swiftUIOnly:
            if packSource != nil {
                out.append(
                    "No package needed. Add the Metal file at the bottom of this "
                        + "message to your app target, then paste the Swift view. "
                        + "Metal shaders need a real target build; they do not run "
                        + "in a source-only playground."
                )
            } else {
                out.append(
                    "The self-contained export could not read the Metal source out "
                        + "of the package bundle on this device, so this is the "
                        + "package form instead. It produces the same indicator."
                )
                out.append("")
                out.append(contentsOf: Self.packageInstallLines)
            }
        }
        out.append("")

        // Code
        out.append("## Code")
        out.append("")
        out.append("```swift")
        switch surface {
        case .pill:
            out.append(packageSnippet(call: "MurmurPill(Self.murmur, state: state)"))
        case .indicator:
            out.append(
                packageSnippet(
                    call: "MurmurView(Self.murmur, state: state)\n            .frame(width: 46, height: 46)"
                )
            )
        case .swiftUIOnly:
            if packSource != nil {
                out.append(selfContainedSnippet())
            } else {
                out.append(packageSnippet(call: "MurmurPill(Self.murmur, state: state)"))
            }
        }
        out.append("```")
        out.append("")

        out.append(contentsOf: stateSection(for: surface))
        out.append("")
        out.append(contentsOf: designSection())
        out.append("")

        out.append("Colors, sRGB, shared by every state:")
        out.append("- ink, the ground the field dissolves into: \(ink.hexString)")
        out.append("- tone, the hue family anchor: \(tone.hexString)")
        if let tone2 {
            out.append(
                "- tone2, the second duotone anchor: \(tone2.hexString). The "
                    + "interior palette runs between the two anchors through OKLAB "
                    + "instead of deriving that side from the spread knob."
            )
        }
        out.append("")
        out.append(
            "Match every value above. The indicator is the whole visual: no "
                + "border, no shadow, no second hue, and no spinner behind it."
        )

        if let source = packSource {
            out.append("")
            out.append("## \(style.family.packFileName).metal")
            out.append("")
            out.append(
                "This is the whole \(style.family.rawValue) pack: the shared kit and "
                    + "its \(style.family.styles.count) species. Keep \(style.shaderName) and "
                    + "delete the other \(style.family.styles.count - 1) functions if you "
                    + "want a smaller file."
            )
            out.append("")
            out.append("```metal")
            out.append(source.trimmingCharacters(in: .whitespacesAndNewlines))
            out.append("```")
        }

        return out.joined(separator: "\n")
    }

    // MARK: - The state sections

    /// How the host drives the thing. Without this an agent ships a pill
    /// that says "thinking" while the answer is already streaming.
    private func stateSection(for surface: MurmurExportSurface) -> [String] {
        var lines: [String] = []
        lines.append("## Driving the state")
        lines.append("")
        lines.append(
            "There are six states: idle, listening, thinking, responding, success "
                + "and error. Each one is a complete design rather than a tint on a "
                + "base, and the view crosses the whole dial set over about "
                + "\(MurmurExport.number(MurmurState.transitionDuration)) seconds "
                + "when the state changes. Pass the state that matches what the "
                + "agent is doing."
        )
        lines.append("")

        switch surface {
        case .pill:
            lines.append("```swift")
            lines.append("MurmurPill(Self.murmur, state: agentIsStreaming ? .responding : .thinking)")
            lines.append("```")
            lines.append("")
        case .indicator:
            lines.append("```swift")
            lines.append("MurmurView(Self.murmur, state: agentIsStreaming ? .responding : .thinking)")
            lines.append("```")
            lines.append("")
        case .swiftUIOnly:
            lines.append(
                "The view above holds one state. To drive all six, swap in the dial "
                    + "sets listed below, cross them over about "
                    + "\(MurmurExport.number(MurmurState.transitionDuration)) seconds "
                    + "with a smoothstep, and pass the matching stateIndex."
            )
            lines.append("")
        }

        lines.append(contentsOf: Self.entryLines)
        lines.append("")
        lines.append(
            "Entering thinking or success also restarts the shader clock"
                + (style.hasArc
                    ? ", which is how this style replays its arrival arc."
                    : ". This style has no arc, so that only matters for the entry.")
        )
        lines.append("")
        lines.append(
            "The shader is told which state it is in: stateIndex is 0 idle, "
                + "1 listening, 2 thinking, 3 responding, 4 success, 5 error, and "
                + "stateTau is the seconds since that state was entered. During a "
                + "crossfade the index is the state being entered."
        )
        lines.append("")
        lines.append(contentsOf: Self.signalLines(for: surface))
        if style.family == .glass {
            lines.append("")
            lines.append(
                "This is a glass hero, so its shader takes two arguments the "
                    + "other families do not, after activity: a float2 tilt, the "
                    + "device attitude from CoreMotion at roughly -1 to 1 per "
                    + "axis and 0,0 when unavailable, which parallaxes the "
                    + "interior while the body holds still; and a half4 tone2, "
                    + "the second duotone anchor, which equals tone unless one "
                    + "was set. Pass MurmurTilt's point, or zero, or a drag: the "
                    + "view does not own the motion manager."
            )
        }
        return lines
    }

    /// The live half. A presence that ignores its person is decoration, so
    /// an agent that wires the states but not the signals has built half of
    /// this.
    private static func signalLines(for surface: MurmurExportSurface) -> [String] {
        var lines = [
            "The indicator also listens. Feed it two live scalars, both 0 to 1: "
                + "level is voice energy off the microphone, and activity is typing "
                + "cadence or token stream rate. Send them every frame; they are "
                + "not saved with the design, they are what is happening right now.",
            "",
        ]
        switch surface {
        case .pill:
            lines.append("```swift")
            lines.append("MurmurPill(Self.murmur, state: state, signals: MurmurSignals(level: micLevel, activity: typingRate))")
            lines.append("```")
        case .indicator:
            lines.append("```swift")
            lines.append("MurmurView(Self.murmur, state: state, signals: MurmurSignals(level: micLevel, activity: typingRate))")
            lines.append("```")
        case .swiftUIOnly:
            lines.append(
                "They are the last two shader arguments. Smooth them before "
                    + "they reach the shader, with a rise of about "
                    + "\(MurmurExport.number(MurmurSignals.attack)) seconds and a fall of about "
                    + "\(MurmurExport.number(MurmurSignals.release)) seconds, or the "
                    + "waveform's own jitter arrives as flicker."
            )
        }
        lines.append("")
        lines.append(
            "Every species gets a small generic response on top of its design: "
                + "activity quickens the tempo by up to "
                + "\(Int(MurmurSignals.activitySpeedLift * 100)) percent and level "
                + "lifts the glow by up to \(Int(MurmurSignals.levelGlowLift * 100)) "
                + "percent. The presence family builds a deeper per-species "
                + "response from the raw values as well."
        )
        return lines
    }

    /// Every design in prose, so nothing depends on reading the snippet.
    private func designSection() -> [String] {
        var lines: [String] = []
        lines.append("## The six state designs")
        lines.append("")
        lines.append(
            "Each block is one complete dial set. 1.0 is the value the style "
                + "itself was tuned at, so a number above 1 opens the material up "
                + "and a number below 1 quiets it."
        )
        lines.append("")

        let custom = Set(customizedStates)
        let labels = style.characterKnobs.map(\.label)
        for state in MurmurState.allCases {
            let p = resolvedParameters(for: state)
            let mark = custom.contains(state) ? ", customized" : ""
            lines.append("\(state.rawValue) (entry \(entry(for: state).rawValue)\(mark))")
            lines.append(
                "- speed \(MurmurExport.number(p.speed)), "
                    + "form scale \(MurmurExport.number(p.formScale)), "
                    + "depth \(MurmurExport.number(p.depth)), "
                    + "glow \(MurmurExport.number(p.glow)), "
                    + "hue shift \(MurmurExport.number(p.hueShift))"
            )
            lines.append(
                "- "
                    + zip(labels, p.character)
                    .map { "\($0) \(MurmurExport.number($1))" }
                    .joined(separator: ", ")
            )
            lines.append("")
        }

        if custom.isEmpty {
            lines.append(
                "Every state is at its seed, so constructing the configuration "
                    + "from the style alone reproduces all of this."
            )
        } else {
            lines.append(
                "The states marked customized were tuned by hand and are written "
                    + "out in the snippet above. The rest are seeds."
            )
        }
        return lines
    }

    /// What the four entry names mean, in the terms whoever reimplements
    /// this will need. The numbers match MurmurEntry.
    private static var entryLines: [String] {
        [
            "The entry is the one-shot the change itself looks like:",
            "- none: nothing beyond the dial crossing.",
            "- wake: the tempo overshoots by 60 percent and decays back with a "
                + "0.4 second time constant. The material wakes up.",
            "- swell: the glow rises to 35 percent above its level, peaking near "
                + "0.4 seconds and gone by 1.5. The arrival breath.",
            "- stutter: the clock catches twice inside the first half second, "
                + "then settles clean. Keep the catches soft enough to read as "
                + "the material snagging; a hard hold reads as a broken frame.",
        ]
    }

    private static var packageInstallLines: [String] {
        [
            "Add the package dependency:",
            "",
            "    .package(url: \"\(MurmurInfo.repositoryURL)\", from: \"\(MurmurInfo.version)\")",
            "",
            "then add \"Murmur\" to the target's dependencies.",
        ]
    }

    // MARK: - Snippets

    /// The package form. Only what departs from the seed gets written, so
    /// the snippet reads as the decisions that were actually made.
    private func packageSnippet(call: String) -> String {
        var mutations: [String] = []

        if ink != .ink { mutations.append("c.ink = \(MurmurExport.literal(ink))") }
        if tone != .tone { mutations.append("c.tone = \(MurmurExport.literal(tone))") }
        if let tone2 { mutations.append("c.tone2 = \(MurmurExport.literal(tone2))") }

        for state in MurmurState.allCases {
            let design = parameters(for: state)
            if design != state.seedParameters(for: style) {
                mutations.append(
                    "c.states[.\(state.rawValue)] = "
                        + MurmurExport.literal(design, style: style, indent: "        ")
                )
            }
            if entry(for: state) != state.defaultEntry {
                mutations.append("c.entries[.\(state.rawValue)] = .\(entry(for: state).rawValue)")
            }
        }

        let configuration: String
        if mutations.isEmpty {
            configuration = "    static let murmur = MurmurConfiguration(style: .\(style.rawValue))"
        } else {
            let body = mutations.map { "        \($0)" }.joined(separator: "\n")
            configuration = """
                    static var murmur: MurmurConfiguration {
                        var c = MurmurConfiguration(style: .\(style.rawValue))
                \(body)
                        return c
                    }
                """
        }

        return """
            import SwiftUI
            import Murmur

            struct ThinkingIndicator: View {
                var state: MurmurState = .thinking

                var body: some View {
                    \(call)
                }

            \(configuration)
            }
            """
    }

    /// The no-package form. Same mount, same argument order, every value
    /// written as a literal so the file has no dependencies at all. It runs
    /// the thinking design; the other four are in the prose below it.
    private func selfContainedSnippet() -> String {
        let design = resolvedParameters(for: .thinking)
        let knobs = style.characterKnobs
        // Written at the depth the surrounding argument list lands at once
        // the literal below is de-indented. Interpolated lines keep their own
        // whitespace, so this has to match by hand.
        let knobLines = (0..<4).map { i in
            String(repeating: " ", count: 28)
                + ".float(\(MurmurExport.number(design.character[i]))),  // \(knobs[i].label)"
        }.joined(separator: "\n")
        // The heroes take two more, appended as a suffix so the archive
        // families' call ends exactly where it used to and no trailing comma
        // is left behind.
        let pad = String(repeating: " ", count: 28)
        let isGlass = style.family == .glass
        let glassSuffix = isGlass
            ? ",\n" + pad + ".float2(tilt),  // device attitude, 0,0 when unavailable\n"
                + pad + ".color(\(MurmurExport.colorLiteral(resolvedTone2)))  // tone2"
            : ""
        let tiltProperty = isGlass
            ? "\n                /// Device attitude, roughly -1 to 1 per axis. Zero is fine."
                + "\n                var tilt: CGPoint = .zero"
            : ""


        return """
            import SwiftUI

            /// \(style.displayName). \(MurmurExport.sentence(style.species))
            /// Needs \(style.family.packFileName).metal in the same target.
            /// This runs the thinking design; the other state designs are
            /// listed below, along with what stateIndex and stateTau mean.
            struct \(style.displayName)Indicator: View {
                var size: CGFloat = 46
                /// Live signals from the host, 0 to 1. Smooth them before
                /// they get here: rise about \(MurmurExport.number(MurmurSignals.attack)) s, fall about \(MurmurExport.number(MurmurSignals.release)) s.
                var level: Double = 0
                var activity: Double = 0\(tiltProperty)

                @Environment(\\.displayScale) private var displayScale
                @State private var birth = Date.now

                var body: some View {
                    let ink = \(MurmurExport.colorLiteral(ink))
                    let tone = \(MurmurExport.colorLiteral(tone))
                    let scale = displayScale

                    TimelineView(.periodic(from: birth, by: 1.0 / 30.0)) { context in
                        let time = birth.distance(to: context.date)
                        Rectangle()
                            .fill(ink)
                            .visualEffect { content, proxy in
                                content.colorEffect(
                                    ShaderLibrary.\(style.shaderName)(
                                        .float2(proxy.size),
                                        .float(time),
                                        .float(scale),
                                        .color(ink),
                                        .color(tone),
                                        .float(\(MurmurExport.number(design.hueShift))),  // hueShift
                                        .float(\(MurmurExport.number(design.formScale))),  // formScale
                                        .float(\(MurmurExport.number(design.speed))),  // speed
                                        .float(\(MurmurExport.number(design.depth))),  // depth
                                        .float(\(MurmurExport.number(design.glow))),  // glow
            \(knobLines)
                                        .float(0.0),  // epoch
                                        .float(2.0),  // stateIndex: thinking
                                        .float(time),  // stateTau
                                        .float(level),
                                        .float(activity)\(glassSuffix)
                                    )
                                )
                            }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                }
            }
            """
    }
}

enum MurmurExport {
    /// Swift-source safe, and short. Three decimals is finer than any dial
    /// in the lab resolves, and the trailing ".0" keeps every literal a Double.
    static func number(_ value: Double) -> String {
        var text = String(format: "%.3f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text += "0" }
        return text
    }

    /// The roster writes species lines lowercase, which reads right after
    /// "What it is:" and wrong as a doc comment. One capital, one period.
    static func sentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst() + "."
    }

    static func literal(_ rgba: MurmurRGBA) -> String {
        let base = "MurmurRGBA(r: \(number(rgba.r)), g: \(number(rgba.g)), b: \(number(rgba.b))"
        return rgba.a >= 1 ? base + ")" : base + ", a: \(number(rgba.a)))"
    }

    /// Multi-line, because six dials and four knobs on one line is a scroll
    /// bar. The caller's indent is applied to the continuation lines; the
    /// first line inherits whatever the mutation list puts in front of it.
    static func literal(
        _ parameters: MurmurParameters,
        style: MurmurStyle,
        indent: String
    ) -> String {
        let values = parameters.resolvedCharacter(for: style)
            .map(number)
            .joined(separator: ", ")
        let labels = style.characterKnobs.map(\.label).joined(separator: ", ")
        return [
            "MurmurParameters(",
            indent + "    speed: \(number(parameters.speed)), "
                + "formScale: \(number(parameters.formScale)), "
                + "depth: \(number(parameters.depth)),",
            indent + "    glow: \(number(parameters.glow)), "
                + "hueShift: \(number(parameters.hueShift)),",
            indent + "    character: [\(values)]  // \(labels)",
            indent + ")",
        ].joined(separator: "\n")
    }

    static func colorLiteral(_ rgba: MurmurRGBA) -> String {
        "Color(.sRGB, red: \(number(rgba.r)), green: \(number(rgba.g)), "
            + "blue: \(number(rgba.b)), opacity: \(number(rgba.a)))"
    }

    /// The pack source, if SwiftPM left it readable in the bundle. It may
    /// not: `.process` compiles .metal into the metallib and is free to drop
    /// the source. The exporter treats that as a normal outcome and falls
    /// back to the package form rather than emitting half a file.
    static func packSource(for family: MurmurFamily) -> String? {
        let name = family.packFileName
        let candidates = [
            Bundle.module.url(forResource: name, withExtension: "metal"),
            Bundle.module.url(forResource: name, withExtension: "metal", subdirectory: "Shaders"),
        ]
        for case let url? in candidates {
            if let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
                return text
            }
        }
        return nil
    }
}
