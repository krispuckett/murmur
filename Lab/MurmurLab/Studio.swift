// Pinned preview, scrolling panel. The first version put the dials under the
// preview in one scroll, which meant tuning a character knob scrolled the
// thing you were tuning off the screen. The indicator never moves now; only
// the panel does.

import SwiftUI
import Murmur

struct Studio: View {
    let style: MurmurStyle

    @Environment(LabModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            // One block that takes its full height first. Left to negotiate,
            // the ScrollView below claims the space it had before and the
            // pinned content ends up drawn underneath it, where the scroll
            // view eats the taps meant for the state chips.
            VStack(spacing: 0) {
                StudioPreview()
                    .padding(.horizontal, 20)

                StateSelector()
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                EntryRow()
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .layoutPriority(1)

            StudioPanel(style: style)
        }
        .background(LabTheme.stage.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(style.displayName)
                    .font(LabTheme.mono(15, .medium))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.smooth(duration: 0.28)) { model.isExporting = true }
                } label: {
                    Text("Export").font(LabTheme.mono(13, .medium))
                }
            }
        }
        .task(id: style) {
            model.select(style)
        }
    }
}

// MARK: - Pinned

/// Never scrolls. The large render carries large-scale truth, the two chips
/// beside it carry small-scale truth, and every dial below is visible against
/// all three at once.
private struct StudioPreview: View {
    @Environment(LabModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            // The hero is centered on its own and the chips ride the trailing
            // margin. Laying all three out as one centered row pushes the
            // hero off center, which is the first thing the eye reads.
            // Identity carries the demo tick: changing an entry envelope makes
            // the preview appear again, and appearing is an arrival, so the
            // new envelope runs immediately instead of waiting for the next
            // state change.
            MurmurView(model.previewConfig, state: model.state)
                .id(model.demoTick)
                .frame(width: 160, height: 160)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    VStack(spacing: 16) {
                        sizeChip(46)
                        sizeChip(20)
                    }
                    .padding(.trailing, 6)
                }
                .padding(.vertical, 16)
            // In dark this is the page ground, so the card is invisible and
            // the pinned region reads as open stage rather than a platter.
            .background(stageColor)
            .clipShape(.rect(cornerRadius: 28, style: .continuous))

            Text(model.config.style.species)
                .font(LabTheme.mono(11))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }

    private func sizeChip(_ size: CGFloat) -> some View {
        VStack(spacing: 7) {
            MurmurView(model.previewConfig, state: model.state)
                .id(model.demoTick)
                .frame(width: size, height: size)
            Text("\(Int(size))")
                .font(LabTheme.mono(10))
                .foregroundStyle(stageText.opacity(0.5))
        }
        .frame(width: 52)
    }

    /// Exactly the ground the previewed field composites over, so the circle
    /// dissolves into the stage instead of showing its own disc edge.
    private var stageColor: Color {
        model.previewScheme == .light ? MurmurRGBA.paper.color : model.config.ink.color
    }

    private var stageText: Color {
        model.previewScheme == .light ? .black : .white
    }
}

// MARK: - State

/// Five live indicators, each running its own state. A word for a state is a
/// label; the state actually running is the thing itself, so idle reads slow
/// and dim beside responding without anyone having to read either one.
/// Selecting sets the state plainly: MurmurView runs its own glide, and
/// wrapping this in an animation would fight the transition it provides.
private struct StateSelector: View {
    @Environment(LabModel.self) private var model

    var body: some View {
        // Small spacing: these should read as five separate pieces of glass,
        // not flow into one bar the way a segmented control does.
        GlassEffectContainer(spacing: 2) {
            HStack(spacing: 8) {
                ForEach(MurmurState.allCases, id: \.self) { state in
                    StateMini(state: state, isSelected: model.state == state) {
                        model.state = state
                    }
                }
            }
        }
    }
}

private struct StateMini: View {
    @Environment(LabModel.self) private var model

    let state: MurmurState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Only the selected one wears glass. Giving all five a glass
                // ring and marking the selection with a brighter stroke on top
                // was unreadable at a glance: the ring was already bright, so
                // the stroke had nothing to stand out against.
                Group {
                    if isSelected {
                        MurmurView(model.config, state: state, fps: 24)
                            .frame(width: 44, height: 44)
                            .padding(5)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .overlay {
                                Circle().strokeBorder(LabTheme.selectedEdge, lineWidth: 2)
                            }
                    } else {
                        MurmurView(model.config, state: state, fps: 24)
                            .frame(width: 44, height: 44)
                            .padding(5)
                            .overlay {
                                Circle().strokeBorder(.white.opacity(0.10), lineWidth: 1)
                            }
                    }
                }

                Text(state.displayName)
                    .font(LabTheme.mono(9, isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : LabTheme.labelDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// The entry envelope for whichever state is selected. Tapping cycles it and
/// replays it on the pinned preview, so the wake, the swell and the stutter
/// are things you watch rather than words you pick.
private struct EntryRow: View {
    @Environment(LabModel.self) private var model

    var body: some View {
        Button {
            model.cycleEntry()
        } label: {
            HStack(spacing: 12) {
                Text("entry")
                    .font(LabTheme.mono(13))
                    .foregroundStyle(.white.opacity(0.68))

                Spacer(minLength: 8)

                Text(model.entry.displayName)
                    .font(LabTheme.mono(13, .medium))
                    .foregroundStyle(LabTheme.valueLive)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Panel

private struct StudioPanel: View {
    let style: MurmurStyle

    @Environment(LabModel.self) private var model

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // The state's name rides its section headings. Colors and the
                // pill below say nothing, which is how you can tell they are
                // shared rather than per state.
                section("Motion, \(model.state.rawValue)") {
                    DialRow(label: "speed", value: model.dial(\.speed),
                            range: 0.25...2, defaultValue: seed.speed)
                    DialRow(label: "formScale", value: model.dial(\.formScale),
                            range: 0.5...2, defaultValue: seed.formScale)
                    DialRow(label: "depth", value: model.dial(\.depth),
                            range: 0.3...2, defaultValue: seed.depth)
                    DialRow(label: "glow", value: model.dial(\.glow),
                            range: 0.25...2, defaultValue: seed.glow)
                    DialRow(label: "hueShift", value: model.dial(\.hueShift),
                            range: -0.6...0.6, defaultValue: seed.hueShift, signed: true)
                }

                section("Character, \(model.state.rawValue)") {
                    ForEach(Array(style.characterKnobs.enumerated()), id: \.offset) { index, knob in
                        DialRow(
                            label: knob.label,
                            value: model.knob(index),
                            range: 0...1,
                            defaultValue: seedCharacter(index, fallback: knob.defaultValue)
                        )
                    }
                }

                section("Color") {
                    SwatchRow(selection: $model.config.tone, swatches: LabTheme.tones)
                        .padding(.bottom, 2)
                    ControlRow(label: "tone") {
                        ColorPicker("", selection: toneColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                    ControlRow(label: "ink") {
                        ColorPicker("", selection: inkColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                }

                section("Preview") {
                    schemeToggle
                    ControlRow(label: "label") {
                        TextField("Thinking...", text: $model.pillLabel)
                            .font(LabTheme.mono(13))
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.done)
                            .frame(maxWidth: 210)
                    }
                    pillStage(scheme: .dark, ground: LabTheme.inkStage)
                    pillStage(scheme: .light, ground: LabTheme.paperStage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        // The scroll view runs to the screen edge, so without this the last
        // row ends up under the home indicator.
        .safeAreaPadding(.bottom, 20)
        // A soft edge rather than a hairline or a platter: rows dissolve into
        // the ground as they reach the pinned region. Painted in the ground
        // color rather than masked, which is equivalent over a solid ground
        // and keeps the scroll content itself untouched.
        .overlay(alignment: .top) { edgeFade(.top) }
        .overlay(alignment: .bottom) { edgeFade(.bottom) }
    }

    private func edgeFade(_ edge: VerticalEdge) -> some View {
        LinearGradient(
            colors: edge == .top
                ? [LabTheme.stage, LabTheme.stage.opacity(0)]
                : [LabTheme.stage.opacity(0), LabTheme.stage],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: edge == .top ? 20 : 28)
        .allowsHitTesting(false)
    }

    private var schemeToggle: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ChipButton(title: "Dark", isSelected: model.previewScheme == .dark) {
                    withAnimation(.snappy(duration: 0.2)) { model.previewScheme = .dark }
                }
                ChipButton(title: "Light", isSelected: model.previewScheme == .light) {
                    withAnimation(.snappy(duration: 0.2)) { model.previewScheme = .light }
                }
            }
        }
    }

    private func pillStage(scheme: ColorScheme, ground: Color) -> some View {
        HStack {
            MurmurPill(model.config, state: model.state, label: displayLabel)
            Spacer(minLength: 0)
        }
        .environment(\.colorScheme, scheme)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground)
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }

    /// No GlassEffectContainer around the rows. It groups them the way the
    /// chip clusters are grouped, but it also blurs everything in its subtree,
    /// and the dial rows carry a 2pt value track that does not survive that.
    /// The containers in this app are on the chip clusters, which have no
    /// fine detail to lose.
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: title)
            VStack(spacing: 10) {
                content()
            }
        }
    }

    private var displayLabel: String {
        model.pillLabel.isEmpty ? "Thinking..." : model.pillLabel
    }

    /// The selected state's untouched design, which is what a dial's value
    /// resets to when it is tapped.
    private var seed: MurmurParameters { model.seed }

    private func seedCharacter(_ index: Int, fallback: Double) -> Double {
        let values = seed.resolvedCharacter(for: model.config.style)
        return index < values.count ? values[index] : fallback
    }

    private var toneColor: Binding<Color> {
        Binding(
            get: { model.config.tone.color },
            set: { model.config.tone = MurmurRGBA($0) }
        )
    }

    private var inkColor: Binding<Color> {
        Binding(
            get: { model.config.ink.color },
            set: { model.config.ink = MurmurRGBA($0) }
        )
    }
}
