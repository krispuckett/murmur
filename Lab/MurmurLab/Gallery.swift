// All 24 species on the dark ground, alive. The cells carry the studio's
// current colors so the gallery is a view of one configuration across the
// roster, not a contact sheet of factory defaults.

import SwiftUI
import Murmur

struct Gallery: View {
    @Environment(LabModel.self) private var model

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header

                ForEach(MurmurFamily.allCases, id: \.self) { family in
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(text: family.displayName)
                        LazyVGrid(columns: columns, spacing: 22) {
                            ForEach(family.styles) { style in
                                NavigationLink(value: style) {
                                    GalleryCell(style: style, base: model.config)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 48)
        }
        .background(LabTheme.ink.ignoresSafeArea())
        .navigationDestination(for: MurmurStyle.self) { style in
            Studio(style: style)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Murmur")
                .font(LabTheme.mono(30, .medium))
                .foregroundStyle(.white)
            Text("24 thinking indicators")
                .font(LabTheme.mono(12))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(.top, 8)
    }
}

private struct GalleryCell: View {
    let style: MurmurStyle
    let base: MurmurConfiguration

    var body: some View {
        VStack(spacing: 10) {
            // 24 fps in the grid: enough for flow to read, cheap enough to
            // run every species at once.
            MurmurView(base.withStyle(style), fps: 24)
                .frame(width: 76, height: 76)

            Text(style.displayName)
                .font(LabTheme.mono(11))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
    }
}
