// The drop-in. A chat client should be able to paste one line and have a
// thinking indicator that looks like it belongs to the app.
//
// The one rule that makes it look right: the chip and the shader's ink are
// the SAME color. The field is opaque and grounded, so if the chip were a
// different neutral you would see a disc sitting on a pill instead of a
// field opening inside one. In light appearance we swap both to paper
// together, never one of them.

import SwiftUI

public struct MurmurPill: View {
    private let configuration: MurmurConfiguration
    private let label: String
    private let showsPill: Bool
    private let showsLabel: Bool
    private let indicatorSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(
        _ configuration: MurmurConfiguration,
        label: String = "Thinking...",
        showsPill: Bool = true,
        showsLabel: Bool = true,
        indicatorSize: CGFloat = 46
    ) {
        self.configuration = configuration
        self.label = label
        self.showsPill = showsPill
        self.showsLabel = showsLabel
        self.indicatorSize = indicatorSize
    }

    /// Light appearance gets a paper chip rather than the house ink, so the
    /// pill does not read as a dark slab dropped into a light thread.
    private var ground: MurmurRGBA {
        colorScheme == .light ? .paper : configuration.ink
    }

    private var grounded: MurmurConfiguration {
        var copy = configuration
        copy.ink = ground
        return copy
    }

    private var labelColor: Color {
        colorScheme == .light
            ? Color(.sRGB, red: 0.13, green: 0.13, blue: 0.15, opacity: 1)
            : Color(.sRGB, red: 0.80, green: 0.80, blue: 0.83, opacity: 1)
    }

    /// The chip breathes with the indicator: at 46 pt this is 6, which keeps
    /// the pill above the 44 pt tap floor without looking padded.
    private var inset: CGFloat { max(6, indicatorSize * 0.13) }

    public var body: some View {
        HStack(spacing: indicatorSize * 0.22) {
            MurmurView(grounded)
                .frame(width: indicatorSize, height: indicatorSize)

            if showsLabel {
                Text(label)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
            }
        }
        .padding(.leading, showsPill ? inset : 0)
        .padding(.trailing, showsPill ? (showsLabel ? inset * 2.6 : inset) : 0)
        .padding(.vertical, showsPill ? inset : 0)
        .background {
            if showsPill {
                Capsule(style: .continuous).fill(ground.color)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
