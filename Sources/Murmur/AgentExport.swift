// Copy for agent. The lab's whole point is that a designer tunes a species
// by hand and then hands the result to whoever implements it, with nothing
// lost in the handoff. So the export is written for a coding agent that has
// never seen this package: what the thing is, how to get it, the exact call,
// and every number spelled out in prose underneath in case the snippet has
// to be adapted.
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
            out.append(packageSnippet(call: "MurmurPill(Self.murmur)"))
        case .indicator:
            out.append(
                packageSnippet(
                    call: "MurmurView(Self.murmur)\n            .frame(width: 46, height: 46)"
                )
            )
        case .swiftUIOnly:
            if packSource != nil {
                out.append(selfContainedSnippet())
            } else {
                out.append(packageSnippet(call: "MurmurPill(Self.murmur)"))
            }
        }
        out.append("```")
        out.append("")

        // The numbers, in prose, so nothing depends on reading the snippet.
        out.append("## The exact configuration")
        out.append("")
        out.append("Shared dials, 1.0 is the value each style was tuned at:")
        out.append("- speed: \(MurmurExport.number(speed))")
        out.append("- form scale: \(MurmurExport.number(formScale))")
        out.append("- depth: \(MurmurExport.number(depth))")
        out.append("- glow: \(MurmurExport.number(glow))")
        out.append("- hue shift: \(MurmurExport.number(hueShift)) radians")
        out.append("")
        out.append("Character knobs, each 0 to 1, in c0 to c3 order:")
        for pair in knobValues {
            out.append("- \(pair.knob.label): \(MurmurExport.number(pair.value))")
        }
        out.append("")
        out.append("Colors, sRGB:")
        out.append("- ink, the ground the field dissolves into: \(ink.hexString)")
        out.append("- tone, the single hue family anchor: \(tone.hexString)")
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
                    + "its six species. Keep \(style.shaderName) and delete the other "
                    + "five functions if you want a smaller file."
            )
            out.append("")
            out.append("```metal")
            out.append(source.trimmingCharacters(in: .whitespacesAndNewlines))
            out.append("```")
        }

        return out.joined(separator: "\n")
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

    /// The package form. Only values that differ from the style's tuned
    /// defaults get written, so the snippet reads as the decisions that were
    /// actually made.
    private func packageSnippet(call: String) -> String {
        let defaults = MurmurConfiguration(style: style)
        var mutations: [String] = []

        if speed != defaults.speed { mutations.append("c.speed = \(MurmurExport.number(speed))") }
        if formScale != defaults.formScale {
            mutations.append("c.formScale = \(MurmurExport.number(formScale))")
        }
        if depth != defaults.depth { mutations.append("c.depth = \(MurmurExport.number(depth))") }
        if glow != defaults.glow { mutations.append("c.glow = \(MurmurExport.number(glow))") }
        if hueShift != defaults.hueShift {
            mutations.append("c.hueShift = \(MurmurExport.number(hueShift))")
        }
        if resolvedCharacter != defaults.resolvedCharacter {
            let values = resolvedCharacter.map(MurmurExport.number).joined(separator: ", ")
            let labels = style.characterKnobs.map(\.label).joined(separator: ", ")
            mutations.append("c.character = [\(values)] // \(labels)")
        }
        if ink != defaults.ink { mutations.append("c.ink = \(MurmurExport.literal(ink))") }
        if tone != defaults.tone { mutations.append("c.tone = \(MurmurExport.literal(tone))") }

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
                var body: some View {
                    \(call)
                }

            \(configuration)
            }
            """
    }

    /// The no-package form. Same mount, same argument order, every value
    /// written as a literal so the file has no dependencies at all.
    private func selfContainedSnippet() -> String {
        let character = resolvedCharacter
        let knobs = style.characterKnobs
        // Written at the depth the surrounding argument list lands at once
        // the literal below is de-indented. Interpolated lines keep their own
        // whitespace, so this has to match by hand.
        let knobLines = (0..<4).map { i in
            String(repeating: " ", count: 28)
                + ".float(\(MurmurExport.number(character[i]))),  // \(knobs[i].label)"
        }.joined(separator: "\n")

        return """
            import SwiftUI

            /// \(style.displayName). \(MurmurExport.sentence(style.species))
            /// Needs \(style.family.packFileName).metal in the same target.
            struct \(style.displayName)Indicator: View {
                var size: CGFloat = 46

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
                                        .float(\(MurmurExport.number(hueShift))),  // hueShift
                                        .float(\(MurmurExport.number(formScale))),  // formScale
                                        .float(\(MurmurExport.number(speed))),  // speed
                                        .float(\(MurmurExport.number(depth))),  // depth
                                        .float(\(MurmurExport.number(glow))),  // glow
            \(knobLines)
                                        .float(0.0)  // epoch
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
