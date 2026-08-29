// One frame, 1024 square, out to wherever the designer wants it. No options:
// the configuration on screen is the configuration that renders, including the
// state being previewed and the ground the current stage is wearing.
//
// The view is clipped to a circle and the renderer is not opaque, so the PNG
// arrives as a circular presence on transparency rather than a square tile.

import SwiftUI
import UIKit
import Murmur

@MainActor
enum StillExport {
    /// Late enough that a settle arc has arrived and the material is at its
    /// designed weather, not its opening frame.
    private static let stillTime: Double = 6

    static func png(
        _ configuration: MurmurConfiguration,
        state: MurmurState,
        size: CGFloat = 1024
    ) -> URL? {
        let renderer = ImageRenderer(
            content: MurmurView(configuration, state: state, animated: false, stillTime: stillTime)
                .frame(width: size, height: size)
        )
        // The frame is already in points at the target pixel count, so no
        // display scaling on top of it.
        renderer.scale = 1
        renderer.isOpaque = false

        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur-\(configuration.style.rawValue).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// The system share sheet, presented on whatever is frontmost. This is the
    /// one place a system sheet is right: it is an OS service, not one of the
    /// app's own overlays.
    static func share(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let root = scene.keyWindow?.rootViewController else { return }

        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        presenter.present(activity, animated: true)
    }
}
