// The export card floats at the root, above the navigation stack, because it
// is one glass card over the whole stage. Presenting it inside a screen would
// leave the navigation bar drawn on top of it.

import SwiftUI
import Murmur

@main
struct MurmurLabApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var model = LabModel()
    @State private var path = NavigationPath()

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                Gallery()
            }
            .tint(LabTheme.tone)

            if model.isExporting {
                ExportCard()
            }
        }
        .environment(model)
        .preferredColorScheme(.dark)
        // -openStyle <case> jumps straight to a studio. Screenshot rigs and
        // agents drive the lab through launch arguments because HID events do
        // not reliably reach a headless simulator; arguments always arrive.
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if let flag = args.firstIndex(of: "-openStyle"), flag + 1 < args.count,
               let style = MurmurStyle(rawValue: args[flag + 1]) {
                path.append(style)
            }
        }
    }
}
