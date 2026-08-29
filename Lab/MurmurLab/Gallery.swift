// The shelf. The glass family is the collection a buyer sees first, at a size
// that lets a species argue for itself; everything before it is kept, but
// folded away behind one row.
//
// The cells carry the studio's current colors, so this is a view of one
// configuration across the roster rather than a contact sheet of factory
// defaults.

import SwiftUI
import Murmur

/// Which glass species actually have a shader in the metallib.
///
/// The family lands in batches. A style whose `mh_` function is not there yet
/// still exists in the Swift roster and still renders, as a black circle, so
/// the shelf would advertise holes. This list is the gate: update it when a
/// batch lands, and the cell appears.
enum GlassRoster {
    static let landed: Set<String> = [
        "aura", "droplet", "limn", "comet",
        "nebula", "prism", "duet", "still",
    ]

    static var collection: [MurmurStyle] {
        MurmurFamily.glass.styles.filter { landed.contains($0.rawValue) }
    }

    /// Everything that came before the collection, untouched.
    static var archive: [MurmurFamily] {
        MurmurFamily.allCases.filter { $0 != .glass }
    }

    static var archiveCount: Int {
        archive.reduce(0) { $0 + $1.styles.count }
    }
}

struct Gallery: View {
    @Environment(LabModel.self) private var model

    @State private var archiveExpanded = false

    /// The shelf runs three across at 100 pt. The archive keeps the tighter
    /// grid it has always had.
    private let collectionColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let archiveColumns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header
                collection
                archive
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .safeAreaPadding(.bottom, 20)
        .background(LabTheme.stage.ignoresSafeArea())
        .navigationDestination(for: MurmurStyle.self) { style in
            Studio(style: style)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Murmur")
                .font(LabTheme.mono(30, .medium))
                .foregroundStyle(.white)
            // Nothing to count until the first batch lands, and "0 glass
            // indicators" is a worse way to say that than the shelf itself.
            if let subtitle {
                Text(subtitle)
                    .font(LabTheme.mono(12))
                    .foregroundStyle(LabTheme.labelDim)
            }
        }
        .padding(.top, 8)
    }

    private var subtitle: String? {
        let count = GlassRoster.collection.count
        guard count > 0 else { return nil }
        return count == 1 ? "1 glass indicator" : "\(count) glass indicators"
    }

    // MARK: - The collection

    @ViewBuilder
    private var collection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeading(text: "The collection")

            if GlassRoster.collection.isEmpty {
                Text("The glass family is still landing.")
                    .font(LabTheme.mono(12))
                    .foregroundStyle(LabTheme.labelDim)
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else {
                LazyVGrid(columns: collectionColumns, spacing: 26) {
                    ForEach(GlassRoster.collection) { style in
                        NavigationLink(value: style) {
                            GalleryCell(style: style, base: model.config, size: 100)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Archive

    private var archive: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.smooth(duration: 0.28)) { archiveExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Text("Archive")
                        .font(LabTheme.mono(13))
                        .foregroundStyle(LabTheme.label)

                    Spacer(minLength: 8)

                    Text("\(GlassRoster.archiveCount)")
                        .font(LabTheme.mono(13, .medium))
                        .monospacedDigit()
                        .foregroundStyle(LabTheme.valueIdle)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LabTheme.labelDim)
                        .rotationEffect(.degrees(archiveExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 54)
                .contentShape(.rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))

            if archiveExpanded {
                // The six families exactly as they were, nothing removed.
                ForEach(GlassRoster.archive, id: \.self) { family in
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(text: family.displayName)
                        LazyVGrid(columns: archiveColumns, spacing: 22) {
                            ForEach(family.styles) { style in
                                NavigationLink(value: style) {
                                    GalleryCell(style: style, base: model.config, size: 76)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct GalleryCell: View {
    let style: MurmurStyle
    let base: MurmurConfiguration
    let size: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            // 24 fps in the grid: enough for flow to read, cheap enough to
            // run every species at once.
            MurmurView(base.withStyle(style), fps: 24)
                .frame(width: size, height: size)

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
