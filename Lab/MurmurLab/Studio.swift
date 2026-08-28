// One species, every dial, and the truth about scale. The size row is not
// decoration: a field that reads at 300 pt and dies at 20 pt is a failed
// indicator, and this is where you find that out without leaving the screen.

import SwiftUI
import Murmur

struct Studio: View {
    let style: MurmurStyle

    @Environment(LabModel.self) private var model

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                stage

                section("Motion") {
                    DialRow(label: "speed", value: $model.config.speed,
                            range: 0.25...2, defaultValue: 1)
                    DialRow(label: "formScale", value: $model.config.formScale,
                            range: 0.5...2, defaultValue: 1)
                    DialRow(label: "depth", value: $model.config.depth,
                            range: 0.3...2, defaultValue: 1)
                    DialRow(label: "glow", value: $model.config.glow,
                            range: 0.25...2, defaultValue: 1)
                    DialRow(label: "hueShift", value: $model.config.hueShift,
                            range: -0.6...0.6, defaultValue: 0, signed: true)
                }

                section("Character") {
                    ForEach(Array(style.characterKnobs.enumerated()), id: \.offset) { index, knob in
                        DialRow(
                            label: knob.label,
                            value: $model.config.character[index],
                            range: 0...1,
                            defaultValue: knob.defaultValue
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
                    pillPreviews
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(LabTheme.ink.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
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
            // A decoded or hand-edited configuration can arrive short; the
            // character dials index straight into this array.
            if model.config.character.count != 4 {
                model.config.character = model.config.resolvedCharacter
            }
        }
    }

    // MARK: - Stage

    private var stage: some View {
        VStack(spacing: 26) {
            MurmurView(model.previewConfig)
                .frame(width: 300, height: 300)

            HStack(alignment: .bottom, spacing: 26) {
                ForEach([20.0, 46.0, 120.0], id: \.self) { size in
                    VStack(spacing: 8) {
                        MurmurView(model.previewConfig)
                            .frame(width: size, height: size)
                        Text("\(Int(size))")
                            .font(LabTheme.mono(10))
                            .foregroundStyle(stageText.opacity(0.5))
                    }
                }
            }
            .frame(height: 148, alignment: .bottom)

            Text(style.species)
                .font(LabTheme.mono(11))
                .foregroundStyle(stageText.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(stageColor)
        .clipShape(.rect(cornerRadius: 30, style: .continuous))
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

    private var pillPreviews: some View {
        VStack(spacing: 12) {
            pillStage(scheme: .dark, ground: LabTheme.inkStage)
            pillStage(scheme: .light, ground: LabTheme.paperStage)
        }
    }

    private func pillStage(scheme: ColorScheme, ground: Color) -> some View {
        HStack {
            MurmurPill(model.config, label: displayLabel)
            Spacer(minLength: 0)
        }
        .environment(\.colorScheme, scheme)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ground)
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Pieces

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(text: title)
            content()
        }
    }

    private var displayLabel: String {
        model.pillLabel.isEmpty ? "Thinking..." : model.pillLabel
    }

    /// Exactly the ground the previewed field composites over, so the circle
    /// dissolves into the stage instead of showing its own disc edge. The
    /// pill stage below is deliberately a shade off, for the opposite reason.
    private var stageColor: Color {
        model.previewScheme == .light ? MurmurRGBA.paper.color : model.config.ink.color
    }

    private var stageText: Color {
        model.previewScheme == .light ? .black : .white
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
