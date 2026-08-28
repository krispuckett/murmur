// The handoff. One glass card over a dimmed stage, never a system sheet: a
// sheet draws its own platter behind the glass and the whole surface goes
// muddy.

import SwiftUI
import UIKit
import Murmur

struct ExportCard: View {
    @Environment(LabModel.self) private var model

    @State private var prompt = ""
    @State private var copied = false

    /// The self-contained export carries a whole pack file. Laying out fifty
    /// thousand characters of Text stalls the card, so the view shows the
    /// head of it and the Copy button still writes the whole thing.
    private let previewLimit = 8000

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture { dismiss() }

            card
                .padding(.horizontal, 16)
                .padding(.vertical, 56)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .task(id: model.exportSurface) {
            prompt = model.config.agentPrompt(as: model.exportSurface)
            copied = false
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Text("Export")
                    .font(LabTheme.mono(15, .medium))
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .padding(.top, 6)

            surfacePicker
                .padding(.horizontal, 16)

            promptView
                .padding(.horizontal, 16)

            copyButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: 560)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
    }

    private var surfacePicker: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(MurmurExportSurface.allCases, id: \.self) { surface in
                    ChipButton(
                        title: surface.displayName,
                        isSelected: model.exportSurface == surface
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            model.exportSurface = surface
                        }
                    }
                }
            }
        }
    }

    private var promptView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.38))
            ScrollView {
                Text(displayedPrompt)
                    .font(LabTheme.mono(10.5))
                    .foregroundStyle(.white.opacity(0.85))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }
        }
        .frame(maxHeight: 400)
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = prompt
            withAnimation(.snappy(duration: 0.18)) { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.snappy(duration: 0.18)) { copied = false }
            }
        } label: {
            Text(copied ? "Copied" : "Copy")
                .font(LabTheme.mono(14, .semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.glassProminent)
        .tint(LabTheme.tone)
        .foregroundStyle(.black)
    }

    private var displayedPrompt: String {
        guard prompt.count > previewLimit else { return prompt }
        let head = prompt.prefix(previewLimit)
        return head + "\n\n...\n\nPreview stops here. Copy writes all \(prompt.count) characters."
    }

    private func dismiss() {
        withAnimation(.smooth(duration: 0.24)) { model.isExporting = false }
    }
}
