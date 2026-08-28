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
            .tint(.white)

            if model.isExporting {
                ExportCard()
            }
        }
        .environment(model)
        .preferredColorScheme(.dark)
        .task {
            if let style = Self.launchStyle {
                path.append(style)
            }
        }
    }

    /// `simctl launch <sim> com.krispuckett.MurmurLab -openStyle eddy` opens
    /// that studio directly. UserDefaults reads `-key value` launch arguments
    /// into the argument domain, which is how an agent drives this app without
    /// having to find a cell and tap it.
    private static var launchStyle: MurmurStyle? {
        guard let raw = UserDefaults.standard.string(forKey: "openStyle") else { return nil }
        return MurmurStyle(rawValue: raw)
    }
}
